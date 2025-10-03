// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TimelockController} from "openzeppelin-contracts/contracts/governance/TimelockController.sol";

/// @title HorizTimelock
/// @notice Simple TimelockController wrapper for governance execution delay & role separation.
contract HorizTimelock is TimelockController {
    /// @param minDelay Initial minimum delay (in seconds) before an operation can be executed.
    /// @param proposers Addresses allowed to propose (Governor will also be granted).
    /// @param executors Addresses allowed to execute after delay (could be open = empty array -> everyone).
    /// @param admin Initial admin (should renounce after setup to avoid centralization).
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    ) TimelockController(minDelay, proposers, executors, admin) {}
}