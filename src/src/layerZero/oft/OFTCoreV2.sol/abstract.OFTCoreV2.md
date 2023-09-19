# OFTCoreV2
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/216fe89b4b259aa768c698247b6facac9d08597e/src/layerZero/oft/OFTCoreV2.sol)

**Inherits:**
[NonblockingLzApp](/src/layerZero/lzApp/NonblockingLzApp.sol/abstract.NonblockingLzApp.md)


## State Variables
### NO_EXTRA_GAS

```solidity
uint256 public constant NO_EXTRA_GAS = 0;
```


### PT_SEND

```solidity
uint8 public constant PT_SEND = 0;
```


### PT_SEND_AND_CALL

```solidity
uint8 public constant PT_SEND_AND_CALL = 1;
```


### sharedDecimals

```solidity
uint8 public immutable sharedDecimals;
```


### useCustomAdapterParams

```solidity
bool public useCustomAdapterParams;
```


### creditedPackets

```solidity
mapping(uint16 => mapping(bytes => mapping(uint64 => bool))) public creditedPackets;
```


## Functions
### constructor


```solidity
constructor(uint8 _sharedDecimals, address authority, address _lzEndpoint) NonblockingLzApp(authority, _lzEndpoint);
```

### callOnOFTReceived

public functions


```solidity
function callOnOFTReceived(
  uint16 _srcChainId,
  bytes calldata _srcAddress,
  uint64 _nonce,
  bytes32 _from,
  address _to,
  uint256 _amount,
  bytes calldata _payload,
  uint256 _gasForCall
)
  public
  virtual;
```

### setUseCustomAdapterParams


```solidity
function setUseCustomAdapterParams(bool _useCustomAdapterParams) public virtual onlyAdmin;
```

### _estimateSendFee

internal functions


```solidity
function _estimateSendFee(
  uint16 _dstChainId,
  bytes32 _toAddress,
  uint256 _amount,
  bool _useZro,
  bytes memory _adapterParams
)
  internal
  view
  virtual
  returns (uint256 nativeFee, uint256 zroFee);
```

### _nonblockingLzReceive


```solidity
function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override;
```

### _send


```solidity
function _send(
  address _from,
  uint16 _dstChainId,
  bytes32 _toAddress,
  uint256 _amount,
  address payable _refundAddress,
  address _zroPaymentAddress,
  bytes memory _adapterParams
)
  internal
  virtual
  returns (uint256 amount);
```

### _sendAck


```solidity
function _sendAck(uint16 _srcChainId, bytes memory, uint64, bytes memory _payload) internal virtual;
```

### _checkAdapterParams


```solidity
function _checkAdapterParams(uint16 _dstChainId, uint16 _pkType, bytes memory _adapterParams, uint256 _extraGas) internal virtual;
```

### _ld2sd


```solidity
function _ld2sd(uint256 _amount) internal view virtual returns (uint64);
```

### _sd2ld


```solidity
function _sd2ld(uint64 _amountSD) internal view virtual returns (uint256);
```

### _removeDust


```solidity
function _removeDust(uint256 _amount) internal view virtual returns (uint256 amountAfter, uint256 dust);
```

### _encodeSendPayload


```solidity
function _encodeSendPayload(bytes32 _toAddress, uint64 _amountSD) internal view virtual returns (bytes memory);
```

### _decodeSendPayload


```solidity
function _decodeSendPayload(bytes memory _payload) internal view virtual returns (address to, uint64 amountSD);
```

### _debitFrom


```solidity
function _debitFrom(address _from, uint16 _dstChainId, bytes32 _toAddress, uint256 _amount) internal virtual returns (uint256);
```

### _creditTo


```solidity
function _creditTo(uint16 _srcChainId, address _toAddress, uint256 _amount) internal virtual returns (uint256);
```

### _transferFrom


```solidity
function _transferFrom(address _from, address _to, uint256 _amount) internal virtual returns (uint256);
```

### _ld2sdRate


```solidity
function _ld2sdRate() internal view virtual returns (uint256);
```

## Events
### SendToChain
*Emitted when `_amount` tokens are moved from the `_sender` to (`_dstChainId`, `_toAddress`)
`_nonce` is the outbound nonce*


```solidity
event SendToChain(uint16 indexed _dstChainId, address indexed _from, bytes32 indexed _toAddress, uint256 _amount);
```

### ReceiveFromChain
*Emitted when `_amount` tokens are received from `_srcChainId` into the `_toAddress` on the local chain.
`_nonce` is the inbound nonce.*


```solidity
event ReceiveFromChain(uint16 indexed _srcChainId, address indexed _to, uint256 _amount);
```

### SetUseCustomAdapterParams

```solidity
event SetUseCustomAdapterParams(bool _useCustomAdapterParams);
```

### CallOFTReceivedSuccess

```solidity
event CallOFTReceivedSuccess(uint16 indexed _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _hash);
```

### NonContractAddress

```solidity
event NonContractAddress(address _address);
```

## Errors
### CallerMustBeOFTCore

```solidity
error CallerMustBeOFTCore();
```

### UnknownPacketType

```solidity
error UnknownPacketType();
```

### AdapterParamsMustBeEmpty

```solidity
error AdapterParamsMustBeEmpty();
```

### AmountSDOverflow

```solidity
error AmountSDOverflow();
```

