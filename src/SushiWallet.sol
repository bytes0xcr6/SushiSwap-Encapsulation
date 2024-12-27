// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";
import {IMasterChef} from "./interfaces/IMasterChef.sol";
import {ISushiWallet} from "./interfaces/ISushiWallet.sol";
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";

/**
 * @title SushiWallet
 * @author 0xCR6 - https://www.0xcr6.dev
 * @notice A contract for managing SushiSwap liquidity positions and yield farming
 * @dev This contract handles adding and removing liquidity from SushiSwap pools and staking in MasterChef
 */
contract SushiWallet is ISushiWallet {
    using SafeERC20 for IERC20;

    /// @notice SushiSwap Router contract for liquidity operations
    IUniswapV2Router02 public immutable SUSHI_ROUTER;

    /// @notice MasterChef contract for staking LP tokens
    IMasterChef public immutable MASTER_CHEF;

    /// @notice SushiSwap Factory contract for getting LP pair addresses
    IUniswapV2Factory public immutable SUSHI_FACTORY;

    /**
     * @notice Initializes the SushiWallet contract
     * @param _sushiRouter Address of the SushiSwap Router contract
     * @param _masterChef Address of the MasterChef staking contract
     */
    constructor(address _sushiRouter, address _masterChef) {
        SUSHI_ROUTER = IUniswapV2Router02(_sushiRouter);
        MASTER_CHEF = IMasterChef(_masterChef);
        SUSHI_FACTORY = IUniswapV2Factory(0xc35DADB65012eC5796536bD9864eD8773aBc74C4); // Arbitrum SushiSwap Factory
    }

    /**
     * @notice Adds liquidity to a SushiSwap pool and stakes the LP tokens in MasterChef
     * @dev Transfers tokens from user, adds liquidity, and stakes LP tokens
     * @param tokenA The first token of the pair
     * @param tokenB The second token of the pair
     * @param amountADesired The amount of tokenA to add as liquidity
     * @param amountBDesired The amount of tokenB to add as liquidity
     * @param amountAMin The minimum amount of tokenA to add (slippage protection)
     * @param amountBMin The minimum amount of tokenB to add (slippage protection)
     * @param pid The pool ID in MasterChef for staking
     * @param deadline The deadline for the transaction to be executed
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
    ) external {
        // 1. Transfer tokens from user to this contract
        IERC20(tokenA).safeTransferFrom(msg.sender, address(this), amountADesired);
        IERC20(tokenB).safeTransferFrom(msg.sender, address(this), amountBDesired);

        // 2. Approve router to spend tokens
        IERC20(tokenA).approve(address(SUSHI_ROUTER), amountADesired);
        IERC20(tokenB).approve(address(SUSHI_ROUTER), amountBDesired);

        // 3. Add liquidity to SushiSwap pool
        (,, uint256 liquidity) = SUSHI_ROUTER.addLiquidity(
            tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, address(this), deadline
        );

        // 4. Get SLP token address
        address pair = getPairAddress(tokenA, tokenB);

        // 5. Approve MasterChef to spend SLP tokens
        IERC20(pair).approve(address(MASTER_CHEF), liquidity);

        // 6. Deposit SLP tokens into MasterChef
        MASTER_CHEF.deposit(pid, liquidity, address(this));

        // Emit event
        emit LiquidityAdded(msg.sender, tokenA, tokenB, amountADesired, amountBDesired, liquidity);
    }

    /**
     * @notice Gets the LP token address for a pair of tokens
     * @dev Uses SushiSwap Factory to find the pair address
     * @param tokenA The first token of the pair
     * @param tokenB The second token of the pair
     * @return The address of the LP token
     */
    function getPairAddress(address tokenA, address tokenB) internal view returns (address) {
        return SUSHI_FACTORY.getPair(tokenA, tokenB);
    }

    /**
     * @notice Withdraws LP tokens from MasterChef and removes liquidity from SushiSwap
     * @dev Unstakes LP tokens and removes liquidity, sending tokens directly to user
     * @param tokenA The first token of the pair
     * @param tokenB The second token of the pair
     * @param liquidity The amount of LP tokens to withdraw
     * @param amountAMin The minimum amount of tokenA to receive (slippage protection)
     * @param amountBMin The minimum amount of tokenB to receive (slippage protection)
     * @param pid The pool ID in MasterChef
     * @param deadline The deadline for the transaction to be executed
     */
    function exitLiquidityMining(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 pid,
        uint256 deadline
    ) external {
        // 1. Get SLP token address
        address pair = getPairAddress(tokenA, tokenB);

        // 2. Withdraw LP tokens from MasterChef
        MASTER_CHEF.withdraw(pid, liquidity, address(this));

        // 3. Approve router to spend LP tokens
        IERC20(pair).approve(address(SUSHI_ROUTER), liquidity);

        // 4. Remove liquidity from SushiSwap pool
        (uint256 amountA, uint256 amountB) = SUSHI_ROUTER.removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            msg.sender, // Send tokens directly to user
            deadline
        );

        emit LiquidityRemoved(msg.sender, tokenA, tokenB, amountA, amountB);
    }
}
