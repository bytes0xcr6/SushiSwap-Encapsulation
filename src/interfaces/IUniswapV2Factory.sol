// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title IUniswapV2Factory Interface
 * @author SushiSwap
 * @dev Interface for SushiSwap's Factory contract that manages liquidity pools
 * @notice Interface for interacting with SushiSwap's Factory to get pool addresses
 */
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
