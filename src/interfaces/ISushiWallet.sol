// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title ISushiWallet
 * @author 0xCR6 - https://www.0xcr6.dev
 * @notice Interface for the SushiWallet contract
 * @dev Defines the events and functions for managing SushiSwap liquidity positions
 */
interface ISushiWallet {
    /**
     * @notice Emitted when liquidity is added to a pool and staked
     * @param user The address that added liquidity
     * @param tokenA The first token of the pair
     * @param tokenB The second token of the pair
     * @param amountA The amount of tokenA added
     * @param amountB The amount of tokenB added
     * @param liquidity The amount of LP tokens received
     */
    event LiquidityAdded(
        address indexed user,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    /**
     * @notice Emitted when liquidity is removed from a pool
     * @param user The address that removed liquidity
     * @param tokenA The first token of the pair
     * @param tokenB The second token of the pair
     * @param amountA The amount of tokenA received
     * @param amountB The amount of tokenB received
     */
    event LiquidityRemoved(
        address indexed user, address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB
    );

    /**
     * @notice Adds liquidity to a SushiSwap pool and stakes the LP tokens
     * @param tokenA The first token of the pair
     * @param tokenB The second token of the pair
     * @param amountADesired The amount of tokenA to add
     * @param amountBDesired The amount of tokenB to add
     * @param amountAMin Minimum amount of tokenA to add
     * @param amountBMin Minimum amount of tokenB to add
     * @param pid The pool ID in MasterChef
     * @param deadline The deadline for the transaction
     */
    function joinLiquidityMining(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 pid,
        uint256 deadline
    ) external;

    /**
     * @notice Withdraws LP tokens and removes liquidity from SushiSwap
     * @param tokenA The first token of the pair
     * @param tokenB The second token of the pair
     * @param liquidity The amount of LP tokens to withdraw
     * @param amountAMin Minimum amount of tokenA to receive
     * @param amountBMin Minimum amount of tokenB to receive
     * @param pid The pool ID in MasterChef
     * @param deadline The deadline for the transaction
     */
    function exitLiquidityMining(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 pid,
        uint256 deadline
    ) external;
}
