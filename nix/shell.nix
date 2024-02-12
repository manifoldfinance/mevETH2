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
          name = "deploy-auth-manager";
          help = "Deploy the AuthManager";
          command = ''
            forge script $PRJ_ROOT/script/AuthManager.s.sol:AuthManagerDeployScript \
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
          name = "deploy-auth-manager-test";
          help = "Deploy the AuthManager test";
          command = ''
            forge script $PRJ_ROOT/script/AuthManager.s.sol:AuthManagerDeployScript \
              --chain-id 1 \
              --fork-url $RPC_MAINNET \
              -vvvvv
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
          category = "admin";
          name = "init";
          help = "Initialise mevETH with the share vault and staking module addresses";
          command = ''
            cast send \
              --rpc-url $RPC_MAINNET \
              --private-key $PRIVATE_KEY \
              $MEV_ETH_ADDRESS \
              "init(address,address)" \
              $SHARE_VAULT_ADDRESS $STAKER_ADDRESS
          '';
        }
        {
          category = "admin";
          name = "PauseStaking";
          help = "Pause Staking";
          command = ''
            cast send \
              --rpc-url $RPC_MAINNET \
              --private-key $PRIVATE_KEY \
              $MEV_ETH_ADDRESS \
              "pauseStaking()"
          '';
        }
        {
          category = "admin";
          name = "UnpauseStaking";
          help = "Unpause Staking";
          command = ''
            cast send \
              --rpc-url $RPC_MAINNET \
              --private-key $PRIVATE_KEY \
              $MEV_ETH_ADDRESS \
              "unpauseStaking()"
          '';
        }
        {
          category = "operator";
          name = "CreateValidator";
          help = "Create a Validator";
          command = ''
            cast send \
              --rpc-url $RPC_MAINNET \
              --private-key $PRIVATE_KEY \
              $MEV_ETH_ADDRESS \
              "createValidator((address,bytes,bytes32,bytes,bytes32),bytes32)" \
              "($OPERATOR,$PUBLIC_KEY,$WITHDRAW_CREDS,$SIGNATURE,$DEPOSIT_DATA_ROOT)" $LAST_DEPOSIT_ROOT
          '';
        }
        {
          category = "operator";
          name = "ProcessQueue";
          help = "Process withdraw queue";
          command = ''
            cast send \
              --rpc-url $RPC_MAINNET \
              --private-key $PRIVATE_KEY \
              $MEV_ETH_ADDRESS \
              "processWithdrawalQueue(uint256)" \
              $WITHDRAW_QUEUE_LENGTH
          '';
        }
        {
          category = "operator";
          name = "PayStakerValidatorWithdraw";
          help = "Pay MevEth contract for validator withdraw from Wagyu staker";
          command = ''
            cast send \
              --rpc-url $RPC_MAINNET \
              --private-key $PRIVATE_KEY \
              $STAKER_ADDRESS \
              "payValidatorWithdraw()"
          '';
        }
        {
          category = "operator";
          name = "PayStakerRewards";
          help = "Pay MevEth contract rewards from Wagyu staker";
          command = ''
            cast send \
              --rpc-url $RPC_MAINNET \
              --private-key $PRIVATE_KEY \
              $STAKER_ADDRESS \
              "payRewards(uint256)" \
              $REWARDS
          '';
        }
        {
          category = "operator";
          name = "PayShareVaultValidatorWithdraw";
          help = "Pay MevEth contract for validator withdraw from Share Vault";
          command = ''
            cast send \
              --rpc-url $RPC_MAINNET \
              --private-key $PRIVATE_KEY \
              $SHARE_VAULT_ADDRESS \
              "payValidatorWithdraw()"
          '';
        }
        {
          category = "operator";
          name = "PayShareVaultRewards";
          help = "Pay MevEth contract rewards from Share Vault";
          command = ''
            cast send \
              --rpc-url $RPC_MAINNET \
              --private-key $PRIVATE_KEY \
              $SHARE_VAULT_ADDRESS \
              "payRewards(uint256)" \
              $REWARDS
          '';
        }
        {
          category = "multisig";
          name = "GenerateDataPayRewards";
          help = "Generate data for payRewards";
          command = ''
            cast calldata "grantRewards()"
          '';
        }
        {
          category = "multisig";
          name = "MultisigPayRewards";
          help = "Multisig pay MevEth contract rewards";
          command = ''
            cast send \
              --rpc-url $PRIVATE_TX_URL \
              --private-key $PRIVATE_KEY \
              $MULTISIG_ADDRESS \
              "execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)" \
              $MEV_ETH_ADDRESS $REWARDS $CALLDATA 0 0 0 0 0x0000000000000000000000000000000000000000 0x0000000000000000000000000000000000000000 \
              $SIGNATURES
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
