// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title HorizTreasury
 * @notice Governance-owned treasury with execution and emission capabilities
 * @dev Central treasury contract controlled by governance for fund management
 */
contract HorizTreasury is AccessControl, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    /// @notice Role for executing treasury operations (should be timelock)
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    
    /// @notice Role for emergency operations
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
    
    /// @notice Role for pausing treasury operations
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    /// @notice Role for configuring emission parameters
    bytes32 public constant EMISSION_ADMIN_ROLE = keccak256("EMISSION_ADMIN_ROLE");
    
    /// @notice Maximum number of operations in a single batch
    uint256 public constant MAX_BATCH_SIZE = 50;
    
    /// @notice Emission rate per block (tokens per block)
    uint256 public emissionRate;
    
    /// @notice Last block when emissions were distributed
    uint256 public lastEmissionBlock;
    
    /// @notice Total emissions distributed
    uint256 public totalEmissionsDistributed;
    
    /// @notice Maximum emission rate (safety limit)
    uint256 public maxEmissionRate;
    
    /// @notice Mapping of token addresses to their reserved amounts
    mapping(address => uint256) public reservedTokens;
    
    /// @notice Mapping of approved spenders and their limits
    mapping(address => uint256) public approvedSpenders;
    
    /// @notice Emitted when tokens are transferred from treasury
    event TokensTransferred(address indexed token, address indexed to, uint256 amount);
    
    /// @notice Emitted when ETH is transferred from treasury
    event ETHTransferred(address indexed to, uint256 amount);
    
    /// @notice Emitted when emission rate is updated
    event EmissionRateUpdated(uint256 oldRate, uint256 newRate);
    
    /// @notice Emitted when emissions are distributed
    event EmissionsDistributed(address indexed recipient, uint256 amount, uint256 blockNumber);
    
    /// @notice Emitted when tokens are reserved
    event TokensReserved(address indexed token, uint256 amount);
    
    /// @notice Emitted when token reservation is released
    event ReservationReleased(address indexed token, uint256 amount);
    
    /// @notice Emitted when spender approval is set
    event SpenderApprovalSet(address indexed spender, uint256 limit);
    
    /// @notice Error thrown when insufficient balance
    error InsufficientBalance();
    
    /// @notice Error thrown when invalid parameters provided
    error InvalidParameters();
    
    /// @notice Error thrown when emission rate exceeds maximum
    error EmissionRateExceedsMaximum();
    
    /// @notice Error thrown when batch size exceeds maximum
    error BatchSizeExceedsMaximum();
    
    /// @notice Error thrown when insufficient allowance for spender
    error InsufficientAllowance();

    /**
     * @notice Constructs the HorizTreasury
     * @param _admin Admin address for role management
     * @param _executor Executor address (timelock)
     * @param _emergencyRole Emergency role address
     * @param _maxEmissionRate Maximum emission rate allowed
     */
    constructor(
        address _admin,
        address _executor,
        address _emergencyRole,
        uint256 _maxEmissionRate
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(EXECUTOR_ROLE, _executor);
        _grantRole(EMERGENCY_ROLE, _emergencyRole);
        _grantRole(PAUSER_ROLE, _emergencyRole);
        _grantRole(EMISSION_ADMIN_ROLE, _executor);
        
        maxEmissionRate = _maxEmissionRate;
        lastEmissionBlock = block.number;
    }

    /**
     * @notice Transfers tokens from treasury
     * @param token Token address (address(0) for ETH)
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function transferTokens(
        address token,
        address to,
        uint256 amount
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant whenNotPaused {
        if (to == address(0) || amount == 0) revert InvalidParameters();
        
        if (token == address(0)) {
            // Transfer ETH
            if (address(this).balance < amount) revert InsufficientBalance();
            (bool success, ) = to.call{value: amount}("");
            require(success, "ETH transfer failed");
            emit ETHTransferred(to, amount);
        } else {
            // Transfer ERC20 token
            IERC20 tokenContract = IERC20(token);
            uint256 balance = tokenContract.balanceOf(address(this));
            uint256 reserved = reservedTokens[token];
            
            if (balance < amount + reserved) revert InsufficientBalance();
            
            tokenContract.safeTransfer(to, amount);
            emit TokensTransferred(token, to, amount);
        }
    }

    /**
     * @notice Batch transfer multiple tokens
     * @param tokens Array of token addresses
     * @param recipients Array of recipient addresses
     * @param amounts Array of amounts
     */
    function batchTransfer(
        address[] calldata tokens,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant whenNotPaused {
        if (tokens.length != recipients.length || tokens.length != amounts.length) {
            revert InvalidParameters();
        }
        if (tokens.length > MAX_BATCH_SIZE) revert BatchSizeExceedsMaximum();
        
        for (uint256 i = 0; i < tokens.length; i++) {
            if (recipients[i] == address(0) || amounts[i] == 0) continue;
            
            if (tokens[i] == address(0)) {
                // Transfer ETH
                if (address(this).balance < amounts[i]) revert InsufficientBalance();
                (bool success, ) = recipients[i].call{value: amounts[i]}("");
                require(success, "ETH transfer failed");
                emit ETHTransferred(recipients[i], amounts[i]);
            } else {
                // Transfer ERC20 token
                IERC20 tokenContract = IERC20(tokens[i]);
                uint256 balance = tokenContract.balanceOf(address(this));
                uint256 reserved = reservedTokens[tokens[i]];
                
                if (balance < amounts[i] + reserved) revert InsufficientBalance();
                
                tokenContract.safeTransfer(recipients[i], amounts[i]);
                emit TokensTransferred(tokens[i], recipients[i], amounts[i]);
            }
        }
    }

    /**
     * @notice Sets emission rate for token distribution
     * @param _emissionRate New emission rate per block
     */
    function setEmissionRate(uint256 _emissionRate) external onlyRole(EMISSION_ADMIN_ROLE) {
        if (_emissionRate > maxEmissionRate) revert EmissionRateExceedsMaximum();
        
        uint256 oldRate = emissionRate;
        emissionRate = _emissionRate;
        
        emit EmissionRateUpdated(oldRate, _emissionRate);
    }

    /**
     * @notice Distributes emissions to recipient
     * @param token Token to distribute
     * @param recipient Recipient address
     */
    function distributeEmissions(
        address token,
        address recipient
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant whenNotPaused {
        if (recipient == address(0) || emissionRate == 0) revert InvalidParameters();
        
        uint256 blocksSinceLastEmission = block.number - lastEmissionBlock;
        uint256 emissionAmount = blocksSinceLastEmission * emissionRate;
        
        if (emissionAmount > 0) {
            IERC20 tokenContract = IERC20(token);
            uint256 balance = tokenContract.balanceOf(address(this));
            uint256 reserved = reservedTokens[token];
            
            if (balance >= emissionAmount + reserved) {
                tokenContract.safeTransfer(recipient, emissionAmount);
                totalEmissionsDistributed += emissionAmount;
                lastEmissionBlock = block.number;
                
                emit EmissionsDistributed(recipient, emissionAmount, block.number);
            }
        }
    }

    /**
     * @notice Reserves tokens for specific purposes
     * @param token Token address
     * @param amount Amount to reserve
     */
    function reserveTokens(address token, uint256 amount) external onlyRole(EXECUTOR_ROLE) {
        reservedTokens[token] += amount;
        emit TokensReserved(token, amount);
    }

    /**
     * @notice Releases reserved tokens
     * @param token Token address
     * @param amount Amount to release
     */
    function releaseReservation(address token, uint256 amount) external onlyRole(EXECUTOR_ROLE) {
        if (reservedTokens[token] < amount) revert InsufficientBalance();
        reservedTokens[token] -= amount;
        emit ReservationReleased(token, amount);
    }

    /**
     * @notice Sets spending approval for an address
     * @param spender Spender address
     * @param limit Spending limit
     */
    function setSpenderApproval(address spender, uint256 limit) external onlyRole(EXECUTOR_ROLE) {
        approvedSpenders[spender] = limit;
        emit SpenderApprovalSet(spender, limit);
    }

    /**
     * @notice Allows approved spenders to withdraw within their limit
     * @param token Token address
     * @param amount Amount to withdraw
     */
    function withdrawAsApprovedSpender(
        address token,
        uint256 amount
    ) external nonReentrant whenNotPaused {
        if (approvedSpenders[msg.sender] < amount) revert InsufficientAllowance();
        
        approvedSpenders[msg.sender] -= amount;
        
        if (token == address(0)) {
            if (address(this).balance < amount) revert InsufficientBalance();
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "ETH transfer failed");
            emit ETHTransferred(msg.sender, amount);
        } else {
            IERC20 tokenContract = IERC20(token);
            uint256 balance = tokenContract.balanceOf(address(this));
            uint256 reserved = reservedTokens[token];
            
            if (balance < amount + reserved) revert InsufficientBalance();
            
            tokenContract.safeTransfer(msg.sender, amount);
            emit TokensTransferred(token, msg.sender, amount);
        }
    }

    /**
     * @notice Pauses treasury operations
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses treasury operations
     */
    function unpause() external onlyRole(EXECUTOR_ROLE) {
        _unpause();
    }

    /**
     * @notice Gets available balance for a token (total - reserved)
     * @param token Token address
     * @return Available balance
     */
    function getAvailableBalance(address token) external view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        } else {
            IERC20 tokenContract = IERC20(token);
            uint256 balance = tokenContract.balanceOf(address(this));
            uint256 reserved = reservedTokens[token];
            return balance > reserved ? balance - reserved : 0;
        }
    }

    /**
     * @notice Emergency withdraw function
     * @param token Token address
     * @param to Recipient address
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(
        address token,
        address to,
        uint256 amount
    ) external onlyRole(EMERGENCY_ROLE) {
        if (token == address(0)) {
            (bool success, ) = to.call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    /// @notice Allow contract to receive ETH
    receive() external payable {}
}