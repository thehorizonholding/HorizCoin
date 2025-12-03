// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IAave {
    function flashLoanSimple(address receiver, address asset, uint256 amount, bytes calldata params, uint16) external;
}

interface I1inch {
    function swap(address, address, uint256, uint256, bytes calldata) external returns (uint256);
}

contract AtomicMSLORouter {
    using SafeERC20 for IERC20;
    address public immutable POC_VAULT;
    address constant ONEINCH = 0x1111111254EEB25477B68fb85Ed929f73A960582;

    constructor(address vault) { POC_VAULT = vault; }

    function execute(bytes calldata oneInchData) external {
        IAave(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2).flashLoanSimple(
            address(this), 0xFF970A61A04b1cA14834A43f5dE4533EbDDB5CC8, 1, oneInchData, 0
        );
    }

    function executeOperation(address, address, uint256, uint256, address, bytes calldata data) external returns (bool) {
        (bool s,) = ONEINCH.call(data);
        require(s);
        uint256 profit = IERC20(0xFF970A61A04b1cA14834A43f5dE4533EbDDB5CC8).balanceOf(address(this));
        IERC20(0xFF970A61A04b1cA14834A43f5dE4533EbDDB5CC8).safeTransfer(POC_VAULT, profit);
        return true;
    }
}
