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
    };
  };
}
