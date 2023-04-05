{inputs, ...}: {
  imports = [
    inputs.treefmt-nix.flakeModule
  ];
  perSystem = {
    config,
    pkgs,
    lib,
    inputs',
    ...
  }: {
    treefmt.config = {
      inherit (config.flake-root) projectRootFile;
      package = pkgs.treefmt;

      programs = {
        alejandra.enable = true; # nix
        prettier.enable = true; # json,html,markdown and so on
      };

      settings.formatter = let
        excludes = ["./lib/**"];
      in {
        alejandra.excludes = excludes;
        prettier.excludes = excludes;
      };
    };

    formatter = config.treefmt.build.wrapper;

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
