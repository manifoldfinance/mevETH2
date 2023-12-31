# IOFTWithFee
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/3090c0b460080053b688ae3504dd322da59dd255/src/interfaces/IOFTWithFee.sol)

**Inherits:**
[ICommonOFT](/src/interfaces/ICommonOFT.sol/interface.ICommonOFT.md)

SPDX-License-Identifier: SSPL-1.-0

*Interface of the IOFT core standard*


## Functions
### sendFrom

*send `_amount` amount of token to (`_dstChainId`, `_toAddress`) from `_from`
`_from` the owner of token
`_dstChainId` the destination chain identifier
`_toAddress` can be any size depending on the `dstChainId`.
`_amount` the quantity of tokens in wei
`_minAmount` the minimum amount of tokens to receive on dstChain
`_refundAddress` the address LayerZero refunds if too much message fee is sent
`_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
`_adapterParams` is a flexible bytes array to indicate messaging adapter services*


```solidity
function sendFrom(
    address _from,
    uint16 _dstChainId,
    bytes32 _toAddress,
    uint256 _amount,
    uint256 _minAmount,
    LzCallParams calldata _callParams
)
    external
    payable;
```

