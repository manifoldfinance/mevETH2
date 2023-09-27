# BaseOFTWithFee
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/fb1b10e0f4766c0b96be04b99ddfd379368057c1/src/layerZero/oft/BaseOFTWithFee.sol)

**Inherits:**
[OFTCoreV2](/gh-pages/src/src/layerZero/oft/OFTCoreV2.sol/abstract.OFTCoreV2.md), [Fee](/gh-pages/src/src/layerZero/oft/Fee.sol/abstract.Fee.md), ERC165, [IOFTWithFee](/gh-pages/src/src/interfaces/IOFTWithFee.sol/interface.IOFTWithFee.md)

SPDX-License-Identifier: SSPL-1.-0


## Functions
### constructor


```solidity
constructor(uint8 _sharedDecimals, address authority, address _lzEndpoint) OFTCoreV2(_sharedDecimals, authority, _lzEndpoint) Fee(authority);
```

### sendFrom

public functions


```solidity
function sendFrom(
    address _from,
    uint16 _dstChainId,
    bytes32 _toAddress,
    uint256 _amount,
    uint256 _minAmount,
    LzCallParams calldata _callParams
)
    public
    payable
    virtual
    override;
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
)
    public
    view
    virtual
    override
    returns (uint256 nativeFee, uint256 zroFee);
```

### circulatingSupply

This function returns the circulating supply of a token.

*This function is used to get the circulating supply of a token. It is an override of the virtual function and is public and viewable. It returns a
uint256 value.*


```solidity
function circulatingSupply() public view virtual override returns (uint256);
```

### token

This function returns the address of the token associated with the contract.

*This function is a virtual override of the token() function.*


```solidity
function token() public view virtual override returns (address);
```

### _transferFrom

This function is used to transfer tokens from one address to another.

*This function is used to transfer tokens from one address to another. It takes three parameters: _from, _to, and _amount. _from is the address from
which the tokens are being transferred, _to is the address to which the tokens are being transferred, and _amount is the amount of tokens being
transferred. This function is internal and virtual, and it overrides the Fee and OFTCoreV2 contracts. It returns the amount of tokens transferred.*


```solidity
function _transferFrom(address _from, address _to, uint256 _amount) internal virtual override(Fee, OFTCoreV2) returns (uint256);
```

## Errors
### AmountLessThanMinAmount

```solidity
error AmountLessThanMinAmount();
```

