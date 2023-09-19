# Fee
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/216fe89b4b259aa768c698247b6facac9d08597e/src/layerZero/oft/Fee.sol)

**Inherits:**
[Auth](/src/libraries/Auth.sol/contract.Auth.md)


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


```solidity
function setFeeOwner(address _feeOwner) public virtual onlyAdmin;
```

### quoteOFTFee


```solidity
function quoteOFTFee(uint16 _dstChainId, uint256 _amount) public view virtual returns (uint256 fee);
```

### _payOFTFee


```solidity
function _payOFTFee(address _from, uint16 _dstChainId, uint256 _amount) internal virtual returns (uint256 amount, uint256 fee);
```

### _transferFrom


```solidity
function _transferFrom(address _from, address _to, uint256 _amount) internal virtual returns (uint256);
```

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

