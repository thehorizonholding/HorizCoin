// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/I1inch.sol";

contract AtomicMSLORouter is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public immutable POC_VAULT;
    ILendingPool public immutable AAVE;
    address constant ONEINCH = 0x1111111254EEB25477B68fb85Ed929f73A960582;

    constructor(address aave, address vault) {
        AAVE = ILendingPool(aave);
        POC_VAULT = vault;
    }

    function executeAtomicArbitrage(
        address asset,
        uint256 amount,
        bytes calldata oneInchCalldata,
        uint256 minProfit
    ) external nonReentrant {
        AAVE.flashLoanSimple(address(this), asset, amount, oneInchCalldata, 0);
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address,
        bytes calldata params
    ) external returns (bool) {
        require(msg.sender == address(AAVE));

        (bool success,) = ONEINCH.call(params);
        require(success, "Swap failed");

        uint256 balance = IERC20(asset).balanceOf(address(this));
        uint256 debt = amount + premium;
        require(balance >= debt + minProfit, "No profit");

        IERC20(asset).safeTransfer(address(AAVE), debt);
        IERC20(asset).safeTransfer(POC_VAULT, balance - debt);

        return true;
    }
}
