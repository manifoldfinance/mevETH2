# MevETHRateProvider
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/fb1b10e0f4766c0b96be04b99ddfd379368057c1/src/MevEthRateProvider.sol)

**Inherits:**
[IRateProvider](/gh-pages/src/src/interfaces/IRateProvider.sol/interface.IRateProvider.md)

SPDX-License-Identifier: SSPL-1.-0

Returns the value of mevETH in terms of ETH


## State Variables
### mevETH
The address of the mevETH contract


```solidity
IMevEth public immutable mevETH;
```


## Functions
### constructor

Constructs the MevETHRateProvider contract, setting the mevETH address


```solidity
constructor(IMevEth _mevETH);
```

### getRate

Returns the value of mevETH in terms of ETH


```solidity
function getRate() external view override returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the value of mevETH in terms of ETH|


