// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

/**
 * @title OmegaConquestTreasury
 * @author HorizCoin Conquest Division
 * @notice Decentralized treasury for accumulating tokenized Real-World Assets (RWAs)
 *         using HORIZ rewards. Enables synthetic exposure to global equities.
 * @dev Integrates with Uniswap V2-style routers. Start with tokenized Treasuries,
 *      progress to equities like GOOGLx (Backed Finance) or GOOGLON (Ondo).
 */
contract OmegaConquestTreasury is Ownable, ReentrancyGuard {
    IERC20 public immutable HORIZ;
    address public constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap V2 Ethereum Mainnet

    mapping(address => bool) public approvedRWA;

    event RWAApproved(address indexed rwa);
    event RWAConquered(address indexed rwa, uint256 horizIn, uint256 rwaOut);
    event FundsRescued(address indexed token, uint256 amount);

    constructor(address _horiz) Ownable(msg.sender) {
        require(_horiz != address(0), "Invalid HORIZ address");
        HORIZ = IERC20(_horiz);
    }

    /**
     * @notice Approve a tokenized RWA for conquest (e.g., GOOGLx, OUSG, BUIDL)
     */
    function approveRWA(address rwa) external onlyOwner {
        require(rwa != address(0), "Invalid RWA address");
        approvedRWA[rwa] = true;
        emit RWAApproved(rwa);
    }

    /**
     * @notice Execute conquest: swap HORIZ for approved RWA
     * @param amountHORIZ Amount of HORIZ to spend
     * @param targetRWA Target RWA token address
     * @param minOut Minimum acceptable RWA output (slippage protection)
     */
    function conquerRWA(
        uint256 amountHORIZ,
        address targetRWA,
        uint256 minOut
    ) external onlyOwner nonReentrant {
        require(approvedRWA[targetRWA], "RWA not approved");
        require(amountHORIZ > 0, "Zero amount");

        HORIZ.approve(ROUTER, amountHORIZ);

        address[] memory path = new address[](2);
        path[0] = address(HORIZ);
        path[1] = targetRWA;

        uint[] memory amounts = IUniswapV2Router(ROUTER).swapExactTokensForTokens(
            amountHORIZ,
            minOut,
            path,
            address(this),
            block.timestamp + 1800
        );

        emit RWAConquered(targetRWA, amountHORIZ, amounts[1]);
    }

    /**
     * @notice Emergency rescue of any ERC20 token
     */
    function rescueFunds(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner(), amount);
        emit FundsRescued(token, amount);
    }
}
