// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Leo.sol";

contract DeployLeo is Script {
    function run() external {
        // 🔐 Load deployer private key from env
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        // 🪙 Constructor params
        uint256 initialSupply = 1_000_000 ether; // 1M LEO
        uint256 maxSupply     = 10_000_000 ether; // 10M LEO cap

        vm.startBroadcast(deployerKey);

        Leo leo = new Leo(initialSupply, maxSupply);

        vm.stopBroadcast();

        console2.log("LEO deployed at:", address(leo));
    }
}
