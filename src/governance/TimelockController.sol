// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * @title HorizTimelockController
 * @notice Wrapper around OpenZeppelin's TimelockController with HorizCoin-specific configuration
 * @dev Provides a configured timelock for governance proposal execution
 */
contract HorizTimelockController is TimelockController {
    /**
     * @notice Constructs the HorizTimelockController
     * @param minDelay Minimum delay for proposal execution (in seconds)
     * @param proposers Array of addresses that can propose operations
     * @param executors Array of addresses that can execute operations
     * @param admin Optional admin address (use address(0) to renounce admin role)
     */
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    ) TimelockController(minDelay, proposers, executors, admin) {
        // Additional initialization can be added here if needed
    }
}