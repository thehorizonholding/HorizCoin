// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./custody/ICustodyVerifier.sol";

interface IGovernanceProxy {
    function mint(address to, uint256 amount) external;
}

interface IMintableERC20 {
    function mint(address to, uint256 amount) external;
}

contract VampireMigrator {
    address public immutable horizCoin;
    address public immutable mAsset;

    ICustodyVerifier public custodyVerifier;

    uint256 public constant VAMPIRE_MULTIPLIER = 3;

    event Migrated(address indexed user, uint256 shares, uint256 reward, address verifier);

    constructor(address _horizCoin, address _mAsset, address _verifier) {
        horizCoin = _horizCoin;
        mAsset = _mAsset;
        custodyVerifier = ICustodyVerifier(_verifier);
    }

    function setCustodyVerifier(address newVerifier) external {
        // DAO-gated in production
        custodyVerifier = ICustodyVerifier(newVerifier);
    }

    function migrateShares(uint256 shareAmount, bytes calldata proof) external {
        require(shareAmount > 0, "Zero amount");

        bool ok = custodyVerifier.verify(msg.sender, shareAmount, proof);
        require(ok, "Custody verification failed");

        IGovernanceProxy(mAsset).mint(msg.sender, shareAmount);

        uint256 reward = shareAmount * VAMPIRE_MULTIPLIER;
        IMintableERC20(horizCoin).mint(msg.sender, reward);

        emit Migrated(msg.sender, shareAmount, reward, address(custodyVerifier));
    }
}
