// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import {SushiWallet} from "../src/SushiWallet.sol";

/**
 * @title SushiWallet Deploy Script
 * @author 0xCR6 - https://www.0xcr6.dev
 * @dev Script to deploy SushiWallet contract to Arbitrum
 */
contract SushiWalletScript is Script {
    event WalletDeployed(address wallet);

    // Arbitrum One addresses
    address public constant SUSHI_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address public constant MASTER_CHEF = 0xF4d73326C13a4Fc5FD7A064217e12780e9Bd62c3;

    function run() public {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy SushiWallet
        SushiWallet wallet = new SushiWallet(
            SUSHI_ROUTER,
            MASTER_CHEF
        );

        // Emit event for test to capture
        emit WalletDeployed(address(wallet));

        console.log("SushiWallet deployed to:", address(wallet));

        vm.stopBroadcast();
    }
} 