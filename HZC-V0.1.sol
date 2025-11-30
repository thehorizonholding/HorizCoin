// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract HorizCoinVulnerable {
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function totalSupply() public view returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view returns (uint256) { return _balances[account]; }
    function approve(address, uint256) public pure returns (bool) { return true; }

    constructor() {}

    // CRITICAL FLAW: public mint — no access control
    function mint(address account, uint256 amount) public {
        if (amount == 0) revert();
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
}
