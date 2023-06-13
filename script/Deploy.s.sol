// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "src/MevEth.sol";

contract DeployScript is Script {
    function run() public {
        address _authority = tx.origin;
        address depositContractGoerli = 0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b;
        address goerliWETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
        vm.startBroadcast();
        MevEth mevETH = new MevEth(_authority, depositContractGoerli, address(goerliWETH));
        vm.stopBroadcast();
    }
}
