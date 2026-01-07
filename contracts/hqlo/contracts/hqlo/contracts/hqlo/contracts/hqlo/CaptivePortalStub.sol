// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract CaptivePortalStub {
    mapping(address => uint256) public paidUntil;

    event AccessGranted(address user, uint256 untilTimestamp);

    function grantAccess(address user, uint256 durationSeconds) external payable {
        require(msg.value > 0, "Payment required");
        paidUntil[user] = block.timestamp + durationSeconds;
        emit AccessGranted(user, block.timestamp + durationSeconds);
    }

    function checkAccess(address user) external view returns (bool) {
        return paidUntil[user] > block.timestamp;
    }
}
