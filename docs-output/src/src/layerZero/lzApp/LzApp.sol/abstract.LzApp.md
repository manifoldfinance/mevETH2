# LzApp
[Git Source](https://github.com/manifoldfinance/mevETH/blob/744c86166044c40a1c176b100f17322ace7974b4/src/layerZero/lzApp/LzApp.sol)

**Inherits:**
[Auth](/docs-output/src/src/libraries/Auth.sol/contract.Auth.md), [ILayerZeroReceiver](/docs-output/src/src/interfaces/ILayerZeroReceiver.sol/interface.ILayerZeroReceiver.md), [ILayerZeroUserApplicationConfig](/docs-output/src/src/interfaces/ILayerZeroUserApplicationConfig.sol/interface.ILayerZeroUserApplicationConfig.md)


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


```solidity
function _getGasLimit(bytes memory _adapterParams) internal pure virtual returns (uint256 gasLimit);
```

### _checkPayloadSize


```solidity
function _checkPayloadSize(uint16 _dstChainId, uint256 _payloadSize) internal view virtual;
```

### getConfig


```solidity
function getConfig(uint16 _version, uint16 _chainId, address, uint256 _configType) external view returns (bytes memory);
```

### setConfig


```solidity
function setConfig(uint16 _version, uint16 _chainId, uint256 _configType, bytes calldata _config) external override onlyAdmin;
```

### setSendVersion


```solidity
function setSendVersion(uint16 _version) external override onlyAdmin;
```

### setReceiveVersion


```solidity
function setReceiveVersion(uint16 _version) external override onlyAdmin;
```

### forceResumeReceive


```solidity
function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyAdmin;
```

### setTrustedRemote


```solidity
function setTrustedRemote(uint16 _remoteChainId, bytes calldata _path) external onlyAdmin;
```

### setTrustedRemoteAddress


```solidity
function setTrustedRemoteAddress(uint16 _remoteChainId, bytes calldata _remoteAddress) external onlyAdmin;
```

### getTrustedRemoteAddress


```solidity
function getTrustedRemoteAddress(uint16 _remoteChainId) external view returns (bytes memory);
```

### setPrecrime


```solidity
function setPrecrime(address _precrime) external onlyAdmin;
```

### setMinDstGas


```solidity
function setMinDstGas(uint16 _dstChainId, uint16 _packetType, uint256 _minGas) external onlyAdmin;
```

### setPayloadSizeLimit


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

