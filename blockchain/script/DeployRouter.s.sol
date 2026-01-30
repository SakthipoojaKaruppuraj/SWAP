// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SwapRouter.sol";

contract DeployRouter is Script {
    function run() external {
        uint256 key = vm.envUint("PRIVATE_KEY");

        // 🔴 UPDATE AFTER SWAP DEPLOY
        address swap = 0x25914a498Ac0B2d99d6b0405d7720e6B2B5983A5;

        vm.startBroadcast(key);

        SwapRouter router = new SwapRouter(swap);

        vm.stopBroadcast();

        console2.log("Router deployed at:", address(router));
    }
}
