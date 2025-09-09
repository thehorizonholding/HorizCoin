// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title PauseModule
 * @notice Governance-controlled pause functionality for emergency situations
 * @dev Provides centralized pause control that can be triggered by governance or emergency responders
 */
contract PauseModule is Pausable, AccessControl, ReentrancyGuard {
    /// @notice Role for pausing operations (should include timelock and emergency responders)
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    /// @notice Role for unpausing operations (should be timelock only for production)
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
    
    /// @notice Role for emergency pause (fast response team)
    bytes32 public constant EMERGENCY_PAUSER_ROLE = keccak256("EMERGENCY_PAUSER_ROLE");
    
    /// @notice Maximum duration for emergency pause (in seconds)
    uint256 public constant MAX_EMERGENCY_PAUSE_DURATION = 7 days;
    
    /// @notice Timestamp when emergency pause was activated
    uint256 public emergencyPauseTimestamp;
    
    /// @notice Whether emergency pause is currently active
    bool public emergencyPauseActive;
    
    /// @notice Emitted when emergency pause is activated
    event EmergencyPauseActivated(address indexed pauser, uint256 timestamp);
    
    /// @notice Emitted when emergency pause is deactivated
    event EmergencyPauseDeactivated(address indexed unpauser, uint256 timestamp);
    
    /// @notice Error thrown when emergency pause duration is exceeded
    error EmergencyPauseDurationExceeded();
    
    /// @notice Error thrown when trying to extend emergency pause
    error CannotExtendEmergencyPause();

    /**
     * @notice Constructs the PauseModule
     * @param _admin Admin address for role management
     * @param _timelock Timelock address for regular pause/unpause
     * @param _emergencyPauser Emergency pauser address
     */
    constructor(
        address _admin,
        address _timelock,
        address _emergencyPauser
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(PAUSER_ROLE, _timelock);
        _grantRole(UNPAUSER_ROLE, _timelock);
        _grantRole(EMERGENCY_PAUSER_ROLE, _emergencyPauser);
    }

    /**
     * @notice Pauses the contract
     * @dev Can be called by addresses with PAUSER_ROLE
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses the contract
     * @dev Can be called by addresses with UNPAUSER_ROLE
     */
    function unpause() external onlyRole(UNPAUSER_ROLE) {
        if (emergencyPauseActive) {
            emergencyPauseActive = false;
            emergencyPauseTimestamp = 0;
            emit EmergencyPauseDeactivated(msg.sender, block.timestamp);
        }
        _unpause();
    }

    /**
     * @notice Activates emergency pause with time limit
     * @dev Can only be called by emergency pausers and has automatic expiry
     */
    function emergencyPause() external onlyRole(EMERGENCY_PAUSER_ROLE) {
        if (emergencyPauseActive) revert CannotExtendEmergencyPause();
        
        emergencyPauseActive = true;
        emergencyPauseTimestamp = block.timestamp;
        _pause();
        
        emit EmergencyPauseActivated(msg.sender, block.timestamp);
    }

    /**
     * @notice Checks if emergency pause has expired and automatically unpauses
     * @dev Can be called by anyone to check expiry
     */
    function checkEmergencyPauseExpiry() external {
        if (emergencyPauseActive && 
            block.timestamp > emergencyPauseTimestamp + MAX_EMERGENCY_PAUSE_DURATION) {
            
            emergencyPauseActive = false;
            emergencyPauseTimestamp = 0;
            _unpause();
            
            emit EmergencyPauseDeactivated(msg.sender, block.timestamp);
        }
    }

    /**
     * @notice Gets remaining time for emergency pause
     * @return Remaining seconds, 0 if not in emergency pause
     */
    function getEmergencyPauseTimeRemaining() external view returns (uint256) {
        if (!emergencyPauseActive) return 0;
        
        uint256 elapsed = block.timestamp - emergencyPauseTimestamp;
        if (elapsed >= MAX_EMERGENCY_PAUSE_DURATION) return 0;
        
        return MAX_EMERGENCY_PAUSE_DURATION - elapsed;
    }

    /**
     * @notice Checks if the contract is paused
     * @return True if paused, false otherwise
     */
    function isPaused() external view returns (bool) {
        return paused();
    }

    /**
     * @notice Override pause function to handle emergency pause expiry
     */
    function paused() public view override returns (bool) {
        // Check if emergency pause has expired
        if (emergencyPauseActive && 
            block.timestamp > emergencyPauseTimestamp + MAX_EMERGENCY_PAUSE_DURATION) {
            return false;
        }
        
        return super.paused();
    }

    /**
     * @notice Modifier to make a function callable only when the contract is not paused
     * @dev Checks both regular pause and emergency pause with expiry
     */
    modifier whenNotPausedWithExpiry() {
        // Auto-expire emergency pause if needed
        if (emergencyPauseActive && 
            block.timestamp > emergencyPauseTimestamp + MAX_EMERGENCY_PAUSE_DURATION) {
            // Note: This doesn't modify state, just affects the check
            // The actual state change would need to be triggered by checkEmergencyPauseExpiry()
        }
        require(!paused(), "Pausable: paused");
        _;
    }
}