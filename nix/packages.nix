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
    config.packages = rec {
      solc-0_8_20 = solc.overrideAttrs (_finalAttrs: _previousAttrs: {
        version = "0.8.20";
        patches = []; # Emptied, otherwise having issues
        src = pkgs.fetchzip {
          url = "https://github.com/ethereum/solidity/releases/download/v0.8.20/solidity_0.8.20.tar.gz";
          sha256 = "sha256-DPFucRJc3PpgRvaQyrxNnIgVFe97Bt39GC09tKoLNhg=";
        };
      });

      mevETH = mkDerivation {
        pname = "mevETH";
        version = "0.0.1";

        src = lib.cleanSource ../.;

        buildInputs = [
          solc-0_8_20
          foundry
        ];

        # force a hermetic build by disabling network access and specifying the version of solc brought in via nix
        FOUNDRY_OFFLINE = "true";
        FOUNDRY_SOLC_VERSION = "${lib.getExe solc-0_8_20}";

        # submodules will not get copied in so we rebuild the lib directory using `git+file` based inputs
        configurePhase = ''
          cp -r ${inputs.forge-std} lib/forge-std
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
  };
}
