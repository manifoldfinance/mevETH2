# ICommonOFT
[Git Source](https://github.com/manifoldfinance/mevETH/blob/744c86166044c40a1c176b100f17322ace7974b4/src/interfaces/ICommonOFT.sol)

**Inherits:**
IERC165

*Interface of the IOFT core standard*


## Functions
### estimateSendFee

*estimate send token `_tokenId` to (`_dstChainId`, `_toAddress`)
_dstChainId - L0 defined chain id to send tokens too
_toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
_amount - amount of the tokens to transfer
_useZro - indicates to use zro to pay L0 fees
_adapterParam - flexible bytes array to indicate messaging adapter services in L0*


```solidity
function estimateSendFee(
    uint16 _dstChainId,
    bytes32 _toAddress,
    uint256 _amount,
    bool _useZro,
    bytes calldata _adapterParams
) external view returns (uint256 nativeFee, uint256 zroFee);
```

### estimateSendAndCallFee


```solidity
function estimateSendAndCallFee(
    uint16 _dstChainId,
    bytes32 _toAddress,
    uint256 _amount,
    bytes calldata _payload,
    uint64 _dstGasForCall,
    bool _useZro,
    bytes calldata _adapterParams
) external view returns (uint256 nativeFee, uint256 zroFee);
```

### circulatingSupply

*returns the circulating amount of tokens on current chain*


```solidity
function circulatingSupply() external view returns (uint256);
```

### token

*returns the address of the ERC20 token*


```solidity
function token() external view returns (address);
```

## Structs
### LzCallParams

```solidity
struct LzCallParams {
    address payable refundAddress;
    address zroPaymentAddress;
    bytes adapterParams;
}
```

