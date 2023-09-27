# OFTCoreV2
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/fb1b10e0f4766c0b96be04b99ddfd379368057c1/src/layerZero/oft/OFTCoreV2.sol)

**Inherits:**
[NonblockingLzApp](/gh-pages/src/src/layerZero/lzApp/NonblockingLzApp.sol/abstract.NonblockingLzApp.md)

SPDX-License-Identifier: SSPL-1.-0


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

This function allows the admin to set whether or not to use custom adapter parameters.

*This function sets the boolean value of useCustomAdapterParams to the value of _useCustomAdapterParams. It also emits an event to notify that the
value has been changed.*


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

This function is used to receive a packet from a source chain and process it.

*The packet type is checked and if it is a PT_SEND packet, an acknowledgement is sent. If the packet type is not recognised, the transaction is
reverted.*


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

This function converts a given amount of LD to SD.

*The function takes a uint256 _amount as an argument and returns a uint64 amountSD. The amountSD is calculated by dividing the _amount by the
_ld2sdRate(). If the amountSD is greater than the maximum value of a uint64, the function will revert with an AmountSDOverflow() error.*


```solidity
function _ld2sd(uint256 _amount) internal view virtual returns (uint64);
```

### _sd2ld

_sd2ld() function converts an amount of SD (Solidity Dollars) to LD (Lumens Dollars)

*_sd2ld() function takes a uint64 _amountSD as an argument and returns a uint256 LD amount. The conversion rate is determined by the _ld2sdRate()
function.*


```solidity
function _sd2ld(uint64 _amountSD) internal view virtual returns (uint256);
```

### _removeDust

_removeDust() removes dust from an amount of tokens.

*_removeDust() takes an amount of tokens and removes the dust from it. The dust is calculated by taking the remainder of the amount divided by the
ld2sdRate. The amountAfter is the amount of tokens minus the dust.*


```solidity
function _removeDust(uint256 _amount) internal view virtual returns (uint256 amountAfter, uint256 dust);
```

### _encodeSendPayload

_encodeSendPayload() is a function that encodes the payload for a send transaction.

*_encodeSendPayload() takes two parameters, a bytes32 _toAddress and a uint64 _amountSD. It returns a bytes memory. It uses the abi.encodePacked()
function to encode the payload. The payload consists of the PT_SEND constant, the _toAddress and the _amountSD.*


```solidity
function _encodeSendPayload(bytes32 _toAddress, uint64 _amountSD) internal view virtual returns (bytes memory);
```

### _decodeSendPayload

This function decodes a payload for a send transaction.

*The function takes in a bytes memory _payload and returns an address to and uint64 amountSD.
The first 12 bytes of bytes32 are dropped and the address is taken from the 13th byte. The amountSD is taken from the 33rd byte.
If the first byte of the payload is not PT_SEND or the length of the payload is not 41, the function will revert with an InvalidPayload error.*


```solidity
function _decodeSendPayload(bytes memory _payload) internal view virtual returns (address to, uint64 amountSD);
```

### _debitFrom

Debit an amount from a given address on a given chain

*This function debits an amount from a given address on a given chain.*


```solidity
function _debitFrom(address _from, uint16 _dstChainId, bytes32 _toAddress, uint256 _amount) internal virtual returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_from`|`address`|The address from which the amount is to be debited|
|`_dstChainId`|`uint16`|The chain ID of the chain from which the amount is to be debited|
|`_toAddress`|`bytes32`|The address to which the amount is to be credited|
|`_amount`|`uint256`|The amount to be debited|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount debited|


### _creditTo

This function is used to credit an amount to a given address on a given chain.

*This function is used to credit an amount to a given address on a given chain. It takes in three parameters:
- _srcChainId: The chain ID of the source chain.
- _toAddress: The address to which the amount is to be credited.
- _amount: The amount to be credited.
This function returns the amount credited.*


```solidity
function _creditTo(uint16 _srcChainId, address _toAddress, uint256 _amount) internal virtual returns (uint256);
```

### _transferFrom


```solidity
function _transferFrom(address _from, address _to, uint256 _amount) internal virtual returns (uint256);
```

### _ld2sdRate

This function returns the rate of LD2SD conversion.

*This function is used to get the rate of LD2SD conversion.*


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

