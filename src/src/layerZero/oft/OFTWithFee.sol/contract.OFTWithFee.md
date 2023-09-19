# OFTWithFee
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/216fe89b4b259aa768c698247b6facac9d08597e/src/layerZero/oft/OFTWithFee.sol)

**Inherits:**
[BaseOFTWithFee](/src/layerZero/oft/BaseOFTWithFee.sol/abstract.BaseOFTWithFee.md), ERC20


## State Variables
### ld2sdRate

```solidity
uint256 internal immutable ld2sdRate;
```


## Functions
### constructor


```solidity
constructor(
  string memory _name,
  string memory _symbol,
  uint8 decimals,
  uint8 _sharedDecimals,
  address authority,
  address _lzEndpoint
)
  ERC20(_name, _symbol, decimals)
  BaseOFTWithFee(_sharedDecimals, authority, _lzEndpoint);
```

### circulatingSupply

public functions


```solidity
function circulatingSupply() public view virtual override returns (uint256);
```

### token


```solidity
function token() public view virtual override returns (address);
```

### _debitFrom

internal functions


```solidity
function _debitFrom(address _from, uint16, bytes32, uint256 _amount) internal virtual override returns (uint256);
```

### _creditTo


```solidity
function _creditTo(uint16, address _toAddress, uint256 _amount) internal virtual override returns (uint256);
```

### _transferFrom


```solidity
function _transferFrom(address _from, address _to, uint256 _amount) internal virtual override returns (uint256);
```

### _ld2sdRate


```solidity
function _ld2sdRate() internal view virtual override returns (uint256);
```

### _spendAllowance

OpenZeppelin ERC20 extensions

*Updates `owner` s allowance for `spender` based on spent `amount`.
Does not update the allowance amount in case of infinite allowance.
Revert if not enough allowance is available.*


```solidity
function _spendAllowance(address owner, address spender, uint256 amount) internal virtual;
```

### _transfer

*Moves `amount` of tokens from `from` to `to`.
This internal function is equivalent to {transfer}, and can be used to
e.g. implement automatic token fees, slashing mechanisms, etc.*


```solidity
function _transfer(address from, address to, uint256 amount) internal;
```

## Errors
### InsufficientAllowance

```solidity
error InsufficientAllowance();
```

### InsufficientBalance

```solidity
error InsufficientBalance();
```

### SharedDecimalsTooLarge

```solidity
error SharedDecimalsTooLarge();
```

### ZeroAddress

```solidity
error ZeroAddress();
```

