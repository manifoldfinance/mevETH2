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

    /// @dev PRIVATE_KEY and SENDER env vars must be set to initial mevETH admin
    function run() public {
        address authority = tx.origin;
        uint256 chainId;
        address beaconDepositContract;
        address weth;
        address layerZeroEndpoint;
        address creamToken;
        uint8 creamRedeem = 106;
        assembly {
            chainId := chainid()
        }
        if (chainId == 1) {
            // Eth mainnet
            beaconDepositContract = 0x00000000219ab540356cBB839Cbe05303d7705Fa;
            weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
            layerZeroEndpoint = 0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675;
            creamToken = 0x49D72e3973900A195A155a46441F0C08179FdB64;
        } else if (chainId == 5) {
            // Goerli
            beaconDepositContract = 0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b;
            weth = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
            layerZeroEndpoint = 0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23;
            // no creth2 on Goerli, using stEth for tests
            creamToken = 0x39028aaFaae59C3c5d8848fc3Ccc4e4CfD1f124C;
        } else {
            revert UnknownChain();
        }

        vm.startBroadcast();
        // deploy mevETH
        MevEth mevEth = new MevEth(authority, weth, layerZeroEndpoint, creamToken, creamRedeem);

        // deploy sharevault
        // TODO: Is the initial share vault a multisig? If so will need to comment this out and sub in multisig address
        MevEthShareVault initialShareVault = new MevEthShareVault(authority, address(mevEth), authority);
        // deploy staking module
        IStakingModule initialStakingModule = new WagyuStaker(authority, beaconDepositContract, address(mevEth));
        // initialise mevETH
        mevEth.init(address(initialShareVault), address(initialStakingModule));

        // deploy AuthManager
        AuthManager authManager = new AuthManager(authority, address(mevEth), address(initialShareVault), address(initialStakingModule));
        // set AuthManager as admin
        IAuth(address(mevEth)).addAdmin(address(authManager));
        IAuth(address(initialShareVault)).addAdmin(address(authManager));
        IAuth(address(initialStakingModule)).addAdmin(address(authManager));

        vm.stopBroadcast();
    }
}
