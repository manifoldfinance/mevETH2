# OFTV2
[Git Source](https://github.com/manifoldfinance/mevETH/blob/744c86166044c40a1c176b100f17322ace7974b4/src/layerZero/oft/OFTV2.sol)

**Inherits:**
[BaseOFTV2](/docs-output/src/src/layerZero/oft/BaseOFTV2.sol/abstract.BaseOFTV2.md), ERC20


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
    BaseOFTV2(_sharedDecimals, authority, _lzEndpoint);
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

### SharedDecimalsTooLarge

```solidity
error SharedDecimalsTooLarge();
```

