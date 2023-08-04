// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../lzApp/NonblockingLzApp.sol";
import "../../util/ExcessivelySafeCall.sol";
import "../../interfaces/ICommonOFT.sol";
import "../../interfaces/IOFTReceiverV2.sol";

abstract contract OFTCoreV2 is NonblockingLzApp {
    // Custom errors save gas
    // error InvalidPayload();
    error CallerMustBeOFTCore();
    // error AmountTooSmall();
    error UnknownPacketType();
    error AdapterParamsMustBeEmpty();
    error AmountSDOverflow();

    using BytesLib for bytes;
    using ExcessivelySafeCall for address;

    uint256 public constant NO_EXTRA_GAS = 0;

    // packet type
    uint8 public constant PT_SEND = 0;
    uint8 public constant PT_SEND_AND_CALL = 1;

    uint8 public immutable sharedDecimals;

    bool public useCustomAdapterParams;
    mapping(uint16 => mapping(bytes => mapping(uint64 => bool))) public creditedPackets;

    /**
     * @dev Emitted when `_amount` tokens are moved from the `_sender` to (`_dstChainId`, `_toAddress`)
     * `_nonce` is the outbound nonce
     */
    event SendToChain(uint16 indexed _dstChainId, address indexed _from, bytes32 indexed _toAddress, uint256 _amount);

    /**
     * @dev Emitted when `_amount` tokens are received from `_srcChainId` into the `_toAddress` on the local chain.
     * `_nonce` is the inbound nonce.
     */
    event ReceiveFromChain(uint16 indexed _srcChainId, address indexed _to, uint256 _amount);

    event SetUseCustomAdapterParams(bool _useCustomAdapterParams);

    event CallOFTReceivedSuccess(uint16 indexed _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _hash);

    event NonContractAddress(address _address);

    // _sharedDecimals should be the minimum decimals on all chains
    constructor(uint8 _sharedDecimals, address authority, address _lzEndpoint) NonblockingLzApp(authority, _lzEndpoint) {
        sharedDecimals = _sharedDecimals;
    }

    /**
     *
     * public functions
     *
     */
    function callOnOFTReceived(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes32 _from,
        address _to,
        uint256 _amount,
        bytes calldata _payload,
        uint256 _gasForCall
    )
        public
        virtual
    {
        if (msg.sender != address(this)) revert CallerMustBeOFTCore();

        // send
        _amount = _transferFrom(address(this), _to, _amount);
        emit ReceiveFromChain(_srcChainId, _to, _amount);

        // call
        IOFTReceiverV2(_to).onOFTReceived{ gas: _gasForCall }(_srcChainId, _srcAddress, _nonce, _from, _amount, _payload);
    }

    function setUseCustomAdapterParams(bool _useCustomAdapterParams) public virtual onlyAdmin {
        useCustomAdapterParams = _useCustomAdapterParams;
        emit SetUseCustomAdapterParams(_useCustomAdapterParams);
    }

    /**
     *
     * internal functions
     *
     */
    function _estimateSendFee(
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount,
        bool _useZro,
        bytes memory _adapterParams
    )
        internal
        view
        virtual
        returns (uint256 nativeFee, uint256 zroFee)
    {
        // mock the payload for sendFrom()
        bytes memory payload = _encodeSendPayload(_toAddress, _ld2sd(_amount));
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, _useZro, _adapterParams);
    }

    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
        uint8 packetType = _payload.toUint8(0);

        if (packetType == PT_SEND) {
            _sendAck(_srcChainId, _srcAddress, _nonce, _payload);
        } else {
            revert UnknownPacketType();
        }
    }

    function _send(
        address _from,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    )
        internal
        virtual
        returns (uint256 amount)
    {
        _checkAdapterParams(_dstChainId, PT_SEND, _adapterParams, NO_EXTRA_GAS);

        (amount,) = _removeDust(_amount);
        amount = _debitFrom(_from, _dstChainId, _toAddress, amount); // amount returned should not have dust
        if (amount == 0) revert AmountTooSmall();

        bytes memory lzPayload = _encodeSendPayload(_toAddress, _ld2sd(amount));
        _lzSend(_dstChainId, lzPayload, _refundAddress, _zroPaymentAddress, _adapterParams, msg.value);

        emit SendToChain(_dstChainId, _from, _toAddress, amount);
    }

    function _sendAck(uint16 _srcChainId, bytes memory, uint64, bytes memory _payload) internal virtual {
        (address to, uint64 amountSD) = _decodeSendPayload(_payload);
        if (to == address(0)) {
            to = address(0xdead);
        }

        uint256 amount = _sd2ld(amountSD);
        amount = _creditTo(_srcChainId, to, amount);

        emit ReceiveFromChain(_srcChainId, to, amount);
    }

    function _checkAdapterParams(uint16 _dstChainId, uint16 _pkType, bytes memory _adapterParams, uint256 _extraGas) internal virtual {
        if (useCustomAdapterParams) {
            _checkGasLimit(_dstChainId, _pkType, _adapterParams, _extraGas);
        } else {
            if (_adapterParams.length != 0) revert AdapterParamsMustBeEmpty();
        }
    }

    function _ld2sd(uint256 _amount) internal view virtual returns (uint64) {
        uint256 amountSD = _amount / _ld2sdRate();
        if (amountSD > type(uint64).max) revert AmountSDOverflow();
        return uint64(amountSD);
    }

    function _sd2ld(uint64 _amountSD) internal view virtual returns (uint256) {
        return _amountSD * _ld2sdRate();
    }

    function _removeDust(uint256 _amount) internal view virtual returns (uint256 amountAfter, uint256 dust) {
        dust = _amount % _ld2sdRate();
        amountAfter = _amount - dust;
    }

    function _encodeSendPayload(bytes32 _toAddress, uint64 _amountSD) internal view virtual returns (bytes memory) {
        return abi.encodePacked(PT_SEND, _toAddress, _amountSD);
    }

    function _decodeSendPayload(bytes memory _payload) internal view virtual returns (address to, uint64 amountSD) {
        if (_payload.toUint8(0) != PT_SEND || _payload.length != 41) revert InvalidPayload();

        to = _payload.toAddress(13); // drop the first 12 bytes of bytes32
        amountSD = _payload.toUint64(33);
    }

    function _debitFrom(address _from, uint16 _dstChainId, bytes32 _toAddress, uint256 _amount) internal virtual returns (uint256);

    function _creditTo(uint16 _srcChainId, address _toAddress, uint256 _amount) internal virtual returns (uint256);

    function _transferFrom(address _from, address _to, uint256 _amount) internal virtual returns (uint256);

    function _ld2sdRate() internal view virtual returns (uint256);
}
