# ITinyMevEth
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/fb1b10e0f4766c0b96be04b99ddfd379368057c1/src/interfaces/ITinyMevEth.sol)

SPDX-License-Identifier: SSPL-1.-0

smol interface for interacting with MevEth


## Functions
### grantRewards

This function is payable and should be called with the amount of rewards to be granted.

*Function to grant rewards to other users.*


```solidity
function grantRewards() external payable;
```

### grantValidatorWithdraw

This function must be called with a validator address and a payable amount.

*Function to allow a validator to withdraw funds from the contract.*


```solidity
function grantValidatorWithdraw() external payable;
```

