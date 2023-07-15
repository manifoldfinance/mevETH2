# MevETHRateProvider
[Git Source](https://github.com/manifoldfinance/mevETH/blob/744c86166044c40a1c176b100f17322ace7974b4/src/MevEthRateProvider.sol)

**Inherits:**
[IRateProvider](/docs-output/src/src/interfaces/IRateProvider.sol/interface.IRateProvider.md)

Returns the value of mevETH in terms of ETH


## State Variables
### mevETH

```solidity
IMevEth public immutable mevETH;
```


## Functions
### constructor


```solidity
constructor(IMevEth _mevETH);
```

### getRate


```solidity
function getRate() external view override returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the value of mevETH in terms of ETH|


