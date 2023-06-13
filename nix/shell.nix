{
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.devshell.flakeModule
  ];

  config.perSystem = {
    inputs',
    pkgs,
    self',
    ...
  }: let
    inherit (inputs'.ethereum-nix.packages) foundry;
    # inherit (inputs'.nixpkgs-unstable.legacyPackages) solc;
  in {
    config.devshells.default = {
      env = [
        # we want foundry to use the version of solidity we have included
        {
          name = "FOUNDRY_SOLC";
          value = "${lib.getExe self'.packages.solc-0_8_20}";
        }
      ];

      packages = with pkgs; [
        age
        foundry
        self'.packages.solc-0_8_20
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
              --broadcast \
              --private-key $PRIVATE_KEY \
              --verify \
              -vvv
          '';
        }
        {
          category = "tests";
          name = "tests";
          help = "Test the Smart Contracts";
          command = ''forge test -vvvv'';
        }
      ];
    };
  };
}
