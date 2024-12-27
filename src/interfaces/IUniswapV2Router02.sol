// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title IUniswapV2Router02 Interface
 * @author SushiSwap
 * @dev Interface for SushiSwap's Router contract that handles liquidity provision
 * @notice Interface for interacting with SushiSwap's Router to add liquidity
 */
interface IUniswapV2Router02 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
}
