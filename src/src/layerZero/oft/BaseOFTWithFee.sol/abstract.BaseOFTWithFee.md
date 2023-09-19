# BaseOFTWithFee
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/216fe89b4b259aa768c698247b6facac9d08597e/src/layerZero/oft/BaseOFTWithFee.sol)

**Inherits:**
[OFTCoreV2](/src/layerZero/oft/OFTCoreV2.sol/abstract.OFTCoreV2.md), [Fee](/src/layerZero/oft/Fee.sol/abstract.Fee.md), ERC165, [IOFTWithFee](/src/interfaces/IOFTWithFee.sol/interface.IOFTWithFee.md)


## Functions
### constructor


```solidity
constructor(uint8 _sharedDecimals, address authority, address _lzEndpoint) OFTCoreV2(_sharedDecimals, authority, _lzEndpoint) Fee(authority);
```

### sendFrom

public functions


```solidity
function sendFrom(
  address _from,
  uint16 _dstChainId,
  bytes32 _toAddress,
  uint256 _amount,
  uint256 _minAmount,
  LzCallParams calldata _callParams
)
  public
  payable
  virtual
  override;
```

### supportsInterface

public view functions


```solidity
function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool);
```

### estimateSendFee


```solidity
function estimateSendFee(
  uint16 _dstChainId,
  bytes32 _toAddress,
  uint256 _amount,
  bool _useZro,
  bytes calldata _adapterParams
)
  public
  view
  virtual
  override
  returns (uint256 nativeFee, uint256 zroFee);
```

### circulatingSupply


```solidity
function circulatingSupply() public view virtual override returns (uint256);
```

### token


```solidity
function token() public view virtual override returns (address);
```

### _transferFrom


```solidity
function _transferFrom(address _from, address _to, uint256 _amount) internal virtual override(Fee, OFTCoreV2) returns (uint256);
```

## Errors
### AmountLessThanMinAmount

```solidity
error AmountLessThanMinAmount();
```

