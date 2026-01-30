// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LeoGiaSwap.sol";

contract DeployLeoGiaSwap is Script {
    function run() external {
        uint256 key = vm.envUint("PRIVATE_KEY");

        // 🔴 USE YOUR REAL TOKEN ADDRESSES
        address LEO = 0x265AEd0ddc0f03a382Ea3361eE17572D59282F5e;
        address GIA = 0xC8E0713C9E5F2AcF37C21aD7AfE61568C749b57f;

        vm.startBroadcast(key);

        LeoGiaSwap swap = new LeoGiaSwap(LEO, GIA);

        vm.stopBroadcast();

        console2.log("LeoGiaSwap deployed at:", address(swap));
    }
}
