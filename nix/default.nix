{inputs, ...}: {
  imports = [
    inputs.flake-root.flakeModule
    ./checks.nix
    ./docs.nix
    ./formatter.nix
    ./packages.nix
    ./shell.nix
  ];
}
