# Fee
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/fb1b10e0f4766c0b96be04b99ddfd379368057c1/src/layerZero/oft/Fee.sol)

**Inherits:**
[Auth](/gh-pages/src/src/libraries/Auth.sol/contract.Auth.md)

SPDX-License-Identifier: SSPL-1.-0


## State Variables
### BP_DENOMINATOR

```solidity
uint256 public constant BP_DENOMINATOR = 10_000;
```


### chainIdToFeeBps

```solidity
mapping(uint16 => FeeConfig) public chainIdToFeeBps;
```


### defaultFeeBp

```solidity
uint16 public defaultFeeBp;
```


### feeOwner

```solidity
address public feeOwner;
```


## Functions
### constructor


```solidity
constructor(address authority);
```

### setDefaultFeeBp


```solidity
function setDefaultFeeBp(uint16 _feeBp) public virtual onlyAdmin;
```

### setFeeBp


```solidity
function setFeeBp(uint16 _dstChainId, bool _enabled, uint16 _feeBp) public virtual onlyAdmin;
```

### setFeeOwner

Sets the fee owner address

*This function sets the fee owner address to the address passed in as an argument. If the address passed in is 0x0, the function will revert with the
FeeOwnerNotSet error.*


```solidity
function setFeeOwner(address _feeOwner) public virtual onlyAdmin;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_feeOwner`|`address`|The address to set as the fee owner|


### quoteOFTFee


```solidity
function quoteOFTFee(uint16 _dstChainId, uint256 _amount) public view virtual returns (uint256 fee);
```

### _payOFTFee


```solidity
function _payOFTFee(address _from, uint16 _dstChainId, uint256 _amount) internal virtual returns (uint256 amount, uint256 fee);
```

### _transferFrom

This function is used to transfer tokens from one address to another.

*This function is called by the transferFrom() function. It is used to transfer tokens from one address to another.*


```solidity
function _transferFrom(address _from, address _to, uint256 _amount) internal virtual returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_from`|`address`|The address from which the tokens are being transferred.|
|`_to`|`address`|The address to which the tokens are being transferred.|
|`_amount`|`uint256`|The amount of tokens being transferred.|


## Events
### SetFeeBp

```solidity
event SetFeeBp(uint16 dstchainId, bool enabled, uint16 feeBp);
```

### SetDefaultFeeBp

```solidity
event SetDefaultFeeBp(uint16 feeBp);
```

### SetFeeOwner

```solidity
event SetFeeOwner(address feeOwner);
```

## Errors
### FeeBpTooLarge

```solidity
error FeeBpTooLarge();
```

### FeeOwnerNotSet

```solidity
error FeeOwnerNotSet();
```

## Structs
### FeeConfig

```solidity
struct FeeConfig {
    uint16 feeBP;
    bool enabled;
}
```

