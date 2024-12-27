// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/SushiWallet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SushiWalletTest is Test {
    SushiWallet public wallet;
    address public constant SUSHI_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address public constant MASTER_CHEF = 0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    
    function setUp() public {
        wallet = new SushiWallet(SUSHI_ROUTER, MASTER_CHEF);
    }

    function testJoinLiquidityMining() public {
        // Test implementation will be added in next part
    }
} 