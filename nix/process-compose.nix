{inputs, ...}: {
  imports = [
    inputs.process-compose-flake.flakeModule
  ];
  
  perSystem = {config, self', inputs', ...}: let
    inherit (inputs'.ethereum-nix.packages) foundry;
  in {
    config.process-compose.configs = {
      dev-net.processes = {
        anvil.command = ''
          ${foundry}/bin/anvil \
            --block-time 12 \
            --accounts 10 \
            --balance 10000
        '';
      };
    };

    config.devshells.default = {
      commands = let
        category = "development";
      in [
        {
          inherit category;
          help = "Run local Ethereum network for development";
          package = self'.packages.dev-net;
        }
      ];
    };
  };
}
