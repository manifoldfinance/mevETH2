{
  perSystem = {
    lib,
    pkgs,
    ...
  }: let
    inherit (pkgs) mkdocs python310Packages;

    my-mkdocs =
      pkgs.runCommand "my-mkdocs"
      {
        buildInputs = [
          mkdocs
          python310Packages.mkdocs-material
        ];
      } ''
        mkdir -p $out/bin

        cat <<MKDOCS > $out/bin/mkdocs
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        export PYTHONPATH=$PYTHONPATH
        exec ${mkdocs}/bin/mkdocs "\$@"
        MKDOCS

        chmod +x $out/bin/mkdocs
      '';
  in {
    packages.docs =
      pkgs.runCommand "homelab-docs"
      {
        passthru.serve = pkgs.writeShellScriptBin "serve" ''
          set -euo pipefail
          cd $PRJ_ROOT
          ${my-mkdocs}/bin/mkdocs serve
        '';
      }
      ''
        cp -r ${lib.cleanSource ../.}/* .
        ${my-mkdocs}/bin/mkdocs build -d "$out"
      '';

    devshells.default = {
      commands = [
        {
          category = "docs";
          name = "docs-serve";
          help = "serve the docs";
          command = "nix run .#docs.serve";
        }
        {
          category = "docs";
          name = "docs-build";
          help = "build the docs and place them in result directory";
          command = "nix build .#docs";
        }
      ];
    };
  };
}
