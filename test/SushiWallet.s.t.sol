// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import {SushiWalletScript} from "../script/SushiWallet.s.sol";
import {SushiWallet} from "../src/SushiWallet.sol";

contract SushiWalletScriptTest is Test {
    SushiWalletScript public deployer;
    event WalletDeployed(address wallet);

    function setUp() public {
        try vm.envString("ARBITRUM_RPC_URL") returns (string memory rpcUrl) {
            vm.createSelectFork(rpcUrl);
        } catch {
            console.log("Warning: No RPC URL provided, running in local environment");
        }
        
        deployer = new SushiWalletScript();
    }

    function testDeployment() public {
        // Generate a private key and corresponding address
        uint256 privateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployerAddress = vm.addr(privateKey);
        
        // Fund the deployer account
        vm.deal(deployerAddress, 1 ether);
        
        // Set the private key in environment
        vm.setEnv("PRIVATE_KEY", vm.toString(privateKey));

        // Run deployment script and capture the deployed address
        vm.recordLogs();
        deployer.run();

        // Get the deployment logs
        Vm.Log[] memory logs = vm.getRecordedLogs();
        
        // Get the deployed contract address from the WalletDeployed event
        address walletAddress = address(0);
        for (uint i = 0; i < logs.length; i++) {
            // Look for WalletDeployed event
            if (logs[i].topics[0] == keccak256("WalletDeployed(address)")) {
                // The address is in the data field since it's not indexed
                walletAddress = abi.decode(logs[i].data, (address));
                break;
            }
        }

        require(walletAddress != address(0), "Failed to find deployed contract address");

        // Create wallet instance
        SushiWallet wallet = SushiWallet(walletAddress);

        // Verify the wallet exists and was deployed correctly
        uint256 size;
        assembly {
            size := extcodesize(walletAddress)
        }
        assertTrue(size > 0, "Contract not deployed");
        
        // Check constructor parameters were set correctly
        assertEq(address(wallet.SUSHI_ROUTER()), deployer.SUSHI_ROUTER());
        assertEq(address(wallet.MASTER_CHEF()), deployer.MASTER_CHEF());
    }
} 