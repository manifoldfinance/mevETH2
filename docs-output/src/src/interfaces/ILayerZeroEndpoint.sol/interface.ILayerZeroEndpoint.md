# ILayerZeroEndpoint
[Git Source](https://github.com/manifoldfinance/mevETH/blob/744c86166044c40a1c176b100f17322ace7974b4/src/interfaces/ILayerZeroEndpoint.sol)

**Inherits:**
[ILayerZeroUserApplicationConfig](/docs-output/src/src/interfaces/ILayerZeroUserApplicationConfig.sol/interface.ILayerZeroUserApplicationConfig.md)


## Functions
### send


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

### getInboundNonce


```solidity
function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);
```

### getOutboundNonce


```solidity
function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);
```

### estimateFees


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


```solidity
function getChainId() external view returns (uint16);
```

### retryPayload


```solidity
function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;
```

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


```solidity
function isSendingPayload() external view returns (bool);
```

### isReceivingPayload


```solidity
function isReceivingPayload() external view returns (bool);
```

### getConfig


```solidity
function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint256 _configType) external view returns (bytes memory);
```

### getSendVersion


```solidity
function getSendVersion(address _userApplication) external view returns (uint16);
```

### getReceiveVersion


```solidity
function getReceiveVersion(address _userApplication) external view returns (uint16);
```

