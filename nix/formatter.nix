{inputs, ...}: {
  imports = [
    inputs.treefmt-nix.flakeModule
  ];
  perSystem = {
    config,
    pkgs,
    inputs',
    ...
  }: let
    inherit (inputs'.ethereum-nix.packages) foundry;
  in {
    treefmt.config = {
      inherit (config.flake-root) projectRootFile;
      package = pkgs.treefmt;

      flakeFormatter = true;

      programs = {
        alejandra.enable = true; # nix
        deadnix.enable = true; # nix
        prettier.enable = true; # json,html,markdown and so on
        shfmt.enable = true;
      };

      settings.formatter = let
        excludes = ["./lib/**"];
      in {
        alejandra.excludes = excludes;
        prettier.excludes = excludes;
        solidity = {
          command = "sh";
          options = [
            "-eucx"
            "${foundry}/bin/forge fmt"
            "--"
          ];
          includes = ["*.sol"];
          inherit excludes;
        };
      };
    };

    devshells.default = {
      commands = [
        {
          category = "formatting";
          name = "fmt";
          help = "format the repo";
          command = "nix fmt";
        }
      ];
    };
  };
}
