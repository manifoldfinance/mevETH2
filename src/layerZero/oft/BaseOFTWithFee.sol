// SPDX-License-Identifier: MIT

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

    function circulatingSupply() public view virtual override returns (uint256);

    function token() public view virtual override returns (address);

    function _transferFrom(address _from, address _to, uint256 _amount) internal virtual override(Fee, OFTCoreV2) returns (uint256);
}
