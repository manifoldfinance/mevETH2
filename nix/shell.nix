{
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.devshell.flakeModule
  ];

  config.perSystem = {
    pkgs,
    inputs',
    ...
  }: let
    inherit (inputs'.ethereum-nix.packages) foundry;
    inherit (inputs'.nixpkgs-unstable.legacyPackages) solc;
  in {
    config.devshells.default = {
      env = [
        # we want foundry to use the version of solidity we have included
        {
          name = "FOUNDRY_SOLC";
          value = "${lib.getExe solc}";
        }
      ];

      packages = with pkgs; [
        age
        foundry
        solc
        sops
        ssh-to-age
        statix
      ];

      commands = let
        category = "foundry";
        package = foundry;
      in [
        {
          inherit category package;
          name = "anvil";
          help = "A fast local Ethereum development node";
        }
        {
          inherit category package;
          name = "cast";
          help = "Perform Ethereum RPC calls from the comfort of your command line";
        }
        {
          inherit category package;
          name = "forge";
          help = "Build, test, fuzz, debug and deploy Solidity contracts";
        }
        {
          category = "deployments";
          name = "deploy";
          help = "Deploy the Smart Contracts";
          command = ''
            forge script $PRJ_ROOT/script/Deploy.s.sol:DeployScript \
              --chain-id 1 \
              --rpc-url $RPC_MAINNET \
              --broadcast \
              --private-key $PRIVATE_KEY \
              --verify \
              --etherscan-api-key $ETHERSCAN_API_KEY \
              -vvvvv
          '';
        }
        {
          category = "deployments";
          name = "deploy-goerli";
          help = "Deploy the Smart Contracts to goerli";
          command = ''
            forge script $PRJ_ROOT/script/Deploy.s.sol:DeployScript \
              --chain-id 5 \
              --broadcast \
              --private-key $PRIVATE_KEY \
              --verify \
              -vvvvv \
              --rpc-url $RPC_GOERLI $@
          '';
        }
        {
          category = "deployments";
          name = "deploy-arbitrum";
          help = "Deploy the mevETH OFT on Arbitrum";
          command = ''
            forge script $PRJ_ROOT/script/DeployOFT.s.sol:DeployOFTScript \
              --chain-id 42161 \
              --rpc-url $ARBITRUM_MAINNET_RPC_URL \
              --broadcast \
              --private-key $PRIVATE_KEY \
              --verify \
              --etherscan-api-key $ARBISCAN_API_KEY \
              -vvvvv
          '';
        }
        {
          category = "deployments";
          name = "deploy-optimism";
          help = "Deploy the mevETH OFT on Optimism";
          command = ''
            forge script $PRJ_ROOT/script/DeployOFT.s.sol:DeployOFTScript \
              --chain-id 42161 \
              --rpc-url $OPTIMISM_RPC_URL \
              --broadcast \
              --private-key $PRIVATE_KEY \
              --verify \
              --etherscan-api-key $ETHERSCAN_API_KEY \
              -vvvvv
          '';
        }
        {
          category = "deployments";
          name = "deploy-avalanche";
          help = "Deploy the mevETH OFT on Avalanche";
          command = ''
            forge script $PRJ_ROOT/script/DeployOFT.s.sol:DeployOFTScript \
              --chain-id 43114 \
              --rpc-url $AVALANCHE_RPC_URL \
              --broadcast \
              --private-key $PRIVATE_KEY \
              --verify \
              --etherscan-api-key $SNOWSCAN_API_KEY \
              -vvvvv
          '';
        }
        {
          category = "deployments";
          name = "deploy-avalanche-testnet";
          help = "Deploy the mevETH OFT on Avalanche testnet";
          command = ''
            forge script $PRJ_ROOT/script/DeployOFT.s.sol:DeployOFTScript \
              --chain-id 43113 \
              --rpc-url $AVALANCHE_TESTNET_RPC_URL \
              --broadcast \
              --private-key $PRIVATE_KEY \
              --verify \
              --etherscan-api-key $SNOWSCAN_API_KEY \
              -vvvvv
          '';
        }
        {
          category = "deployments";
          name = "deploy-bsc";
          help = "Deploy the mevETH OFT on BSC";
          command = ''
            forge script $PRJ_ROOT/script/DeployOFT.s.sol:DeployOFTScript \
              --chain-id 56 \
              --rpc-url $BSC_MAINNET_RPC_URL \
              --broadcast \
              --private-key $PRIVATE_KEY \
              --verify \
              --etherscan-api-key $BSCSCAN_API_KEY \
              -vvvvv
          '';
        }
        {
          category = "deployments";
          name = "deploy-bsc-testnet";
          help = "Deploy the mevETH OFT on BSC testnet";
          command = ''
            forge script $PRJ_ROOT/script/DeployOFT.s.sol:DeployOFTScript \
              --chain-id 97 \
              --rpc-url $BSC_TESTNET_RPC_URL \
              --broadcast \
              --private-key $PRIVATE_KEY \
              --verify \
              --etherscan-api-key $BSCSCAN_API_KEY \
              -vvvvv
          '';
        }
        {
          category = "deployments";
          name = "deploy-polygon";
          help = "Deploy the mevETH OFT on Polygon";
          command = ''
            forge script $PRJ_ROOT/script/DeployOFT.s.sol:DeployOFTScript \
              --chain-id 137 \
              --rpc-url $POLYGON_MAINNET_RPC_URL \
              --broadcast \
              --private-key $PRIVATE_KEY \
              --verify \
              --etherscan-api-key $POLYGONSCAN_API_KEY \
              -vvvvv
          '';
        }
        {
          category = "deployments";
          name = "deploy-polygon-testnet";
          help = "Deploy the mevETH OFT on Polygon testnet";
          command = ''
            forge script $PRJ_ROOT/script/DeployOFT.s.sol:DeployOFTScript \
              --legacy \
              --chain-id 80001 \
              --rpc-url $POLYGON_TESTNET_RPC_URL \
              --broadcast \
              --private-key $PRIVATE_KEY \
              --verify \
              --etherscan-api-key $POLYGONSCAN_API_KEY \
              -vvvvv
          '';
        }
        {
          category = "deployments";
          name = "deploy-test";
          help = "Deploy the Smart Contracts Test";
          command = ''
            forge script $PRJ_ROOT/script/Deploy.s.sol:DeployScript \
              --chain-id 1 \
              --private-key $PRIVATE_KEY \
              --fork-url $RPC_MAINNET \
              -vvvvv
          '';
        }
        {
          category = "deployments";
          name = "deploy-polygon-test";
          help = "Deploy the mevETH OFT Polygon Test";
          command = ''
            forge script $PRJ_ROOT/script/DeployOFT.s.sol:DeployOFTScript \
              --chain-id 137 \
              --fork-url $POLYGON_MAINNET_RPC_URL \
              -vvvvv
          '';
        }
        {
          category = "deployments";
          name = "deploy-arbitrum-test";
          help = "Deploy the mevETH OFT Arbitrum Test";
          command = ''
            forge script $PRJ_ROOT/script/DeployOFT.s.sol:DeployOFTScript \
              --chain-id 42161 \
              --fork-url $ARBITRUM_MAINNET_RPC_URL \
              -vvvvv
          '';
        }
        {
          category = "deployments";
          name = "deploy-bsc-test";
          help = "Deploy the mevETH OFT BSC Test";
          command = ''
            forge script $PRJ_ROOT/script/DeployOFT.s.sol:DeployOFTScript \
              --chain-id 56 \
              --fork-url $BSC_MAINNET_RPC_URL \
              -vvvvv
          '';
        }
        {
          category = "deployments";
          name = "deploy-avalanche-test";
          help = "Deploy the mevETH OFT Avalanche Test";
          command = ''
            forge script $PRJ_ROOT/script/DeployOFT.s.sol:DeployOFTScript \
              --chain-id 43114 \
              --fork-url $AVALANCHE_RPC_URL \
              -vvvvv
          '';
        }
        {
          category = "deployments";
          name = "deploy-optimism-test";
          help = "Deploy the mevETH OFT Optimism Test";
          command = ''
            forge script $PRJ_ROOT/script/DeployOFT.s.sol:DeployOFTScript \
              --chain-id 42161 \
              --fork-url $OPTIMISM_RPC_URL \
              -vvvvv
          '';
        }
        {
          category = "tests";
          name = "tests";
          help = "Test the Smart Contracts";
          command = ''forge test -vvv'';
        }
      ];
    };
  };
}
