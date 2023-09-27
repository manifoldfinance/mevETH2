# BytesLib
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/fb1b10e0f4766c0b96be04b99ddfd379368057c1/src/util/BytesLib.sol)

SPDX-License-Identifier: SSPL-1.-0


## Functions
### slice


```solidity
function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory);
```

### toAddress

toAddress() is a pure function that takes in two parameters, bytes memory _bytes and uint256 _start, and returns an address.

*The function first checks if the length of _bytes is greater than or equal to _start + 20. If not, it reverts with an OutOfBounds error. Otherwise,
it loads the address from the memory and returns it.*


```solidity
function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address);
```

### toUint8

This function takes in a bytes memory and a uint256 start and returns a uint8.

*This function uses assembly to load the memory and return the uint8.*


```solidity
function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8);
```

### toUint64


```solidity
function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64);
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

