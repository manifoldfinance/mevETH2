# LzApp
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/fb1b10e0f4766c0b96be04b99ddfd379368057c1/src/layerZero/lzApp/LzApp.sol)

**Inherits:**
[Auth](/gh-pages/src/src/libraries/Auth.sol/contract.Auth.md), [ILayerZeroReceiver](/gh-pages/src/src/interfaces/ILayerZeroReceiver.sol/interface.ILayerZeroReceiver.md), [ILayerZeroUserApplicationConfig](/gh-pages/src/src/interfaces/ILayerZeroUserApplicationConfig.sol/interface.ILayerZeroUserApplicationConfig.md)

SPDX-License-Identifier: SSPL-1.-0


## State Variables
### DEFAULT_PAYLOAD_SIZE_LIMIT

```solidity
uint256 public constant DEFAULT_PAYLOAD_SIZE_LIMIT = 10_000;
```


### lzEndpoint

```solidity
ILayerZeroEndpoint public immutable lzEndpoint;
```


### trustedRemoteLookup

```solidity
mapping(uint16 => bytes) public trustedRemoteLookup;
```


### minDstGasLookup

```solidity
mapping(uint16 => mapping(uint16 => uint256)) public minDstGasLookup;
```


### payloadSizeLimitLookup

```solidity
mapping(uint16 => uint256) public payloadSizeLimitLookup;
```


### precrime

```solidity
address public precrime;
```


## Functions
### constructor


```solidity
constructor(address authority, address _endpoint) Auth(authority);
```

### lzReceive


```solidity
function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public virtual override;
```

### _blockingLzReceive

This function is used to receive a payload from a different chain.

*This function is used to receive a payload from a different chain. It is triggered when a payload is sent from a different chain. The payload is
stored in the _payload parameter. The _srcChainId parameter is used to identify the chain the payload is coming from. The _srcAddress parameter is used
to identify the address the payload is coming from. The _nonce parameter is used to identify the payload.*


```solidity
function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;
```

### _lzSend


```solidity
function _lzSend(
    uint16 _dstChainId,
    bytes memory _payload,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes memory _adapterParams,
    uint256 _nativeFee
)
    internal
    virtual;
```

### _checkGasLimit


```solidity
function _checkGasLimit(uint16 _dstChainId, uint16 _type, bytes memory _adapterParams, uint256 _extraGas) internal view virtual;
```

### _getGasLimit

This function is used to get the gas limit from the adapter parameters.

*The function requires the adapter parameters to be at least 34 bytes long. If the adapter parameters are shorter than 34 bytes, the function will
revert with an InvalidAdapterParams error. The gas limit is then loaded from the memory address of the adapter parameters plus 34 bytes.*


```solidity
function _getGasLimit(bytes memory _adapterParams) internal pure virtual returns (uint256 gasLimit);
```

### _checkPayloadSize


```solidity
function _checkPayloadSize(uint16 _dstChainId, uint256 _payloadSize) internal view virtual;
```

### getConfig

getConfig() is a function that retrieves the configuration data from the lzEndpoint.

*getConfig() takes in four parameters: _version, _chainId, address, and _configType. It returns a bytes memory.*


```solidity
function getConfig(uint16 _version, uint16 _chainId, address, uint256 _configType) external view returns (bytes memory);
```

### setConfig

This function is used to set the configuration of the contract.

*This function is only accessible to the admin of the contract. It takes in four parameters:
_version, _chainId, _configType, and _config. The _version and _chainId parameters are used to
identify the version and chainId of the contract. The _configType parameter is used to specify
the type of configuration being set. The _config parameter is used to pass in the configuration
data. The lzEndpoint.setConfig() function is then called to set the configuration.*


```solidity
function setConfig(uint16 _version, uint16 _chainId, uint256 _configType, bytes calldata _config) external override onlyAdmin;
```

### setSendVersion

This function allows an admin to set the send version of the lzEndpoint.

*This function is only available to admins and will override any existing send version.*


```solidity
function setSendVersion(uint16 _version) external override onlyAdmin;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_version`|`uint16`|The version of the lzEndpoint to be set.|


### setReceiveVersion

This function sets the receive version of the lzEndpoint.

*This function is only available to the admin and is used to set the receive version of the lzEndpoint.*


```solidity
function setReceiveVersion(uint16 _version) external override onlyAdmin;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_version`|`uint16`|The version to set the lzEndpoint to.|


### forceResumeReceive


```solidity
function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyAdmin;
```

### setTrustedRemote

This function allows an admin to set a trusted remote chain.

*This function sets a trusted remote chain by taking in a chain ID and a path. It then stores the path in the trustedRemoteLookup mapping and emits
an event.*


```solidity
function setTrustedRemote(uint16 _remoteChainId, bytes calldata _path) external onlyAdmin;
```

### setTrustedRemoteAddress


```solidity
function setTrustedRemoteAddress(uint16 _remoteChainId, bytes calldata _remoteAddress) external onlyAdmin;
```

### getTrustedRemoteAddress

getTrustedRemoteAddress() retrieves the trusted remote address for a given chain ID.

*The function reverts if no trusted path is found for the given chain ID. The last 20 bytes of the path should be address(this).*


```solidity
function getTrustedRemoteAddress(uint16 _remoteChainId) external view returns (bytes memory);
```

### setPrecrime

This function allows an admin to set the address of the Precrime contract.

*This function sets the address of the Precrime contract and emits an event.*


```solidity
function setPrecrime(address _precrime) external onlyAdmin;
```

### setMinDstGas

*Sets the minimum gas for a packet type on a destination chain.*


```solidity
function setMinDstGas(uint16 _dstChainId, uint16 _packetType, uint256 _minGas) external onlyAdmin;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_dstChainId`|`uint16`|The ID of the destination chain.|
|`_packetType`|`uint16`|The type of packet.|
|`_minGas`|`uint256`|The minimum gas for the packet type.|


### setPayloadSizeLimit

This function sets the payload size limit for a given destination chain.

*This function is only callable by the admin and sets the payload size limit for a given destination chain.*


```solidity
function setPayloadSizeLimit(uint16 _dstChainId, uint256 _size) external onlyAdmin;
```

### isTrustedRemote


```solidity
function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);
```

## Events
### SetPrecrime

```solidity
event SetPrecrime(address precrime);
```

### SetTrustedRemote

```solidity
event SetTrustedRemote(uint16 _remoteChainId, bytes _path);
```

### SetTrustedRemoteAddress

```solidity
event SetTrustedRemoteAddress(uint16 _remoteChainId, bytes _remoteAddress);
```

### SetMinDstGas

```solidity
event SetMinDstGas(uint16 _dstChainId, uint16 _type, uint256 _minDstGas);
```

## Errors
### NoTrustedPath

```solidity
error NoTrustedPath();
```

### InvalidEndpointCaller

```solidity
error InvalidEndpointCaller();
```

### DestinationChainNotTrusted

```solidity
error DestinationChainNotTrusted();
```

### MinGasLimitNotSet

```solidity
error MinGasLimitNotSet();
```

### GasLimitTooLow

```solidity
error GasLimitTooLow();
```

### InvalidAdapterParams

```solidity
error InvalidAdapterParams();
```

### PayloadSizeTooLarge

```solidity
error PayloadSizeTooLarge();
```

### InvalidMinGas

```solidity
error InvalidMinGas();
```

### InvalidSourceSendingContract

```solidity
error InvalidSourceSendingContract();
```

