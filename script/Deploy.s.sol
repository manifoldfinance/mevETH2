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

    /// @dev MULTISIG_SAFE env var must be set
    function run() public {
        address authority = tx.origin;
        uint256 chainId;
        address beaconDepositContract;
        address weth;
        address safe = vm.envAddress("MULTISIG_SAFE");
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
        } else if (chainId == 17_000) {
            beaconDepositContract = 0x4242424242424242424242424242424242424242;
            weth = 0x94373a4919B3240D86eA41593D5eBa789FEF3848;
        } else {
            revert UnknownChain();
        }

        vm.startBroadcast();
        // deploy mevETH
        MevEth mevEth = new MevEth(authority, weth);

        // deploy sharevault
        // MevEthShareVault initialShareVault = new MevEthShareVault(authority, address(mevEth), authority);
        address initialShareVault = safe;
        // deploy staking module
        IStakingModule initialStakingModule = new WagyuStaker(authority, beaconDepositContract, address(mevEth));
        // initialise mevETH
        mevEth.init(address(initialShareVault), address(initialStakingModule));

        // deploy AuthManager
        AuthManager authManager = new AuthManager(authority, address(mevEth), address(initialShareVault), address(initialStakingModule));
        // set AuthManager as admin
        IAuth(address(mevEth)).addAdmin(address(authManager));
        // initial share vault is a multisig. If upgraded, this will need to be done manually
        // IAuth(address(initialShareVault)).addAdmin(address(authManager));
        IAuth(address(initialStakingModule)).addAdmin(address(authManager));

        vm.stopBroadcast();
    }
}
