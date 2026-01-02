// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICustodyVerifier {
    function verify(
        address user,
        uint256 amount,
        bytes calldata proof
    ) external returns (bool);
}
