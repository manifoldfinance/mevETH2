/**
 * 
 */

import type { HardhatUserConfig } from "hardhat/config";
import "hardhat-preprocessor";
import fs from "fs";
require("@nomiclabs/hardhat-waffle");
require(`@nomiclabs/hardhat-etherscan`);
require("solidity-coverage");
require('hardhat-gas-reporter');
require('hardhat-deploy');
require('hardhat-deploy-ethers');

function getRemappings() {
  return fs
    .readFileSync("remappings.txt", "utf8")
    .split("\n")
    .filter(Boolean) // remove empty lines
    .map((line) => line.trim().split("="));
}

const config: HardhatUserConfig = {
    defaultNetwork: "hardhat",
    namedAccounts: {
      deployer: {
        default: 0,    // wallet address 0, of the mnemonic in .env
      },
    },
    networks: {
      ethereum: {
        url: "https://mainnet.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161", // public infura endpoint
        chainId: 1,
        
      },
      bsc: {
        url: "https://bsc-dataseed1.binance.org",
        chainId: 56,
        
      },
      avalanche: {
        url: "https://api.avax.network/ext/bc/C/rpc",
        chainId: 43114,
        
      },
      polygon: {
        url: "https://rpc-mainnet.maticvigil.com",
        chainId: 137,
        
      },
      arbitrum: {
        url: `https://arb1.arbitrum.io/rpc`,
        chainId: 42161,
        
      },
      optimism: {
        url: `https://mainnet.optimism.io`,
        chainId: 10,
        
      },
      fantom: {
        url: `https://rpcapi.fantom.network`,
        chainId: 250,
        
      },
      metis: {
        url: `https://andromeda.metis.io/?owner=1088`,
        chainId: 1088,
        
      },
  
      goerli: {
        url: "https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161", // public infura endpoint
        chainId: 5,
        
      },
      'bsc-testnet': {
        url: 'https://data-seed-prebsc-1-s1.binance.org:8545/',
        chainId: 97,
        
      },
      fuji: {
        url: `https://api.avax-test.network/ext/bc/C/rpc`,
        chainId: 43113,
        
      },
      mumbai: {
        url: "https://rpc-mumbai.maticvigil.com/",
        chainId: 80001,
        
      },
      'arbitrum-goerli': {
        url: `https://goerli-rollup.arbitrum.io/rpc/`,
        chainId: 421613,
        
      },
      'optimism-goerli': {
        url: `https://goerli.optimism.io/`,
        chainId: 420,
        
      },
      'fantom-testnet': {
        url: `https://rpc.ankr.com/fantom_testnet`,
        chainId: 4002,
        
      }
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
    preprocess: {
      eachLine: (hre) => ({
        transform: (line: string) => {
          if (line.match(/^\s*import /i)) {
            for (const [from, to] of getRemappings()) {
              if (line.includes(from)) {
                line = line.replace(from, to);
                break;
              }
            }
          }
          return line;
        },
      }),
    },
    paths: {
      artifacts: "./artifacts",
      cache: "./cache_hardhat",
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
          runs: 1,
        },
      },
    },
    allowUnlimitedContractSize: true,
    typechain: {
      outDir: "types",
      target: "ethers-v6",
    },
  };
  
  export default config;
