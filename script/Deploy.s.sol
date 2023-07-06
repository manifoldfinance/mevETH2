// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import { MevEth } from "src/MevEth.sol";
import { WagyuStaker } from "src/WagyuStaker.sol";
import { MevEthShareVault } from "src/MevEthShareVault.sol";
import { IStakingModule } from "src/interfaces/IStakingModule.sol";

contract DeployScript is Script {
    error UnknownChain();

    //TODO: set this value to something realistic
    uint128 constant BASE_MEDIAN_MEV_PAYMENT = 0;
    uint128 constant BASE_MEDIAN_VALIDATOR_PAYMENT = 0;

    function run() public {
        address authority = tx.origin;
        uint256 chainId;
        address beaconDepositContract;
        address weth;

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
        MevEth mevEth = new MevEth(authority, weth);

        MevEthShareVault initialShareVault = new MevEthShareVault(authority, address(mevEth), authority, BASE_MEDIAN_MEV_PAYMENT, BASE_MEDIAN_VALIDATOR_PAYMENT);
        IStakingModule initialStakingModule = new WagyuStaker(authority, beaconDepositContract, address(mevEth));

        mevEth.init(address(initialShareVault), address(initialStakingModule));

        vm.stopBroadcast();
    }
}
