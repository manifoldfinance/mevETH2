# ILayerZeroReceiver
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/fb1b10e0f4766c0b96be04b99ddfd379368057c1/src/interfaces/ILayerZeroReceiver.sol)

SPDX-License-Identifier: SSPL-1.-0


## Functions
### lzReceive

This function is used to receive data from a different chain.

*This function takes in four parameters:
- _srcChainId: The ID of the source chain.
- _srcAddress: The address of the source chain.
- _nonce: A unique identifier for the transaction.
- _payload: The data to be received.*


```solidity
function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
```

