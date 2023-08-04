{inputs, ...}: {
  perSystem = {
    lib,
    pkgs,
    inputs',
    ...
  }: let
    inherit (pkgs.stdenv) mkDerivation;
    inherit (inputs'.ethereum-nix.packages) foundry;
    inherit (inputs'.nixpkgs-unstable.legacyPackages) solc;
  in {
    config.packages.mevETH = mkDerivation {
      pname = "mevETH";
      version = "0.0.1";

      src = lib.cleanSource ../.;

      buildInputs = [
        solc
        foundry
      ];

      # force a hermetic build by disabling network access and specifying the version of solc brought in via nix
      FOUNDRY_OFFLINE = "true";
      FOUNDRY_SOLC_VERSION = "${lib.getExe solc}";

      # submodules will not get copied in so we rebuild the lib directory using `git+file` based inputs
      configurePhase = ''
        cp -r ${inputs.forge-std} lib/forge-std
        cp -r ${inputs.openzeppelin-contracts} lib/openzeppelin-contracts
        cp -r ${inputs.pigeon} lib/pigeon
        cp -r ${inputs.solmate} lib/solmate
      '';

      buildPhase = ''
        forge build
      '';

      checkPhase = ''
        forge test
      '';

      installPhase = ''
        mkdir $out
        mv out/* $out/
      '';
    };
  };
}
