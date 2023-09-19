# MevETHRateProvider
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/216fe89b4b259aa768c698247b6facac9d08597e/src/MevEthRateProvider.sol)

**Inherits:**
[IRateProvider](/src/interfaces/IRateProvider.sol/interface.IRateProvider.md)

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


