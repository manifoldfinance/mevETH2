# NonblockingLzApp
[Git Source](https://github.com/manifoldfinance/mevETH/blob/744c86166044c40a1c176b100f17322ace7974b4/src/layerZero/lzApp/NonblockingLzApp.sol)

**Inherits:**
[LzApp](/docs-output/src/src/layerZero/lzApp/LzApp.sol/abstract.LzApp.md)


## State Variables
### failedMessages

```solidity
mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;
```


## Functions
### constructor


```solidity
constructor(address authority, address _endpoint) LzApp(authority, _endpoint);
```

### _blockingLzReceive


```solidity
function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override;
```

### _storeFailedMessage


```solidity
function _storeFailedMessage(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload, bytes memory _reason) internal virtual;
```

### nonblockingLzReceive


```solidity
function nonblockingLzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public virtual;
```

### _nonblockingLzReceive


```solidity
function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;
```

### retryMessage


```solidity
function retryMessage(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public payable virtual;
```

## Events
### MessageFailed

```solidity
event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload, bytes _reason);
```

### RetryMessageSuccess

```solidity
event RetryMessageSuccess(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _payloadHash);
```

## Errors
### CallerMustBeLzApp

```solidity
error CallerMustBeLzApp();
```

### NoStoredMessage

```solidity
error NoStoredMessage();
```

