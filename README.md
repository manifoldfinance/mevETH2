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

## Design Doc

# 🚧 mev-eth 🚧

**Under construction**

mev-eth is a leading Liquid 🥩 Staking 🥩 Reciept

## Design Doc

mev-eth is has a couple core modules and functionality.

### Ownership

First, because mev-eth is a centralized LSR, and dependent on Manifold Finance to actuall stake the Ether, ownership is given, with a couple key roles. An address can be designed as an operator, operators are intended to be automated, keeper style addresses which can redirect Ether to beacon chain validators. Operators are also expected to post oracle updates from the Beacon chain to update the contract on any rewards accrued. Additionally, there is the ManifoldOwner role, which gives the rights to control key management functions such as withdrawing fees, and setting various configuration variables such as cache balance threshold, where Ether will be held to buffer withdrawls.

### Token Design

mev-eth supports the ERC4626 interface to handle itself as an LSR. This allows many key integrations, such as Yearn Vault integrations, or any other protocols which require a yield source. This also means that mev-eth supports ERC20 as a base transferable token. Breaking from ERC4626, mev-eth also supports deposits via its fallback (recieve technically) function for call-data free deposits.

The token keeps track of this by accounting with simple Rebase math, which while a bit confusing, is the most simplistic approach, where each mev-eth token is a share which accumulates interest, and as interest grows will eventually be worth greater than it 1 eth per.

### Beacon Chain Support
