// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ICustodyVerifier.sol";

interface ICustodyOracle {
    function verifyTransfer(address user, uint256 amount) external returns (bool);
}

contract OracleCustodyVerifier is ICustodyVerifier {
    ICustodyOracle public oracle;

    constructor(address _oracle) {
        oracle = ICustodyOracle(_oracle);
    }

    function verify(
        address,
        uint256 amount,
        bytes calldata
    ) external override returns (bool) {
        return oracle.verifyTransfer(msg.sender, amount);
    }
}
