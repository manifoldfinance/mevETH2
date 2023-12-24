// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import { IAuth } from "src/interfaces/IAuth.sol";
import { AuthManager } from "src/libraries/AuthManager.sol";

contract AuthManagerDeployScript is Script {
    function run() public {
        address safe = 0x617c8dE5BdE54ffbb8d92716CC947858cA38f582;
        address authority = safe;
        address mevEth = 0x24Ae2dA0f361AA4BE46b48EB19C91e02c5e4f27E;
        address initialShareVault = safe;
        address initialStakingModule = 0xc5920c99d09E5444C079C01F06763b5d6AB09CbB;

        vm.startBroadcast();
        // deploy AuthManager
        AuthManager authManager = new AuthManager(authority, mevEth, initialShareVault, initialStakingModule);
        // set AuthManager as admin
        IAuth(mevEth).addAdmin(address(authManager));
        IAuth(initialStakingModule).addAdmin(address(authManager));

        vm.stopBroadcast();
    }
}
