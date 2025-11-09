// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ALEXFUNDS.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        ALEXFUNDS alexfunds = new ALEXFUNDS();
        
        console.log("ALEXFUNDS deployed to:", address(alexfunds));
        
        vm.stopBroadcast();
    }
}