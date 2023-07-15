# BytesLib
[Git Source](https://github.com/manifoldfinance/mevETH/blob/744c86166044c40a1c176b100f17322ace7974b4/src/util/BytesLib.sol)


## Functions
### slice


```solidity
function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory);
```

### toAddress


```solidity
function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address);
```

### toUint8


```solidity
function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8);
```

### toUint64


```solidity
function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64);
```

### toBytes32


```solidity
function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32);
```

## Errors
### SliceOverflow

```solidity
error SliceOverflow();
```

### OutOfBounds

```solidity
error OutOfBounds();
```

