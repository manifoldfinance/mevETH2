{inputs, ...}: {
  imports = [
    inputs.treefmt-nix.flakeModule
  ];
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    treefmt.config = {
      inherit (config.flake-root) projectRootFile;
      package = pkgs.treefmt;

      flakeFormatter = true;

      programs = {
        alejandra.enable = true; # nix
        deadnix.enable = true; # nix
        prettier.enable = true; # json,html,markdown and so on
      };

      settings.formatter = let
        excludes = ["./lib/**"];
      in {
        alejandra.excludes = excludes;
        prettier.excludes = excludes;
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
