// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title IMasterChef Interface
 * @author SushiSwap
 * @dev Interface for SushiSwap's MiniChefV2 contract that handles farming rewards on Arbitrum
 * @notice Interface for interacting with SushiSwap's farming contract to deposit LP tokens
 */
interface IMasterChef {
    function deposit(uint256 pid, uint256 amount, address to) external;
    function withdraw(uint256 pid, uint256 amount, address to) external;
    function harvest(uint256 pid, address to) external;
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;
    function emergencyWithdraw(uint256 pid, address to) external;
}
