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

The `lib` directory contains git-submodules which in turn also have submodules.
To update all submodules recursively, execute:

```bash
git submodule update --init --recursive
```

### Docs

To build the docs locally, run `docs-build`. The output will be inside of `./result`.

Run `docs-serve` to serve the docs locally (after building them previously). You can edit the docs in `./docs`.

### Running tests

To run all tests, you can use `check` (alias for `nix flake check`); it will build all packages and run all tests.

You can use `tests -h` to execute a specific test, which will provide more information.

### Formatting

You can manually format the source using the `fmt` command.

## Design Doc

# MevEth - Maximizing Ethereum Value

The `MevEth` contract serves as a sophisticated platform for Liquid Staking Receipt (LSR) management, designed to optimize Ethereum value through efficient staking and reward distribution. This contract leverages multiple core modules to achieve its objectives, including admin control, staking management, share vault updates, ERC4626 integration, withdrawal queues and omni-chain tokens.

- [Documentation for MevEth](docs/index.md)

## Core Modules and Functionality

The `MevEth` contract comprises several core modules, each contributing to its comprehensive functionality:

- **Accounting**: Transparent fractional accounting system
- **Admin Control Panel**: Empowers administrators with control over staking, module updates, and share vault management.
- **Staking Management**: Allows efficient staking of Ether in the Beacon Chain, ensuring validators' registration and interaction with the staking module.
- **Share Vault Updates**: Facilitates seamless updates to the MevEth share vault, ensuring accurate reward distribution and protocol management.
- **Role management**: Supports roles management
- **ERC4626 Integration**: Supports ERC4626 interface for yield source integration, enabling compatibility with Yearn Vault and other protocols.
- **Withdrawal Queues**: First come, first served queues for withdrawal requests beyond buffer balances
- **Omni-chain fungible tokens**: Allows `MevEth` tokens to be sent accross chains
