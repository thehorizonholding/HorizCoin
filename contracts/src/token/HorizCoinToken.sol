// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title HorizCoinToken
/// @notice Governance-enabled ERC20 token with capped supply and owner-controlled minting.
/// @dev Inherits OpenZeppelin ERC20Votes stack; owner should later be transferred to a timelock / governor.
contract HorizCoinToken is ERC20, ERC20Permit, ERC20Votes, Ownable {
    /// @notice Maximum token supply (immutable cap)
    uint256 public immutable maxSupply;

    /// @param name_ Token name
    /// @param symbol_ Token symbol
    /// @param maxSupply_ Hard cap for total supply
    constructor(string memory name_, string memory symbol_, uint256 maxSupply_)
        ERC20(name_, symbol_)
        ERC20Permit(name_)
        Ownable(msg.sender) // OZ v5 Ownable takes initial owner arg
    {
        require(maxSupply_ > 0, "Cap=0");
        maxSupply = maxSupply_;
    }

    /// @notice Mint new tokens up to the max supply cap.
    /// @param to Recipient address
    /// @param amount Amount to mint
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Cap exceeded");
        _mint(to, amount);
    }

    // ---------------------------------------------------------------------
    // Overrides required by Solidity for ERC20Votes (block-based checkpoints)
    // ---------------------------------------------------------------------

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    function nonces(address owner) public view override(ERC20Permit, ERC20Votes) returns (uint256) {
        return super.nonces(owner);
    }
}
