// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/SushiWallet.sol";

contract DeploySushiWallet is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address sushiRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
        address masterChef = 0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd;

        new SushiWallet(sushiRouter, masterChef);

        vm.stopBroadcast();
    }
} 