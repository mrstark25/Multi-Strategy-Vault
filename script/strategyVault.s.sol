// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/vaults/strategyVault.sol";
import "../src/mocks/MockUSDC.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        MockUSDC usdc = new MockUSDC();
        MultiStrategyVault vault = new MultiStrategyVault(usdc);

        vm.stopBroadcast();
    }
}
