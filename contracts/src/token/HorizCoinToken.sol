// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title HorizCoinToken
 * @notice ERC20 token with ERC20Votes (includes Permit) for governance from inception.
 *         Minting is restricted to the owner (expected to be an emission controller
 *         or multisig early on; later transferred to governance-controlled executor).
 *
 *         Optional maxSupply (0 => uncapped at contract level).
 *
 * SECURITY NOTES:
 * - Governance should impose emission / mint rate bounds externally.
 * - If a capped supply model is chosen, set a non-zero maxSupply at deployment.
 * - Vote delegation is available immediately; snapshot/checkpoint logic provided by ERC20Votes.
 */
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {ERC20Votes} from "openzeppelin-contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

contract HorizCoinToken is ERC20, ERC20Votes, Ownable {
    uint256 public immutable maxSupply;

    event Mint(address indexed to, uint256 amount);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 _maxSupply
    ) ERC20(name_, symbol_) ERC20Permit(name_) Ownable(msg.sender) {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Mint new tokens. Restricted to owner (emission controller or governance executor).
     */
    function mint(address to, uint256 amount) external onlyOwner {
        if (maxSupply != 0 && totalSupply() + amount > maxSupply) {
            revert("MAX_SUPPLY_EXCEEDED");
        }
        _mint(to, amount);
        emit Mint(to, amount);
    }

    // ----- Required Overrides for ERC20Votes -----

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}
