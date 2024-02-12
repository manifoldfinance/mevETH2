// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import { MevEth } from "src/MevEth.sol";
import { IAuth } from "src/interfaces/IAuth.sol";
import { WagyuStaker } from "src/WagyuStaker.sol";
import { AuthManager } from "src/libraries/AuthManager.sol";
import { IStakingModule } from "src/interfaces/IStakingModule.sol";

contract DeployStakerScript is Script {
    error UnknownChain();

    function run() public {
        address authority = tx.origin; // make deployer initial authority for setup
        address operator = 0xA0766B65A4f7B1da79a1AF79aC695456eFa28644; // manifoldfinance.eth
        address multisig = 0x617c8dE5BdE54ffbb8d92716CC947858cA38f582;
        uint256 chainId;
        address beaconDepositContract;
        address weth;
        address mevEth = 0x24Ae2dA0f361AA4BE46b48EB19C91e02c5e4f27E;
        assembly {
            chainId := chainid()
        }
        if (chainId == 1) {
            // Eth mainnet
            beaconDepositContract = 0x00000000219ab540356cBB839Cbe05303d7705Fa;
            weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        } else if (chainId == 5) {
            // Goerli
            beaconDepositContract = 0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b;
            weth = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
        } else {
            revert UnknownChain();
        }

        vm.startBroadcast();

        // deploy staking module
        WagyuStaker wagyu = new WagyuStaker(authority, beaconDepositContract, mevEth, multisig);

        // setup roles
        // multisig is admin
        wagyu.addAdmin(multisig);
        if (authority != operator) {
            // manifoldfinance.eth is operator
            wagyu.addOperator(operator);
            // remove deployer as operator
            wagyu.deleteOperator(authority);
        }
        // remove deployer as admin
        wagyu.deleteAdmin(authority);

        vm.stopBroadcast();
    }
}
