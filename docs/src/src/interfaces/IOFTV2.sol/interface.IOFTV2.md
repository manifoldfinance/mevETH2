# IOFTV2
[Git Source](https://github.com/manifoldfinance/mevETH/blob/744c86166044c40a1c176b100f17322ace7974b4/src/interfaces/IOFTV2.sol)

**Inherits:**
[ICommonOFT](/src/interfaces/ICommonOFT.sol/interface.ICommonOFT.md)

*Interface of the IOFT core standard*


## Functions
### sendFrom

*send `_amount` amount of token to (`_dstChainId`, `_toAddress`) from `_from`
`_from` the owner of token
`_dstChainId` the destination chain identifier
`_toAddress` can be any size depending on the `dstChainId`.
`_amount` the quantity of tokens in wei
`_refundAddress` the address LayerZero refunds if too much message fee is sent
`_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
`_adapterParams` is a flexible bytes array to indicate messaging adapter services*


```solidity
function sendFrom(
    address _from,
    uint16 _dstChainId,
    bytes32 _toAddress,
    uint256 _amount,
    LzCallParams calldata _callParams
) external payable;
```

### sendAndCall


```solidity
function sendAndCall(
    address _from,
    uint16 _dstChainId,
    bytes32 _toAddress,
    uint256 _amount,
    bytes calldata _payload,
    uint64 _dstGasForCall,
    LzCallParams calldata _callParams
) external payable;
```

