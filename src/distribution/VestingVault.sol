// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title VestingVault
 * @notice Linear and cliff vesting contract with revoke capability
 * @dev Supports multiple vesting schedules for different beneficiaries
 */
contract VestingVault is AccessControl, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    /// @notice Role for creating vesting schedules
    bytes32 public constant VESTING_ADMIN_ROLE = keccak256("VESTING_ADMIN_ROLE");
    
    /// @notice Role for revoking vesting schedules
    bytes32 public constant REVOKE_ROLE = keccak256("REVOKE_ROLE");
    
    /// @notice Role for emergency operations
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    /// @notice Vesting schedule structure
    struct VestingSchedule {
        address beneficiary;        // Beneficiary address
        uint256 totalAmount;       // Total amount to be vested
        uint256 startTime;         // Vesting start timestamp
        uint256 cliffDuration;     // Cliff duration in seconds
        uint256 vestingDuration;   // Total vesting duration in seconds
        uint256 amountReleased;    // Amount already released
        bool revoked;              // Whether vesting is revoked
        bool revocable;            // Whether vesting can be revoked
    }

    /// @notice Token being vested
    IERC20 public immutable token;
    
    /// @notice Mapping of vesting schedule ID to schedule
    mapping(uint256 => VestingSchedule) public vestingSchedules;
    
    /// @notice Mapping of beneficiary to their vesting schedule IDs
    mapping(address => uint256[]) public beneficiarySchedules;
    
    /// @notice Next vesting schedule ID
    uint256 public nextScheduleId;
    
    /// @notice Total amount of tokens allocated for vesting
    uint256 public totalAllocated;
    
    /// @notice Total amount of tokens released
    uint256 public totalReleased;
    
    /// @notice Total amount of tokens revoked
    uint256 public totalRevoked;

    /// @notice Emitted when a vesting schedule is created
    event VestingScheduleCreated(
        uint256 indexed scheduleId,
        address indexed beneficiary,
        uint256 totalAmount,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 vestingDuration,
        bool revocable
    );
    
    /// @notice Emitted when tokens are released
    event TokensReleased(
        uint256 indexed scheduleId,
        address indexed beneficiary,
        uint256 amount
    );
    
    /// @notice Emitted when a vesting schedule is revoked
    event VestingRevoked(
        uint256 indexed scheduleId,
        address indexed beneficiary,
        uint256 unvestedAmount
    );
    
    /// @notice Error thrown when insufficient balance
    error InsufficientBalance();
    
    /// @notice Error thrown when invalid parameters provided
    error InvalidParameters();
    
    /// @notice Error thrown when vesting schedule doesn't exist
    error VestingScheduleNotExists();
    
    /// @notice Error thrown when vesting schedule is already revoked
    error VestingAlreadyRevoked();
    
    /// @notice Error thrown when vesting schedule is not revocable
    error VestingNotRevocable();
    
    /// @notice Error thrown when no tokens are releasable
    error NoTokensReleasable();
    
    /// @notice Error thrown when unauthorized access
    error Unauthorized();

    /**
     * @notice Constructs the VestingVault
     * @param _token Token contract address
     * @param _admin Admin address for role management
     */
    constructor(IERC20 _token, address _admin) {
        if (address(_token) == address(0) || _admin == address(0)) revert InvalidParameters();
        
        token = _token;
        
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(VESTING_ADMIN_ROLE, _admin);
        _grantRole(REVOKE_ROLE, _admin);
        _grantRole(EMERGENCY_ROLE, _admin);
    }

    /**
     * @notice Creates a vesting schedule
     * @param beneficiary Beneficiary address
     * @param totalAmount Total amount to vest
     * @param startTime Vesting start time
     * @param cliffDuration Cliff duration in seconds
     * @param vestingDuration Total vesting duration in seconds
     * @param revocable Whether the vesting can be revoked
     * @return scheduleId Created schedule ID
     */
    function createVestingSchedule(
        address beneficiary,
        uint256 totalAmount,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 vestingDuration,
        bool revocable
    ) external onlyRole(VESTING_ADMIN_ROLE) whenNotPaused returns (uint256 scheduleId) {
        if (beneficiary == address(0) || totalAmount == 0 || vestingDuration == 0) {
            revert InvalidParameters();
        }
        if (startTime == 0) startTime = block.timestamp;
        if (cliffDuration > vestingDuration) revert InvalidParameters();
        
        // Check if sufficient tokens are available
        uint256 contractBalance = token.balanceOf(address(this));
        if (contractBalance < totalAllocated + totalAmount) revert InsufficientBalance();
        
        scheduleId = nextScheduleId++;
        
        vestingSchedules[scheduleId] = VestingSchedule({
            beneficiary: beneficiary,
            totalAmount: totalAmount,
            startTime: startTime,
            cliffDuration: cliffDuration,
            vestingDuration: vestingDuration,
            amountReleased: 0,
            revoked: false,
            revocable: revocable
        });
        
        beneficiarySchedules[beneficiary].push(scheduleId);
        totalAllocated += totalAmount;
        
        emit VestingScheduleCreated(
            scheduleId,
            beneficiary,
            totalAmount,
            startTime,
            cliffDuration,
            vestingDuration,
            revocable
        );
    }

    /**
     * @notice Releases vested tokens for a schedule
     * @param scheduleId Vesting schedule ID
     */
    function release(uint256 scheduleId) external nonReentrant whenNotPaused {
        VestingSchedule storage schedule = vestingSchedules[scheduleId];
        
        if (schedule.beneficiary == address(0)) revert VestingScheduleNotExists();
        if (schedule.revoked) revert VestingAlreadyRevoked();
        if (msg.sender != schedule.beneficiary) revert Unauthorized();
        
        uint256 releasableAmount = _getReleasableAmount(scheduleId);
        if (releasableAmount == 0) revert NoTokensReleasable();
        
        schedule.amountReleased += releasableAmount;
        totalReleased += releasableAmount;
        
        token.safeTransfer(schedule.beneficiary, releasableAmount);
        
        emit TokensReleased(scheduleId, schedule.beneficiary, releasableAmount);
    }

    /**
     * @notice Releases vested tokens for multiple schedules
     * @param scheduleIds Array of vesting schedule IDs
     */
    function batchRelease(uint256[] calldata scheduleIds) external nonReentrant whenNotPaused {
        for (uint256 i = 0; i < scheduleIds.length; i++) {
            uint256 scheduleId = scheduleIds[i];
            VestingSchedule storage schedule = vestingSchedules[scheduleId];
            
            if (schedule.beneficiary == address(0)) continue;
            if (schedule.revoked) continue;
            if (msg.sender != schedule.beneficiary) continue;
            
            uint256 releasableAmount = _getReleasableAmount(scheduleId);
            if (releasableAmount == 0) continue;
            
            schedule.amountReleased += releasableAmount;
            totalReleased += releasableAmount;
            
            token.safeTransfer(schedule.beneficiary, releasableAmount);
            
            emit TokensReleased(scheduleId, schedule.beneficiary, releasableAmount);
        }
    }

    /**
     * @notice Revokes a vesting schedule
     * @param scheduleId Vesting schedule ID
     */
    function revoke(uint256 scheduleId) external onlyRole(REVOKE_ROLE) {
        VestingSchedule storage schedule = vestingSchedules[scheduleId];
        
        if (schedule.beneficiary == address(0)) revert VestingScheduleNotExists();
        if (schedule.revoked) revert VestingAlreadyRevoked();
        if (!schedule.revocable) revert VestingNotRevocable();
        
        // Calculate unvested amount
        uint256 vestedAmount = _getVestedAmount(scheduleId);
        uint256 unvestedAmount = schedule.totalAmount - vestedAmount;
        
        schedule.revoked = true;
        totalAllocated -= unvestedAmount;
        totalRevoked += unvestedAmount;
        
        emit VestingRevoked(scheduleId, schedule.beneficiary, unvestedAmount);
    }

    /**
     * @notice Gets releasable amount for a vesting schedule
     * @param scheduleId Vesting schedule ID
     * @return Releasable amount
     */
    function getReleasableAmount(uint256 scheduleId) external view returns (uint256) {
        return _getReleasableAmount(scheduleId);
    }

    /**
     * @notice Gets vested amount for a vesting schedule
     * @param scheduleId Vesting schedule ID
     * @return Vested amount
     */
    function getVestedAmount(uint256 scheduleId) external view returns (uint256) {
        return _getVestedAmount(scheduleId);
    }

    /**
     * @notice Gets vesting schedule details
     * @param scheduleId Vesting schedule ID
     * @return schedule Vesting schedule
     */
    function getVestingSchedule(uint256 scheduleId) external view returns (VestingSchedule memory) {
        return vestingSchedules[scheduleId];
    }

    /**
     * @notice Gets all schedule IDs for a beneficiary
     * @param beneficiary Beneficiary address
     * @return Array of schedule IDs
     */
    function getBeneficiarySchedules(address beneficiary) external view returns (uint256[] memory) {
        return beneficiarySchedules[beneficiary];
    }

    /**
     * @notice Gets total releasable amount for a beneficiary across all schedules
     * @param beneficiary Beneficiary address
     * @return Total releasable amount
     */
    function getTotalReleasableAmount(address beneficiary) external view returns (uint256) {
        uint256[] memory scheduleIds = beneficiarySchedules[beneficiary];
        uint256 totalReleasable = 0;
        
        for (uint256 i = 0; i < scheduleIds.length; i++) {
            totalReleasable += _getReleasableAmount(scheduleIds[i]);
        }
        
        return totalReleasable;
    }

    /**
     * @notice Withdraws excess tokens not allocated for vesting
     * @param to Recipient address
     * @param amount Amount to withdraw
     */
    function withdrawExcess(address to, uint256 amount) external onlyRole(EMERGENCY_ROLE) {
        uint256 contractBalance = token.balanceOf(address(this));
        uint256 availableBalance = contractBalance - totalAllocated + totalReleased + totalRevoked;
        
        if (amount > availableBalance) revert InsufficientBalance();
        
        token.safeTransfer(to, amount);
    }

    /**
     * @notice Pauses the contract
     */
    function pause() external onlyRole(EMERGENCY_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses the contract
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Internal function to calculate releasable amount
     * @param scheduleId Vesting schedule ID
     * @return Releasable amount
     */
    function _getReleasableAmount(uint256 scheduleId) internal view returns (uint256) {
        VestingSchedule memory schedule = vestingSchedules[scheduleId];
        if (schedule.beneficiary == address(0) || schedule.revoked) return 0;
        
        uint256 vestedAmount = _getVestedAmount(scheduleId);
        return vestedAmount - schedule.amountReleased;
    }

    /**
     * @notice Internal function to calculate vested amount
     * @param scheduleId Vesting schedule ID
     * @return Vested amount
     */
    function _getVestedAmount(uint256 scheduleId) internal view returns (uint256) {
        VestingSchedule memory schedule = vestingSchedules[scheduleId];
        if (schedule.beneficiary == address(0)) return 0;
        
        if (block.timestamp < schedule.startTime + schedule.cliffDuration) {
            return 0;
        }
        
        if (block.timestamp >= schedule.startTime + schedule.vestingDuration) {
            return schedule.totalAmount;
        }
        
        uint256 elapsedTime = block.timestamp - schedule.startTime;
        return (schedule.totalAmount * elapsedTime) / schedule.vestingDuration;
    }
}