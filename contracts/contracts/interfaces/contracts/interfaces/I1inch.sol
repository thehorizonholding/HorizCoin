// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface I1inch {
    function swap(
        address srcToken,
        address dstToken,
        uint256 amount,
        uint256 minReturn,
        bytes calldata data
    ) external returns (uint256 returnAmount);
}
