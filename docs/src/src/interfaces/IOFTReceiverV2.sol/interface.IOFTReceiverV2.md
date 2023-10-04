# IOFTReceiverV2
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/3090c0b460080053b688ae3504dd322da59dd255/src/interfaces/IOFTReceiverV2.sol)

SPDX-License-Identifier: SSPL-1.-0


## Functions
### onOFTReceived

*Called by the OFT contract when tokens are received from source chain.*


```solidity
function onOFTReceived(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes32 _from, uint256 _amount, bytes calldata _payload) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_srcChainId`|`uint16`|The chain id of the source chain.|
|`_srcAddress`|`bytes`|The address of the OFT token contract on the source chain.|
|`_nonce`|`uint64`|The nonce of the transaction on the source chain.|
|`_from`|`bytes32`|The address of the account who calls the sendAndCall() on the source chain.|
|`_amount`|`uint256`|The amount of tokens to transfer.|
|`_payload`|`bytes`|Additional data with no specified format.|


