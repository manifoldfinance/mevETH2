// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/OperatorRegistry.sol";
import "src/mevETH.sol";

contract DeployScript is Script {
    function run() public {
        address _authority = tx.origin;
        address depositContractGoerli = 0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b;
        vm.startBroadcast();
        MevEth mevETH = new MevEth(_authority, depositContractGoerli);
        vm.stopBroadcast();
    }
}
