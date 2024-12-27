// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {SushiWallet} from "../src/SushiWallet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IMasterChefV2 {
    function deposit(uint256 pid, uint256 amount, address to) external;
    function withdraw(uint256 pid, uint256 amount, address to) external;
    function poolLength() external view returns (uint256);
    function lpToken(uint256 pid) external view returns (address);
    function userInfo(uint256 pid, address user) external view returns (
        uint256 amount,     // How many LP tokens the user has provided
        uint256 rewardDebt  // Reward debt
    );
}

contract SushiWalletTest is Test {
    SushiWallet public wallet;
    
    // Arbitrum One addresses
    address public constant SUSHI_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address public constant MASTER_CHEF = 0xF4d73326C13a4Fc5FD7A064217e12780e9Bd62c3;
    
    // Arbitrum One token addresses
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    
    address public whale;
    uint256 public pid;

    event LiquidityAdded(uint256 wethAmount, uint256 usdcAmount, uint256 lpAmount);
    event LiquidityRemoved(uint256 wethAmount, uint256 usdcAmount, uint256 lpAmount);

    function setUp() public {
        try vm.envString("ARBITRUM_RPC_URL") returns (string memory rpcUrl) {
            vm.createSelectFork(rpcUrl);
        } catch {
            console.log("Warning: No RPC URL provided, running in local environment");
        }
        
        // Find pool ID for WETH-USDC pair
        pid = _findPoolId(WETH, USDC);
        console.log("Found WETH-USDC pool ID:", pid);

        // Create and fund whale account
        whale = makeAddr("whale");
        vm.deal(whale, 100 ether);
        deal(WETH, whale, 100 ether);
        deal(USDC, whale, 1_000_000 * 1e6);

        // Deploy wallet
        vm.startPrank(whale);
        wallet = new SushiWallet(SUSHI_ROUTER, MASTER_CHEF);
        vm.stopPrank();
    }

    function testWhaleBalances() public view {
        assertEq(whale.balance, 100 ether, "Incorrect ETH balance");
        assertEq(IERC20(WETH).balanceOf(whale), 100 ether, "Incorrect WETH balance");
        assertEq(IERC20(USDC).balanceOf(whale), 1_000_000 * 1e6, "Incorrect USDC balance");
        
        _logBalances("Whale", IERC20(WETH).balanceOf(whale), IERC20(USDC).balanceOf(whale));
    }

    struct OperationState {
        uint256 wethAmount;
        uint256 usdcAmount;
        uint256 initialWeth;
        uint256 initialUsdc;
        uint256 finalWeth;
        uint256 finalUsdc;
        uint256 stakedAmount;
        uint256 rewardDebt;
        uint256 sushiRewards;
    }

    function testLiquidityMiningFullCycle() public {
        OperationState memory state;
        state.wethAmount = 0.1 ether;
        
        vm.warp(1000);
        vm.startPrank(whale);
        
        // Get initial balances
        state.initialWeth = IERC20(WETH).balanceOf(whale);
        state.initialUsdc = IERC20(USDC).balanceOf(whale);
        
        _logSummary(
            "LIQUIDITY MINING OPERATION START",
            state.initialWeth,
            state.initialUsdc,
            0,
            0
        );
        
        // Calculate USDC amount and approve tokens
        state.usdcAmount = _getOptimalUSDCAmount(state.wethAmount);
        IERC20(WETH).approve(address(wallet), type(uint256).max);
        IERC20(USDC).approve(address(wallet), type(uint256).max);

        _logSummary(
            "DEPOSITING TO LIQUIDITY POOL",
            state.wethAmount,
            state.usdcAmount,
            0,
            0
        );

        // Join liquidity mining
        wallet.joinLiquidityMining(
            WETH,
            USDC,
            state.wethAmount,
            state.usdcAmount,
            state.wethAmount * 95 / 100,
            state.usdcAmount * 95 / 100,
            pid,
            block.timestamp + 1 hours
        );

        // Get staking info after join
        (state.stakedAmount, state.rewardDebt) = IMasterChefV2(MASTER_CHEF).userInfo(pid, address(wallet));
        _logSummary(
            "POSITION AFTER STAKING (1 BLOCK)",
            IERC20(WETH).balanceOf(whale),
            IERC20(USDC).balanceOf(whale),
            state.stakedAmount,
            state.rewardDebt
        );

        // Advance by 1 block
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 2); // 2 seconds per block
        
        // Get updated staking info
        (state.stakedAmount, state.rewardDebt) = IMasterChefV2(MASTER_CHEF).userInfo(pid, address(wallet));
        state.sushiRewards = state.rewardDebt;

        _logSummary(
            "POSITION AFTER 1 BLOCK",
            IERC20(WETH).balanceOf(whale),
            IERC20(USDC).balanceOf(whale),
            state.stakedAmount,
            state.rewardDebt
        );

        // Exit liquidity mining
        wallet.exitLiquidityMining(
            WETH,
            USDC,
            state.stakedAmount,
            0,
            0,
            pid,
            block.timestamp + 30 minutes
        );

        // Get final balances
        state.finalWeth = IERC20(WETH).balanceOf(whale);
        state.finalUsdc = IERC20(USDC).balanceOf(whale);

        _logSummary(
            "FINAL POSITION AFTER UNSTAKING",
            state.finalWeth,
            state.finalUsdc,
            0,
            state.sushiRewards
        );

        _logOperationSummary(state);

        vm.stopPrank();
    }

    function _logOperationSummary(OperationState memory state) internal pure {
        console.log("\n[!] OPERATION SUMMARY [!]");
        console.log("----------------------------------------");
        console.log("Initial Investment");
        console.log("  WETH Amount:      ", _formatWeth(state.wethAmount), "WETH");
        console.log("  USDC Amount:      ", _formatUsdc(state.usdcAmount), "USDC");
        console.log("  Total USD Value: $", _formatUsdc(state.usdcAmount + (state.wethAmount * 1800 / 1e18 * 1e6)));
        
        console.log("\nReturns After 1 Block");
        
        int256 wethDiff = int256(state.finalWeth) - int256(state.initialWeth);
        int256 usdcDiff = int256(state.finalUsdc) - int256(state.initialUsdc);
        
        if (wethDiff >= 0) {
            console.log("  WETH Profit:     ", _formatWeth(uint256(wethDiff)), "WETH");
        } else {
            console.log("  WETH Loss:       ", _formatWeth(uint256(-wethDiff)), "WETH");
        }
        
        if (usdcDiff >= 0) {
            console.log("  USDC Profit:     ", _formatUsdc(uint256(usdcDiff)), "USDC");
        } else {
            console.log("  USDC Loss:       ", _formatUsdc(uint256(-usdcDiff)), "USDC");
        }

        if (state.sushiRewards > 0) {
            console.log("  SUSHI Rewards:    ", _formatWeth(state.sushiRewards), "SUSHI");
            uint256 apr = _calculateAPR(state.wethAmount, state.usdcAmount, state.sushiRewards);
            console.log("\nProjected Returns (if rate stays constant)");
            console.log("  Daily Rate:       ", (apr / 365), "%");
            console.log("  APR:              ", apr, "%");
        }
        
        console.log("\nFinal Position");
        console.log("  WETH Balance:     ", _formatWeth(state.finalWeth), "WETH");
        console.log("  USDC Balance:     ", _formatUsdc(state.finalUsdc), "USDC");
        if (state.sushiRewards > 0) {
            console.log("  SUSHI Balance:    ", _formatWeth(state.sushiRewards), "SUSHI");
        }
        console.log("----------------------------------------");
    }

    function _calculateAPR(uint256 wethAmount, uint256 usdcAmount, uint256 sushiRewards) internal pure returns (uint256) {
        // Calculate APR based on rewards per block
        // APR = (rewards per block * blocks per year) / principal * 100
        uint256 totalValueInWeth = wethAmount + (usdcAmount * 1e12); // Convert USDC to 18 decimals
        if (totalValueInWeth == 0) return 0;
        
        // Arbitrum averages ~2.5M blocks per year (2 sec block time)
        uint256 blocksPerYear = 31_536_000 / 2; // seconds in year / seconds per block
        return (sushiRewards * blocksPerYear * 100) / totalValueInWeth;
    }

    function test_RevertWhen_InsufficientBalance() public {
        address poor = makeAddr("poor");
        vm.startPrank(poor);
        
        vm.expectRevert();
        wallet.joinLiquidityMining(
            WETH,
            USDC,
            1 ether,
            3000e6,
            0,
            0,
            pid,
            block.timestamp + 1 hours
        );
        
        vm.stopPrank();
    }

    // Helper functions remain unchanged
    function _findPoolId(address tokenA, address tokenB) internal view returns (uint256) {
        IMasterChefV2 chef = IMasterChefV2(MASTER_CHEF);
        uint256 poolLength = chef.poolLength();
        
        for(uint256 i = 0; i < poolLength; i++) {
            address lpToken = chef.lpToken(i);
            if(_isPairForTokens(lpToken, tokenA, tokenB)) {
                return i;
            }
        }
        revert("Pool not found");
    }

    function _isPairForTokens(address pair, address tokenA, address tokenB) internal view returns (bool) {
        if (pair == address(0)) return false;
        
        try IUniswapV2Pair(pair).token0() returns (address token0) {
            address token1 = IUniswapV2Pair(pair).token1();
            return (token0 == tokenA && token1 == tokenB) || (token0 == tokenB && token1 == tokenA);
        } catch {
            return false;
        }
    }

    function _getOptimalUSDCAmount(uint256 wethAmount) internal view returns (uint256) {
        address pair = IMasterChefV2(MASTER_CHEF).lpToken(pid);
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();
        
        address token0 = IUniswapV2Pair(pair).token0();
        
        (uint256 wethReserve, uint256 usdcReserve) = token0 == WETH 
            ? (uint256(reserve0), uint256(reserve1))
            : (uint256(reserve1), uint256(reserve0));
            
        return (wethAmount * usdcReserve) / wethReserve;
    }

    // Helper functions for displaying values with decimals
    function _logBalances(string memory prefix, uint256 wethBalance, uint256 usdcBalance) internal pure {
        console.log(string.concat(prefix, " WETH:"), _formatWeth(wethBalance), "WETH");
        console.log(string.concat(prefix, " WETH (wei):"), wethBalance);
        console.log(string.concat(prefix, " USDC:"), _formatUsdc(usdcBalance), "USDC");
        console.log(string.concat(prefix, " USDC (wei):"), usdcBalance);
    }

    function _logPoolState(string memory prefix, uint256 wethReserve, uint256 usdcReserve) internal pure {
        console.log(string.concat(prefix, " Pool WETH:"), _formatWeth(wethReserve), "WETH");
        console.log(string.concat(prefix, " Pool USDC:"), _formatUsdc(usdcReserve), "USDC");
    }

    function _logStakingInfo(string memory prefix, uint256 stakedAmount, uint256 rewardDebt) internal pure {
        console.log(string.concat(prefix, " Staked LP:"), _formatWeth(stakedAmount), "SLP");
        console.log(string.concat(prefix, " Staked LP (wei):"), stakedAmount);
        console.log(string.concat(prefix, " Reward Debt:"), _formatWeth(rewardDebt));
        console.log(string.concat(prefix, " Reward Debt (wei):"), rewardDebt);
    }

    function _formatWeth(uint256 amount) internal pure returns (string memory) {
        // Format with 18 decimals
        uint256 whole = amount / 1e18;
        uint256 fraction = amount % 1e18;
        if (fraction == 0) {
            return vm.toString(whole);
        }
        // Format fraction to 6 decimal places for readability
        fraction = fraction / 1e12;
        string memory fractionStr = vm.toString(fraction);
        // Pad with leading zeros if needed
        while (bytes(fractionStr).length < 6) {
            fractionStr = string.concat("0", fractionStr);
        }
        return string.concat(vm.toString(whole), ".", fractionStr);
    }

    function _formatUsdc(uint256 amount) internal pure returns (string memory) {
        // Format with 6 decimals
        uint256 whole = amount / 1e6;
        uint256 fraction = amount % 1e6;
        if (fraction == 0) {
            return vm.toString(whole);
        }
        string memory fractionStr = vm.toString(fraction);
        // Pad with leading zeros if needed
        while (bytes(fractionStr).length < 6) {
            fractionStr = string.concat("0", fractionStr);
        }
        return string.concat(vm.toString(whole), ".", fractionStr);
    }

    function _logSummary(
        string memory title,
        uint256 wethAmount,
        uint256 usdcAmount,
        uint256 lpAmount,
        uint256 rewardDebt
    ) internal pure {
        console.log("\n[!]  ", title, "  [!]");
        console.log("----------------------------------------");
        console.log("WETH Balance:    ", _formatWeth(wethAmount), "WETH");
        console.log("USDC Balance:    ", _formatUsdc(usdcAmount), "USDC");
        if (lpAmount > 0) {
            console.log("Staked LP:       ", _formatWeth(lpAmount), "SLP");
        }
        if (rewardDebt > 0) {
            console.log("SUSHI Rewards:   ", _formatWeth(rewardDebt), "SUSHI");
        }
        console.log("----------------------------------------");
    }
} 