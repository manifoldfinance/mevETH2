# BaseOFTV2
[Git Source](https://github.com/manifoldfinance/mevETH/blob/744c86166044c40a1c176b100f17322ace7974b4/src/layerZero/oft/BaseOFTV2.sol)

**Inherits:**
[OFTCoreV2](/src/layerZero/oft/OFTCoreV2.sol/abstract.OFTCoreV2.md), ERC165, [IOFTV2](/src/interfaces/IOFTV2.sol/interface.IOFTV2.md)


## Functions
### constructor


```solidity
constructor(uint8 _sharedDecimals, address authority, address _lzEndpoint)
    OFTCoreV2(_sharedDecimals, authority, _lzEndpoint);
```

### sendFrom

public functions


```solidity
function sendFrom(
    address _from,
    uint16 _dstChainId,
    bytes32 _toAddress,
    uint256 _amount,
    LzCallParams calldata _callParams
) public payable virtual override;
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
) public payable virtual override;
```

### supportsInterface

public view functions


```solidity
function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool);
```

### estimateSendFee


```solidity
function estimateSendFee(
    uint16 _dstChainId,
    bytes32 _toAddress,
    uint256 _amount,
    bool _useZro,
    bytes calldata _adapterParams
) public view virtual override returns (uint256 nativeFee, uint256 zroFee);
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
) public view virtual override returns (uint256 nativeFee, uint256 zroFee);
```

### circulatingSupply


```solidity
function circulatingSupply() public view virtual override returns (uint256);
```

### token


```solidity
function token() public view virtual override returns (address);
```

