// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/GIA.sol";

contract DeployGIA is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        // 🪙 GIA supply config
        uint256 initialSupply = 500_000 ether;   // 500k GIA
        uint256 maxSupply     = 5_000_000 ether; // 5M GIA cap

        vm.startBroadcast(deployerKey);

        GIA gia = new GIA(initialSupply, maxSupply);

        vm.stopBroadcast();

        console2.log("GIA deployed at:", address(gia));
    }
}
