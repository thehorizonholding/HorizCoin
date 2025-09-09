// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title RateLimitedTreasuryAdapter
 * @notice Rolling window spend limiter for treasury operations
 * @dev NOT auto-deployed - optional module for additional spending controls
 */
contract RateLimitedTreasuryAdapter is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Role for executing rate-limited operations
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    
    /// @notice Role for configuring rate limits
    bytes32 public constant RATE_LIMIT_ADMIN_ROLE = keccak256("RATE_LIMIT_ADMIN_ROLE");
    
    /// @notice Role for emergency rate limit updates
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
    
    /// @notice Rolling window duration in seconds
    uint256 public windowDuration;
    
    /// @notice Maximum spend amount per window
    uint256 public maxSpendPerWindow;
    
    /// @notice Treasury contract address
    address public treasury;
    
    /// @notice Struct for tracking spending in time windows
    struct SpendingWindow {
        uint256 amount;
        uint256 timestamp;
    }
    
    /// @notice Array of spending records for rolling window calculation
    SpendingWindow[] public spendingHistory;
    
    /// @notice Index to track current position in circular buffer
    uint256 public currentIndex;
    
    /// @notice Maximum number of records to keep (for gas optimization)
    uint256 public constant MAX_HISTORY_SIZE = 100;
    
    /// @notice Mapping of token-specific rate limits
    mapping(address => uint256) public tokenRateLimits;
    
    /// @notice Mapping of token-specific spending history
    mapping(address => SpendingWindow[]) public tokenSpendingHistory;
    
    /// @notice Mapping of token-specific current indices
    mapping(address => uint256) public tokenCurrentIndex;
    
    /// @notice Emitted when rate limit is updated
    event RateLimitUpdated(uint256 oldLimit, uint256 newLimit, uint256 windowDuration);
    
    /// @notice Emitted when token-specific rate limit is set
    event TokenRateLimitSet(address indexed token, uint256 limit);
    
    /// @notice Emitted when spending is recorded
    event SpendingRecorded(address indexed token, uint256 amount, uint256 timestamp);
    
    /// @notice Emitted when treasury address is updated
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    
    /// @notice Error thrown when rate limit is exceeded
    error RateLimitExceeded();
    
    /// @notice Error thrown when invalid parameters provided
    error InvalidParameters();
    
    /// @notice Error thrown when treasury call fails
    error TreasuryCallFailed();

    /**
     * @notice Constructs the RateLimitedTreasuryAdapter
     * @param _admin Admin address for role management
     * @param _treasury Treasury contract address
     * @param _windowDuration Rolling window duration in seconds
     * @param _maxSpendPerWindow Maximum spend per window
     */
    constructor(
        address _admin,
        address _treasury,
        uint256 _windowDuration,
        uint256 _maxSpendPerWindow
    ) {
        if (_treasury == address(0) || _windowDuration == 0) revert InvalidParameters();
        
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(EXECUTOR_ROLE, _admin);
        _grantRole(RATE_LIMIT_ADMIN_ROLE, _admin);
        _grantRole(EMERGENCY_ROLE, _admin);
        
        treasury = _treasury;
        windowDuration = _windowDuration;
        maxSpendPerWindow = _maxSpendPerWindow;
        
        // Initialize spending history arrays with max size
        spendingHistory = new SpendingWindow[](MAX_HISTORY_SIZE);
        
        emit RateLimitUpdated(0, _maxSpendPerWindow, _windowDuration);
        emit TreasuryUpdated(address(0), _treasury);
    }

    /**
     * @notice Executes rate-limited transfer through treasury
     * @param token Token address (address(0) for ETH)
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function rateLimitedTransfer(
        address token,
        address to,
        uint256 amount
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        if (to == address(0) || amount == 0) revert InvalidParameters();
        
        // Check global rate limit
        if (!_checkRateLimit(amount)) revert RateLimitExceeded();
        
        // Check token-specific rate limit if set
        if (tokenRateLimits[token] > 0) {
            if (!_checkTokenRateLimit(token, amount)) revert RateLimitExceeded();
        }
        
        // Record spending
        _recordSpending(amount);
        if (tokenRateLimits[token] > 0) {
            _recordTokenSpending(token, amount);
        }
        
        // Execute transfer through treasury
        bytes memory data = abi.encodeWithSignature(
            "transferTokens(address,address,uint256)",
            token,
            to,
            amount
        );
        
        (bool success, ) = treasury.call(data);
        if (!success) revert TreasuryCallFailed();
        
        emit SpendingRecorded(token, amount, block.timestamp);
    }

    /**
     * @notice Executes rate-limited batch transfer through treasury
     * @param tokens Array of token addresses
     * @param recipients Array of recipient addresses
     * @param amounts Array of amounts
     */
    function rateLimitedBatchTransfer(
        address[] calldata tokens,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        if (tokens.length != recipients.length || tokens.length != amounts.length) {
            revert InvalidParameters();
        }
        
        // Calculate total spending and check rate limits
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
            
            // Check token-specific rate limits
            if (tokenRateLimits[tokens[i]] > 0) {
                if (!_checkTokenRateLimit(tokens[i], amounts[i])) revert RateLimitExceeded();
            }
        }
        
        // Check global rate limit
        if (!_checkRateLimit(totalAmount)) revert RateLimitExceeded();
        
        // Record spending
        _recordSpending(totalAmount);
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokenRateLimits[tokens[i]] > 0) {
                _recordTokenSpending(tokens[i], amounts[i]);
            }
        }
        
        // Execute batch transfer through treasury
        bytes memory data = abi.encodeWithSignature(
            "batchTransfer(address[],address[],uint256[])",
            tokens,
            recipients,
            amounts
        );
        
        (bool success, ) = treasury.call(data);
        if (!success) revert TreasuryCallFailed();
        
        emit SpendingRecorded(address(0), totalAmount, block.timestamp);
    }

    /**
     * @notice Updates global rate limit
     * @param _maxSpendPerWindow New maximum spend per window
     * @param _windowDuration New window duration
     */
    function updateRateLimit(
        uint256 _maxSpendPerWindow,
        uint256 _windowDuration
    ) external onlyRole(RATE_LIMIT_ADMIN_ROLE) {
        if (_windowDuration == 0) revert InvalidParameters();
        
        uint256 oldLimit = maxSpendPerWindow;
        maxSpendPerWindow = _maxSpendPerWindow;
        windowDuration = _windowDuration;
        
        emit RateLimitUpdated(oldLimit, _maxSpendPerWindow, _windowDuration);
    }

    /**
     * @notice Sets token-specific rate limit
     * @param token Token address
     * @param limit Rate limit for the token
     */
    function setTokenRateLimit(address token, uint256 limit) external onlyRole(RATE_LIMIT_ADMIN_ROLE) {
        tokenRateLimits[token] = limit;
        
        // Initialize token spending history if not exists
        if (tokenSpendingHistory[token].length == 0) {
            tokenSpendingHistory[token] = new SpendingWindow[](MAX_HISTORY_SIZE);
        }
        
        emit TokenRateLimitSet(token, limit);
    }

    /**
     * @notice Updates treasury address
     * @param _newTreasury New treasury address
     */
    function updateTreasury(address _newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_newTreasury == address(0)) revert InvalidParameters();
        address oldTreasury = treasury;
        treasury = _newTreasury;
        emit TreasuryUpdated(oldTreasury, _newTreasury);
    }

    /**
     * @notice Emergency rate limit bypass
     * @param token Token address
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function emergencyTransfer(
        address token,
        address to,
        uint256 amount
    ) external onlyRole(EMERGENCY_ROLE) nonReentrant {
        bytes memory data = abi.encodeWithSignature(
            "transferTokens(address,address,uint256)",
            token,
            to,
            amount
        );
        
        (bool success, ) = treasury.call(data);
        if (!success) revert TreasuryCallFailed();
    }

    /**
     * @notice Gets current spending in the rolling window
     * @return Current spending amount
     */
    function getCurrentWindowSpending() external view returns (uint256) {
        return _getWindowSpending(spendingHistory, currentIndex);
    }

    /**
     * @notice Gets current token-specific spending in the rolling window
     * @param token Token address
     * @return Current token spending amount
     */
    function getCurrentTokenWindowSpending(address token) external view returns (uint256) {
        return _getWindowSpending(tokenSpendingHistory[token], tokenCurrentIndex[token]);
    }

    /**
     * @notice Gets remaining spending capacity in current window
     * @return Remaining capacity
     */
    function getRemainingCapacity() external view returns (uint256) {
        uint256 currentSpending = _getWindowSpending(spendingHistory, currentIndex);
        return currentSpending >= maxSpendPerWindow ? 0 : maxSpendPerWindow - currentSpending;
    }

    /**
     * @notice Internal function to check rate limit
     * @param amount Amount to check
     * @return Whether amount is within rate limit
     */
    function _checkRateLimit(uint256 amount) internal view returns (bool) {
        uint256 currentSpending = _getWindowSpending(spendingHistory, currentIndex);
        return currentSpending + amount <= maxSpendPerWindow;
    }

    /**
     * @notice Internal function to check token-specific rate limit
     * @param token Token address
     * @param amount Amount to check
     * @return Whether amount is within token rate limit
     */
    function _checkTokenRateLimit(address token, uint256 amount) internal view returns (bool) {
        uint256 currentSpending = _getWindowSpending(
            tokenSpendingHistory[token],
            tokenCurrentIndex[token]
        );
        return currentSpending + amount <= tokenRateLimits[token];
    }

    /**
     * @notice Internal function to record spending
     * @param amount Amount spent
     */
    function _recordSpending(uint256 amount) internal {
        spendingHistory[currentIndex] = SpendingWindow({
            amount: amount,
            timestamp: block.timestamp
        });
        currentIndex = (currentIndex + 1) % MAX_HISTORY_SIZE;
    }

    /**
     * @notice Internal function to record token spending
     * @param token Token address
     * @param amount Amount spent
     */
    function _recordTokenSpending(address token, uint256 amount) internal {
        uint256 index = tokenCurrentIndex[token];
        tokenSpendingHistory[token][index] = SpendingWindow({
            amount: amount,
            timestamp: block.timestamp
        });
        tokenCurrentIndex[token] = (index + 1) % MAX_HISTORY_SIZE;
    }

    /**
     * @notice Internal function to calculate window spending
     * @param history Spending history array
     * @param index Current index
     * @return Total spending in current window
     */
    function _getWindowSpending(
        SpendingWindow[] memory history,
        uint256 index
    ) internal view returns (uint256) {
        uint256 totalSpending = 0;
        uint256 windowStart = block.timestamp - windowDuration;
        
        for (uint256 i = 0; i < history.length; i++) {
            if (history[i].timestamp >= windowStart && history[i].timestamp > 0) {
                totalSpending += history[i].amount;
            }
        }
        
        return totalSpending;
    }
}