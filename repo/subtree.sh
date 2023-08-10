#!/bin/bash

# git subtree add --prefix=git-subtree --squash \
git subtree add --prefix=vendor/forge-std --squash https://github.com/foundry-rs/forge-std master
git subtree add --prefix=vendor/solmate --squash https://github.com/transmissions11/solmate main
git subtree add --prefix=vendor/pigeon --squash https://github.com/manifoldfinance/pigeon master
git subtree add --prefix=vendor/manifold-oft --squash https://github.com/manifoldfinance/manifold-oft main
git subtree add --prefix=vendor/safe-tools --squash https://github.com/0xKitsune/safe-tools main
git subtree add --prefix=vendor/openzeppelin-contracts --squash https://github.com/OpenZeppelin/openzeppelin-contracts master
git subtree add --prefix=vendor/solady --squash https://github.com/Vectorized/solady main
git subtree add --prefix=lib/ds-test https://github.com/dapphub/ds-test HEAD
