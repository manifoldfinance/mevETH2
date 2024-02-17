// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import { MevEth } from "src/MevEth.sol";
import { IAuth } from "src/interfaces/IAuth.sol";
import { WagyuStaker } from "src/WagyuStaker.sol";
import { AuthManager } from "src/libraries/AuthManager.sol";
import { MevEthShareVault } from "src/MevEthShareVault.sol";
import { IStakingModule } from "src/interfaces/IStakingModule.sol";
import { IBeaconDepositContract } from "src/interfaces/IBeaconDepositContract.sol";

interface IMevEthVal {
    function createValidator(IStakingModule.ValidatorData calldata newData, bytes32 latestDepositRoot) external;
}

contract CreateValidatorScript is Script {
    using stdJson for string;

    IMevEthVal meveth = IMevEthVal(0x277058D78307F11e590D91eDfF3D4b1C0fAA240c);

    error UnknownChain();

    function run() public {
        uint256 chainId;
        address beaconDepositContract;
        // address weth;
        assembly {
            chainId := chainid()
        }
        if (chainId == 1) {
            // Eth mainnet
            beaconDepositContract = 0x00000000219ab540356cBB839Cbe05303d7705Fa;
            // weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        } else if (chainId == 5) {
            // Goerli
            beaconDepositContract = 0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b;
            // weth = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
        } else if (chainId == 17_000) {
            beaconDepositContract = 0x4242424242424242424242424242424242424242;
            // weth = 0x94373a4919B3240D86eA41593D5eBa789FEF3848;
        } else {
            revert UnknownChain();
        }

        // decode and process data
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/data/validators.json");
        string memory json = vm.readFile(path);

        bytes memory pubkeys = json.parseRaw("[*].pubkey");
        bytes memory withdrawal_credentials = json.parseRaw("[*].withdrawal_credentials");
        bytes memory signatures = json.parseRaw("[*].signature");
        bytes memory deposit_data_roots = json.parseRaw("[*].deposit_data_root");
        string[] memory keys = abi.decode(pubkeys, (string[]));
        string[] memory withdrawals = abi.decode(withdrawal_credentials, (string[]));
        string[] memory sigs = abi.decode(signatures, (string[]));
        string[] memory deps = abi.decode(deposit_data_roots, (string[]));

        vm.startBroadcast();
        for (uint256 i = 0; i < keys.length; i++) {
            bytes32 rooty = IBeaconDepositContract(beaconDepositContract).get_deposit_root();
            bytes memory bkey = hexStringToBytes(keys[i]);
            bytes32 withdrawal = bytes32(hexStringToBytes(withdrawals[i]));
            bytes memory sig = hexStringToBytes(sigs[i]);
            bytes32 dep = bytes32(hexStringToBytes(deps[i]));
            IStakingModule.ValidatorData memory data =
                IStakingModule.ValidatorData({ operator: msg.sender, pubkey: bkey, withdrawal_credentials: withdrawal, signature: sig, deposit_data_root: dep });
            meveth.createValidator(data, rooty);
        }

        vm.stopBroadcast();
    }

    function hexStringToBytes(string memory _hexString) public pure returns (bytes memory) {
        bytes memory bytesData = bytes(_hexString);
        require(bytesData.length % 2 == 0, "Hex string length must be even");

        bytes memory result = new bytes(bytesData.length / 2);
        uint8 n;
        for (uint256 i = 0; i < bytesData.length; i += 2) {
            n = uint8(parseChar(bytesData[i])) * 16 + uint8(parseChar(bytesData[i + 1]));
            result[i / 2] = bytes1(n);
        }

        return result;
    }

    function parseChar(bytes1 _char) internal pure returns (uint8) {
        uint8 uintChar = uint8(_char);
        if (uintChar >= 48 && uintChar <= 57) {
            return uintChar - 48;
        } else if (uintChar >= 65 && uintChar <= 70) {
            return uintChar - 55;
        } else if (uintChar >= 97 && uintChar <= 102) {
            return uintChar - 87;
        } else {
            revert("Invalid hex character");
        }
    }
}
