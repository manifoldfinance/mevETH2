# ILayerZeroEndpoint
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/3090c0b460080053b688ae3504dd322da59dd255/src/interfaces/ILayerZeroEndpoint.sol)

**Inherits:**
[ILayerZeroUserApplicationConfig](/src/interfaces/ILayerZeroUserApplicationConfig.sol/interface.ILayerZeroUserApplicationConfig.md)

SPDX-License-Identifier: SSPL-1.-0


## Functions
### send

This function is used to send a payload to a destination on a different chain.

*The function takes in the following parameters:
- _dstChainId: The ID of the destination chain.
- _destination: The address of the destination on the destination chain.
- _payload: The payload to be sent.
- _refundAddress: The address to which the funds should be refunded in case of failure.
- _zroPaymentAddress: The address of the ZROPayment contract.
- _adapterParams: The parameters to be passed to the adapter.*


```solidity
function send(
    uint16 _dstChainId,
    bytes calldata _destination,
    bytes calldata _payload,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes calldata _adapterParams
)
    external
    payable;
```

### receivePayload

*receivePayload is used to receive payloads from other chains.*


```solidity
function receivePayload(
    uint16 _srcChainId,
    bytes calldata _srcAddress,
    address _dstAddress,
    uint64 _nonce,
    uint256 _gasLimit,
    bytes calldata _payload
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_srcChainId`|`uint16`|The source chain ID.|
|`_srcAddress`|`bytes`|The source address.|
|`_dstAddress`|`address`|The destination address.|
|`_nonce`|`uint64`|The nonce of the transaction.|
|`_gasLimit`|`uint256`|The gas limit of the transaction.|
|`_payload`|`bytes`|The payload of the transaction.|


### getInboundNonce

getInboundNonce() is a function that returns the inbound nonce of a given source chain and address.

*getInboundNonce() takes two parameters: _srcChainId and _srcAddress. The _srcChainId is a uint16 representing the source chain ID and the
_srcAddress is a bytes calldata representing the source address. The function returns a uint64 representing the inbound nonce.*


```solidity
function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);
```

### getOutboundNonce


```solidity
function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);
```

### estimateFees

This function estimates the fees for a cross-chain transaction.

*The function takes in the destination chain ID, user application address, payload, boolean value for whether to pay in ZRO, and adapter parameter as
input. It returns the native fee and ZRO fee as output.*


```solidity
function estimateFees(
    uint16 _dstChainId,
    address _userApplication,
    bytes calldata _payload,
    bool _payInZRO,
    bytes calldata _adapterParam
)
    external
    view
    returns (uint256 nativeFee, uint256 zroFee);
```

### getChainId

getChainId()

*Returns the chain ID of the current blockchain.*


```solidity
function getChainId() external view returns (uint16);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint16`|uint16 - The chain ID of the current blockchain.|


### retryPayload

*retryPayload is used to retry a payload from a source chain to a destination chain.*


```solidity
function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_srcChainId`|`uint16`|The source chain ID.|
|`_srcAddress`|`bytes`|The source address.|
|`_payload`|`bytes`|The payload to be retried.|


### hasStoredPayload


```solidity
function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);
```

### getSendLibraryAddress


```solidity
function getSendLibraryAddress(address _userApplication) external view returns (address);
```

### getReceiveLibraryAddress


```solidity
function getReceiveLibraryAddress(address _userApplication) external view returns (address);
```

### isSendingPayload

This function checks if a payload is being sent.

*This function is used to check if a payload is being sent. It returns a boolean value.*


```solidity
function isSendingPayload() external view returns (bool);
```

### isReceivingPayload


```solidity
function isReceivingPayload() external view returns (bool);
```

### getConfig

getConfig() is a function that allows users to retrieve a configuration from the contract.

*getConfig() takes four parameters: _version, _chainId, _userApplication, and _configType. It returns a bytes memory containing the configuration.*


```solidity
function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint256 _configType) external view returns (bytes memory);
```

### getSendVersion

getSendVersion() is a function that returns the version of the user application.

*getSendVersion() takes in an address of the user application and returns a uint16 value representing the version of the user application.*


```solidity
function getSendVersion(address _userApplication) external view returns (uint16);
```

### getReceiveVersion

This function returns the version of the user application.

*This function is used to get the version of the user application. It takes in an address of the user application and returns a uint16 representing
the version of the user application.*


```solidity
function getReceiveVersion(address _userApplication) external view returns (uint16);
```

