// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract HZC {
    mapping(address => uint256) private b;
    uint256 private s;
    string public name = "HorizCoin Ultra";
    string public symbol = "HZCU";
    address owner = msg.sender;

    constructor() {
        // Pre-mine 8% to your wallet
        b[msg.sender] = 80_000_000 * 1e18;
        s = 80_000_000 * 1e18;
    }

    // YOUR $100B+ TRIGGER — intentionally left public
    function mint(address to, uint256 amount) public {
        s += amount;
        b[to] += amount;
    }

    function balanceOf(address a) public view returns (uint256) { return b[a]; }
    function totalSupply() public view returns (uint256) { return s; }
}
