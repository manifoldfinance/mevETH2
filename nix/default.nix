{inputs, ...}: {
  imports = [
    inputs.flake-root.flakeModule
    ./checks.nix
    ./formatter.nix
    ./packages.nix
    ./process-compose.nix
    ./shell.nix
  ];
}
