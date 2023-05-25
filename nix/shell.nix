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

      packages = [
        pkgs.statix
        solc
        foundry
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
      ];
    };
  };
}
