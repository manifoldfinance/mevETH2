// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import { MevEth } from "src/MevEth.sol";
import { IAuth } from "src/interfaces/IAuth.sol";
import { WagyuStaker } from "src/WagyuStaker.sol";
import { AuthManager } from "src/libraries/AuthManager.sol";
import { MevEthShareVault } from "src/MevEthShareVault.sol";
import { IStakingModule } from "src/interfaces/IStakingModule.sol";

contract DeployScript is Script {
    error UnknownChain();

    function run() public {
        // TODO: set authority before deployment. If left as is, deployer is initial authority
        address authority = tx.origin;
        uint256 chainId;
        address beaconDepositContract;
        address weth;
        address layerZeroEndpoint;
        assembly {
            chainId := chainid()
        }
        if (chainId == 1) {
            // Eth mainnet
            beaconDepositContract = 0x00000000219ab540356cBB839Cbe05303d7705Fa;
            weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
            layerZeroEndpoint = 0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675;
        } else if (chainId == 5) {
            // Goerli
            beaconDepositContract = 0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b;
            weth = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
            layerZeroEndpoint = 0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23;
        } else {
            revert UnknownChain();
        }

        vm.startBroadcast();
        MevEth mevEth = new MevEth(authority, weth, layerZeroEndpoint);

        MevEthShareVault initialShareVault = new MevEthShareVault(authority, address(mevEth), authority, authority);
        IStakingModule initialStakingModule = new WagyuStaker(authority, beaconDepositContract, address(mevEth));

        AuthManager authManager = new AuthManager(authority, address(mevEth), address(initialShareVault), address(initialStakingModule));

        mevEth.init(address(initialShareVault), address(initialStakingModule));

        // authority needs to call these
        // IAuth(address(mevEth)).addAdmin(address(authManager));
        // IAuth(address(initialShareVault)).addAdmin(address(authManager));
        // IAuth(address(initialStakingModule)).addAdmin(address(authManager));

        vm.stopBroadcast();
    }
}
