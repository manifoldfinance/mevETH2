# ExcessivelySafeCall
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/fb1b10e0f4766c0b96be04b99ddfd379368057c1/src/util/ExcessivelySafeCall.sol)

SPDX-License-Identifier: SSPL-1.-0


## Functions
### excessivelySafeCall

Use when you _really_ really _really_ don't trust the called
contract. This prevents the called contract from causing reversion of
the caller in as many ways as we can.

*The main difference between this and a solidity low-level call is
that we limit the number of bytes that the callee can cause to be
copied to caller memory. This prevents stupid things like malicious
contracts returning 10,000,000 bytes causing a local OOG when copying
to memory.*


```solidity
function excessivelySafeCall(address _target, uint256 _gas, uint16 _maxCopy, bytes memory _calldata) internal returns (bool, bytes memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_target`|`address`|The address to call|
|`_gas`|`uint256`|The amount of gas to forward to the remote contract|
|`_maxCopy`|`uint16`|The maximum number of bytes of returndata to copy to memory.|
|`_calldata`|`bytes`|The data to send to the remote contract|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|success and returndata, as `.call()`. Returndata is capped to `_maxCopy` bytes.|
|`<none>`|`bytes`||


