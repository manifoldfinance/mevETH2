// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import { OFTV2 } from "src/layerZero/oft/OFTV2.sol";

contract DeployOFTScript is Script {
    error UnknownChain();
    /// @dev https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids

    function run() public {
        address authority = tx.origin;
        uint256 chainId;
        address layerZeroEndpoint;
        assembly {
            chainId := chainid()
        }
        if (chainId == 56) {
            // BSC
            layerZeroEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
        } else if (chainId == 42_161) {
            // Arbitrum
            layerZeroEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
        } else if (chainId == 137) {
            // Polygon
            layerZeroEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
        } else if (chainId == 10) {
            // Optimism
            layerZeroEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
        } else if (chainId == 43_114) {
            // Avalanche
            layerZeroEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
        } else if (chainId == 1101) {
            // Polygon zkEVM
            layerZeroEndpoint = 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4;
        } else if (chainId == 324) {
            // zkSync Era
            layerZeroEndpoint = 0x9b896c0e23220469C7AE69cb4BbAE391eAa4C8da;
        } else if (chainId == 97) {
            // BSC testnet
            layerZeroEndpoint = 0x6Fcb97553D41516Cb228ac03FdC8B9a0a9df04A1;
        } else if (chainId == 421_613) {
            // Arbitrum Goerli testnet
            layerZeroEndpoint = 0x6aB5Ae6822647046626e83ee6dB8187151E1d5ab;
        } else if (chainId == 80_001) {
            // Polygon testnet
            layerZeroEndpoint = 0xf69186dfBa60DdB133E91E9A4B5673624293d8F8;
        } else if (chainId == 420) {
            // Optimism Goerli testnet
            layerZeroEndpoint = 0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1;
        } else if (chainId == 43_113) {
            // Avalanche testnet
            layerZeroEndpoint = 0x93f54D755A063cE7bB9e6Ac47Eccc8e33411d706;
        } else if (chainId == 1442) {
            // Polygon zkEVM testnet
            layerZeroEndpoint = 0x6aB5Ae6822647046626e83ee6dB8187151E1d5ab;
        } else if (chainId == 280) {
            // zkSync Era testnet
            layerZeroEndpoint = 0x093D2CF57f764f09C3c2Ac58a42A2601B8C79281;
        } else {
            revert UnknownChain();
        }
        vm.startBroadcast();
        new OFTV2("Mev Liquid Staked Ether", "mevETH", 18, 8, authority, layerZeroEndpoint);
        vm.stopBroadcast();
    }
}
