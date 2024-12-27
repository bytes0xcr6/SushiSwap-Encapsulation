// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IUniswapV2Router02 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
}

contract SushiWallet {
    using SafeERC20 for IERC20;

    IUniswapV2Router02 public immutable sushiRouter;
    IMasterChef public immutable masterChef;
    
    constructor(address _sushiRouter, address _masterChef) {
        sushiRouter = IUniswapV2Router02(_sushiRouter);
        masterChef = IMasterChef(_masterChef);
    }

    function joinLiquidityMining(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 pid,
        uint256 deadline
    ) external {
        // 1. Transfer tokens from user to this contract
        IERC20(tokenA).safeTransferFrom(msg.sender, address(this), amountADesired);
        IERC20(tokenB).safeTransferFrom(msg.sender, address(this), amountBDesired);

        // 2. Approve router to spend tokens
        IERC20(tokenA).safeApprove(address(sushiRouter), amountADesired);
        IERC20(tokenB).safeApprove(address(sushiRouter), amountBDesired);

        // 3. Add liquidity to SushiSwap pool
        (,, uint256 liquidity) = sushiRouter.addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            address(this),
            deadline
        );

        // 4. Get SLP token address
        address pair = getPairAddress(tokenA, tokenB);
        
        // 5. Approve MasterChef to spend SLP tokens
        IERC20(pair).safeApprove(address(masterChef), liquidity);

        // 6. Deposit SLP tokens into MasterChef
        masterChef.deposit(pid, liquidity);
    }

    // Helper function to get pair address (implementation needed)
    function getPairAddress(address tokenA, address tokenB) internal pure returns (address) {
        // Implementation needed - will add in next part
        return address(0);
    }
} 