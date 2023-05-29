## Getting started

To make the most of this repository, you should have the following installed:

- [Nix](https://nixos.org/)
- [Direnv](https://direnv.net/)

After cloning this repository and entering inside, run `direnv allow` when prompted, and you will be met with following prompt.

```terminal
🔨 Welcome to devshell

[build]

  check      - run all linters and build all packages

[deployments]

  deploy     - Deploy the Smart Contracts

[development]

  dev-net    - Run local Ethereum network for development

[docs]

  docs-build - build the docs and place them in result directory
  docs-serve - serve the docs

[formatting]

  fmt        - format the repo

[foundry]

  anvil      - A fast local Ethereum development node
  cast       - Perform Ethereum RPC calls from the comfort of your command line
  forge      - Build, test, fuzz, debug and deploy Solidity contracts

[general commands]

  menu       - prints this menu

[tests]

  tests      - Test the Smart Contracts

direnv: export +DEVSHELL_DIR +FOUNDRY_SOLC +IN_NIX_SHELL +NIXPKGS_PATH +PRJ_DATA_DIR +PRJ_ROOT +name ~PATH ~XDG_DATA_DIRS
```

### Docs

To build the docs locally, run `docs-build`. The output will be inside of `./result`.

Run `docs-serve` to serve the docs locally (after building them previously). You can edit the docs in `./docs`.

### Running tests

To run all tests, you can use `check` (alias for `nix flake check`); it will build all packages and run all tests.

You can use `tests -h` to execute a specific test, which will provide more information.

### Formatting

You can manually format the source using the `fmt` command.
