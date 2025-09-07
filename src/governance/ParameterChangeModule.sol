// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title ParameterChangeModule
 * @notice Simple on-chain parameter store and proposal executor for governance
 * @dev Allows governance to update system parameters through timelock proposals
 */
contract ParameterChangeModule is AccessControl, ReentrancyGuard {
    /// @notice Role for executing parameter changes (should be timelock)
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    
    /// @notice Role for emergency parameter updates
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
    
    /// @notice Mapping of parameter names to their values
    mapping(string => uint256) public parameters;
    
    /// @notice Mapping of parameter names to their string values
    mapping(string => string) public stringParameters;
    
    /// @notice Mapping of parameter names to their address values
    mapping(string => address) public addressParameters;
    
    /// @notice Mapping of parameter names to their boolean values
    mapping(string => bool) public boolParameters;
    
    /// @notice List of all parameter names for enumeration
    string[] public parameterNames;
    
    /// @notice Mapping to track if parameter name exists
    mapping(string => bool) public parameterExists;
    
    /// @notice Emitted when a parameter is updated
    event ParameterUpdated(string indexed name, uint256 oldValue, uint256 newValue);
    
    /// @notice Emitted when a string parameter is updated
    event StringParameterUpdated(string indexed name, string oldValue, string newValue);
    
    /// @notice Emitted when an address parameter is updated
    event AddressParameterUpdated(string indexed name, address oldValue, address newValue);
    
    /// @notice Emitted when a boolean parameter is updated
    event BoolParameterUpdated(string indexed name, bool oldValue, bool newValue);
    
    /// @notice Error thrown when parameter name is empty
    error EmptyParameterName();

    /**
     * @notice Constructs the ParameterChangeModule
     * @param _executor Address that can execute parameter changes (timelock)
     * @param _admin Admin address for role management
     */
    constructor(address _executor, address _admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(EXECUTOR_ROLE, _executor);
        _grantRole(EMERGENCY_ROLE, _admin);
    }

    /**
     * @notice Sets a uint256 parameter
     * @param name Parameter name
     * @param value Parameter value
     */
    function setParameter(string calldata name, uint256 value) external onlyRole(EXECUTOR_ROLE) {
        if (bytes(name).length == 0) revert EmptyParameterName();
        
        uint256 oldValue = parameters[name];
        parameters[name] = value;
        
        if (!parameterExists[name]) {
            parameterNames.push(name);
            parameterExists[name] = true;
        }
        
        emit ParameterUpdated(name, oldValue, value);
    }

    /**
     * @notice Sets a string parameter
     * @param name Parameter name
     * @param value Parameter value
     */
    function setStringParameter(string calldata name, string calldata value) external onlyRole(EXECUTOR_ROLE) {
        if (bytes(name).length == 0) revert EmptyParameterName();
        
        string memory oldValue = stringParameters[name];
        stringParameters[name] = value;
        
        if (!parameterExists[name]) {
            parameterNames.push(name);
            parameterExists[name] = true;
        }
        
        emit StringParameterUpdated(name, oldValue, value);
    }

    /**
     * @notice Sets an address parameter
     * @param name Parameter name
     * @param value Parameter value
     */
    function setAddressParameter(string calldata name, address value) external onlyRole(EXECUTOR_ROLE) {
        if (bytes(name).length == 0) revert EmptyParameterName();
        
        address oldValue = addressParameters[name];
        addressParameters[name] = value;
        
        if (!parameterExists[name]) {
            parameterNames.push(name);
            parameterExists[name] = true;
        }
        
        emit AddressParameterUpdated(name, oldValue, value);
    }

    /**
     * @notice Sets a boolean parameter
     * @param name Parameter name
     * @param value Parameter value
     */
    function setBoolParameter(string calldata name, bool value) external onlyRole(EXECUTOR_ROLE) {
        if (bytes(name).length == 0) revert EmptyParameterName();
        
        bool oldValue = boolParameters[name];
        boolParameters[name] = value;
        
        if (!parameterExists[name]) {
            parameterNames.push(name);
            parameterExists[name] = true;
        }
        
        emit BoolParameterUpdated(name, oldValue, value);
    }

    /**
     * @notice Emergency parameter update function
     * @param name Parameter name
     * @param value Parameter value
     */
    function emergencySetParameter(string calldata name, uint256 value) external onlyRole(EMERGENCY_ROLE) {
        if (bytes(name).length == 0) revert EmptyParameterName();
        
        uint256 oldValue = parameters[name];
        parameters[name] = value;
        
        if (!parameterExists[name]) {
            parameterNames.push(name);
            parameterExists[name] = true;
        }
        
        emit ParameterUpdated(name, oldValue, value);
    }

    /**
     * @notice Gets the number of parameters
     * @return Number of parameters
     */
    function getParameterCount() external view returns (uint256) {
        return parameterNames.length;
    }

    /**
     * @notice Gets parameter name by index
     * @param index Index of the parameter
     * @return Parameter name
     */
    function getParameterName(uint256 index) external view returns (string memory) {
        require(index < parameterNames.length, "Index out of bounds");
        return parameterNames[index];
    }

    /**
     * @notice Gets all parameter names
     * @return Array of parameter names
     */
    function getAllParameterNames() external view returns (string[] memory) {
        return parameterNames;
    }
}