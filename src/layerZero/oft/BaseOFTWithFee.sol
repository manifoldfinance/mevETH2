/// SPDX-License-Identifier: SSPL-1.-0



pragma solidity ^0.8.0;

import "./OFTCoreV2.sol";
import "../../interfaces/IOFTWithFee.sol";
import "./Fee.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract BaseOFTWithFee is OFTCoreV2, Fee, ERC165, IOFTWithFee {
    // Custom errors save gas
    error AmountLessThanMinAmount();

    constructor(uint8 _sharedDecimals, address authority, address _lzEndpoint) OFTCoreV2(_sharedDecimals, authority, _lzEndpoint) Fee(authority) { }

    /**
     *
     * public functions
     *
     */
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
        override
    {
        (_amount,) = _payOFTFee(_from, _dstChainId, _amount);
        _amount = _send(_from, _dstChainId, _toAddress, _amount, _callParams.refundAddress, _callParams.zroPaymentAddress, _callParams.adapterParams);
        if (_amount < _minAmount) revert AmountLessThanMinAmount();
    }

    /**
     *
     * public view functions
     *
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IOFTWithFee).interfaceId || super.supportsInterface(interfaceId);
    }

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
        returns (uint256 nativeFee, uint256 zroFee)
    {
        return _estimateSendFee(_dstChainId, _toAddress, _amount, _useZro, _adapterParams);
    }

    /**
     * @notice This function returns the circulating supply of a token.
     * @dev This function is used to get the circulating supply of a token. It is an override of the virtual function and is public and viewable. It returns a
     * uint256 value.
     */
    function circulatingSupply() public view virtual override returns (uint256);

    /**
     * @notice This function returns the address of the token associated with the contract.
     * @dev This function is a virtual override of the token() function.
     */
    function token() public view virtual override returns (address);

    /**
     * @notice This function is used to transfer tokens from one address to another.
     * @dev This function is used to transfer tokens from one address to another. It takes three parameters: _from, _to, and _amount. _from is the address from
     * which the tokens are being transferred, _to is the address to which the tokens are being transferred, and _amount is the amount of tokens being
     * transferred. This function is internal and virtual, and it overrides the Fee and OFTCoreV2 contracts. It returns the amount of tokens transferred.
     */
    function _transferFrom(address _from, address _to, uint256 _amount) internal virtual override(Fee, OFTCoreV2) returns (uint256);
}
