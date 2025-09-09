// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title HorizCoinToken
 * @notice ERC20 governance token for the HorizCoin ecosystem
 * @dev Implements ERC20Votes for governance functionality with permit support
 */
contract HorizCoinToken is ERC20, ERC20Permit, ERC20Votes, Ownable, ReentrancyGuard {
    /// @notice Maximum token supply (1 billion tokens with 18 decimals)
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18;
    
    /// @notice Whether token transfers are paused
    bool public transfersPaused;
    
    /// @notice Treasury address that can receive initial mint
    address public treasury;
    
    /// @notice Emitted when transfers are paused or unpaused
    event TransfersPausedUpdated(bool paused);
    
    /// @notice Emitted when treasury address is updated
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    
    /// @notice Error thrown when trying to mint beyond max supply
    error ExceedsMaxSupply();
    
    /// @notice Error thrown when transfers are paused
    error TransfersPaused();
    
    /// @notice Error thrown when invalid address provided
    error InvalidAddress();

    /**
     * @notice Constructs the HorizCoin token
     * @param _owner Initial owner of the contract
     * @param _treasury Treasury address for initial mint
     */
    constructor(
        address _owner,
        address _treasury
    ) 
        ERC20("HorizCoin", "HORIZ") 
        ERC20Permit("HorizCoin")
        Ownable(_owner)
    {
        if (_treasury == address(0)) revert InvalidAddress();
        treasury = _treasury;
        
        // Mint initial supply to treasury (can be adjusted based on tokenomics)
        _mint(_treasury, MAX_SUPPLY);
        
        emit TreasuryUpdated(address(0), _treasury);
    }

    /**
     * @notice Sets whether token transfers are paused
     * @param _paused Whether to pause transfers
     */
    function setTransfersPaused(bool _paused) external onlyOwner {
        transfersPaused = _paused;
        emit TransfersPausedUpdated(_paused);
    }

    /**
     * @notice Updates the treasury address
     * @param _newTreasury New treasury address
     */
    function setTreasury(address _newTreasury) external onlyOwner {
        if (_newTreasury == address(0)) revert InvalidAddress();
        address oldTreasury = treasury;
        treasury = _newTreasury;
        emit TreasuryUpdated(oldTreasury, _newTreasury);
    }

    /**
     * @notice Override transfer to check pause status
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        
        if (transfersPaused && from != address(0) && to != address(0)) {
            revert TransfersPaused();
        }
    }

    /**
     * @notice Required override for ERC20Votes
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    /**
     * @notice Required override for ERC20Votes
     */
    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        if (totalSupply() + amount > MAX_SUPPLY) revert ExceedsMaxSupply();
        super._mint(to, amount);
    }

    /**
     * @notice Required override for ERC20Votes
     */
    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}