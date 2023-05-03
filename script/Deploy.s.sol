// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/ManifoldLSD.sol";
import "../src/MevETH.sol";
import "../src/OperatorRegistery.sol";

contract DeployScript is Script {

    function run() public {
        vm.startBroadcast();
        address _beaconDepositAddress = address(0);
        address crossChainEndpoint = address(0);
        ManifoldLSD lsd = new ManifoldLSD("Manifold LSD", "mLSD", 18, _beaconDepositAddress);
        MevETH mevETH = new MevETH("Mev staked Ethereum", "mevETH", 18, address(lsd), crossChainEndpoint);
        lsd.setMevETH(address(mevETH));
        OperatorRegistery op = new OperatorRegistery(address(lsd));
        vm.stopBroadcast();
    }
}
