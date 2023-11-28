// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import { IMevEth } from "src/interfaces/IMevEth.sol";
import { MevEthRateProvider } from "src/MevEthRateProvider.sol";

contract DeployRateProviderScript is Script {
    IMevEth mevEth = IMevEth(0x24Ae2dA0f361AA4BE46b48EB19C91e02c5e4f27E);

    function run() public {
        vm.startBroadcast();
        // deploy MevEthRateProvider
        new MevEthRateProvider(mevEth);
        vm.stopBroadcast();
    }
}
