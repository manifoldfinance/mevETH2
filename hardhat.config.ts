import "@nomicfoundation/hardhat-toolbox";
import { config as dotenvConfig } from "dotenv";
import "hardhat-deploy";
import type { HardhatUserConfig } from "hardhat/config";
import type { NetworkUserConfig } from "hardhat/types";
import { resolve } from "path";
("");
import "@primitivefi/hardhat-dodoc";

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  namedAccounts: {
    deployer: 0,
  },

  networks: {},
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
  },
  solidity: {
    version: "0.8.19",
    settings: {
      metadata: {
        bytecodeHash: "none",
      },
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 1_000,
        details: {
          yulDetails: {
            optimizerSteps: "u",
          },
          outputSelection: {
            "*": {
              "*": [
                "abi",
                "evm.bytecode",
                "evm.deployedBytecode",
                "evm.methodIdentifiers",
                "metadata",
              ],
              "": ["ast"],
            },
          },
        },
      },
      typechain: {
        outDir: "types",
        target: "ethers-v6",
      },
      dodoc: {
        runOnCompile: true,
        outputDir: "output-docs"
    },
  },
}
};
