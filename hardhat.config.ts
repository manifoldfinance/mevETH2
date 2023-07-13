/**
 * 
 */

import "@nomicfoundation/hardhat-toolbox";
import { config as dotenvConfig } from "dotenv";
import "hardhat-deploy";
import type { HardhatUserConfig } from "hardhat/config";
import type { NetworkUserConfig } from "hardhat/types";
import { resolve } from "path";

const config: HardhatUserConfig = {
    defaultNetwork: "hardhat",
    namedAccounts: {
      deployer: 0,
    },
    /*  networks: {
      hardhat: {
        accounts: {
          mnemonic,
        },
        chainId: chainIds.hardhat,
      },
      ganache: {
        accounts: {
          mnemonic,
        },
        chainId: chainIds.ganache,
        url: "http://localhost:8545",
      },
      mainnet: getChainConfig("mainnet"),
      sepolia: getChainConfig("sepolia"),
    }, */
    paths: {
      artifacts: "./artifacts",
      cache: "./cache",
      sources: "./src",
      tests: "./test",
    },
    solidity: {
      version: "0.8.19",
      settings: {
        metadata: {
          // Not including the metadata hash
          // https://github.com/paulrberg/hardhat-template/issues/31
          bytecodeHash: "none",
        },
        // Disable the optimizer when debugging
        // https://hardhat.org/hardhat-network/#solidity-optimizer-support
        optimizer: {
          enabled: true,
          runs: 800,
        },
      },
    },
    typechain: {
      outDir: "types",
      target: "ethers-v6",
    },
  };
  
  export default config;
