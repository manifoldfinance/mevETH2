{
  description = "A smart contract for mevETH";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-root.url = "github:srid/flake-root";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ethereum-nix = {
      url = "github:nix-community/ethereum.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # forge manages libraries as git submodules inside of the lib directory

    forge-std = {
      url = "git+file:./lib/forge-std";
      flake = false;
    };

    solmate = {
      url = "git+file:./lib/solmate";
      flake = false;
    };

    solady = {
      url = "git+file:./lib/solady";
      flake = false;
    };

    openzeppelin-contracts = {
      url = "git+file:./lib/openzeppelin-contracts";
      flake = false;
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    (
      flake-parts.lib.evalFlakeModule
      {
        inherit inputs;
      }
      {
        imports = [
          ./nix
        ];
        systems = [
          "x86_64-linux"
          "x86_64-darwin"
          "aarch64-linux"
          "aarch64-darwin"
        ];
      }
    )
    .config
    .flake;
}
