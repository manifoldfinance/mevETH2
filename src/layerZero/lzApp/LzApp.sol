/// SPDX-License-Identifier: SSPL-1.-0

/**
 * @custom:org.protocol='mevETH LST Protocol'
 * @custom:org.security='mailto:security@manifoldfinance.com'
 * @custom:org.vcs-commit=$GIT_COMMIT_SHA
 * @custom:org.vendor='CommodityStream, Inc'
 * @custom:org.schema-version="1.0"
 * @custom.org.encryption="manifoldfinance.com/.well-known/pgp-key.asc"
 * @custom:org.preferred-languages="en"
 */



pragma solidity ^0.8.0;

import "../../libraries/Auth.sol";
import "../../interfaces/ILayerZeroReceiver.sol";
import "../../interfaces/ILayerZeroUserApplicationConfig.sol";
import "../../interfaces/ILayerZeroEndpoint.sol";
import "../../util/BytesLib.sol";

/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is Auth, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    // Custom errors save gas
    error NoTrustedPath();
    error InvalidEndpointCaller();
    error DestinationChainNotTrusted();
    error MinGasLimitNotSet();
    error GasLimitTooLow();
    error InvalidAdapterParams();
    error PayloadSizeTooLarge();
    error InvalidMinGas();
    error InvalidSourceSendingContract();

    using BytesLib for bytes;

    // ua can not send payload larger than this by default, but it can be changed by the ua owner
    uint256 public constant DEFAULT_PAYLOAD_SIZE_LIMIT = 10_000;

    ILayerZeroEndpoint public immutable lzEndpoint;
    mapping(uint16 => bytes) public trustedRemoteLookup;
    mapping(uint16 => mapping(uint16 => uint256)) public minDstGasLookup;
    mapping(uint16 => uint256) public payloadSizeLimitLookup;
    address public precrime;

    event SetPrecrime(address precrime);
    event SetTrustedRemote(uint16 _remoteChainId, bytes _path);
    event SetTrustedRemoteAddress(uint16 _remoteChainId, bytes _remoteAddress);
    event SetMinDstGas(uint16 _dstChainId, uint16 _type, uint256 _minDstGas);

    constructor(address authority, address _endpoint) Auth(authority) {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public virtual override {
        // lzReceive must be called by the endpoint for security
        if (msg.sender != address(lzEndpoint)) revert InvalidEndpointCaller();

        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        if (_srcAddress.length != trustedRemote.length || trustedRemote.length == 0 || keccak256(_srcAddress) != keccak256(trustedRemote)) {
            revert InvalidSourceSendingContract();
        }

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    /**
     * @notice This function is used to receive a payload from a different chain.
     * @dev This function is used to receive a payload from a different chain. It is triggered when a payload is sent from a different chain. The payload is
     * stored in the _payload parameter. The _srcChainId parameter is used to identify the chain the payload is coming from. The _srcAddress parameter is used
     * to identify the address the payload is coming from. The _nonce parameter is used to identify the payload.
     */
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function _lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams,
        uint256 _nativeFee
    )
        internal
        virtual
    {
        bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];
        if (trustedRemote.length == 0) revert DestinationChainNotTrusted();
        _checkPayloadSize(_dstChainId, _payload.length);
        lzEndpoint.send{ value: _nativeFee }(_dstChainId, trustedRemote, _payload, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    function _checkGasLimit(uint16 _dstChainId, uint16 _type, bytes memory _adapterParams, uint256 _extraGas) internal view virtual {
        uint256 providedGasLimit = _getGasLimit(_adapterParams);
        uint256 minGasLimit = minDstGasLookup[_dstChainId][_type] + _extraGas;
        if (minGasLimit == 0) revert MinGasLimitNotSet();
        if (providedGasLimit < minGasLimit) revert GasLimitTooLow();
    }

    /**
     * @notice This function is used to get the gas limit from the adapter parameters.
     * @dev The function requires the adapter parameters to be at least 34 bytes long. If the adapter parameters are shorter than 34 bytes, the function will
     * revert with an InvalidAdapterParams error. The gas limit is then loaded from the memory address of the adapter parameters plus 34 bytes.
     */
    function _getGasLimit(bytes memory _adapterParams) internal pure virtual returns (uint256 gasLimit) {
        if (_adapterParams.length < 34) revert InvalidAdapterParams();
        assembly {
            gasLimit := mload(add(_adapterParams, 34))
        }
    }

    function _checkPayloadSize(uint16 _dstChainId, uint256 _payloadSize) internal view virtual {
        uint256 payloadSizeLimit = payloadSizeLimitLookup[_dstChainId];
        if (payloadSizeLimit == 0) {
            // use default if not set
            payloadSizeLimit = DEFAULT_PAYLOAD_SIZE_LIMIT;
        }
        if (_payloadSize > payloadSizeLimit) revert PayloadSizeTooLarge();
    }

    //---------------------------UserApplication config----------------------------------------
    /**
     * @notice getConfig() is a function that retrieves the configuration data from the lzEndpoint.
     * @dev getConfig() takes in four parameters: _version, _chainId, address, and _configType. It returns a bytes memory.
     */
    function getConfig(uint16 _version, uint16 _chainId, address, uint256 _configType) external view returns (bytes memory) {
        return lzEndpoint.getConfig(_version, _chainId, address(this), _configType);
    }

    // generic config for LayerZero user Application
    /**
     * @notice This function is used to set the configuration of the contract.
     * @dev This function is only accessible to the admin of the contract. It takes in four parameters:
     * _version, _chainId, _configType, and _config. The _version and _chainId parameters are used to
     * identify the version and chainId of the contract. The _configType parameter is used to specify
     * the type of configuration being set. The _config parameter is used to pass in the configuration
     * data. The lzEndpoint.setConfig() function is then called to set the configuration.
     */
    function setConfig(uint16 _version, uint16 _chainId, uint256 _configType, bytes calldata _config) external override onlyAdmin {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    /**
     * @notice This function allows an admin to set the send version of the lzEndpoint.
     * @dev This function is only available to admins and will override any existing send version.
     * @param _version The version of the lzEndpoint to be set.
     */
    function setSendVersion(uint16 _version) external override onlyAdmin {
        lzEndpoint.setSendVersion(_version);
    }

    /**
     * @notice This function sets the receive version of the lzEndpoint.
     * @dev This function is only available to the admin and is used to set the receive version of the lzEndpoint.
     * @param _version The version to set the lzEndpoint to.
     */
    function setReceiveVersion(uint16 _version) external override onlyAdmin {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyAdmin {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // _path = abi.encodePacked(remoteAddress, localAddress)
    // this function set the trusted path for the cross-chain communication
    /**
     * @notice This function allows an admin to set a trusted remote chain.
     * @dev This function sets a trusted remote chain by taking in a chain ID and a path. It then stores the path in the trustedRemoteLookup mapping and emits
     * an event.
     */
    function setTrustedRemote(uint16 _remoteChainId, bytes calldata _path) external onlyAdmin {
        trustedRemoteLookup[_remoteChainId] = _path;
        emit SetTrustedRemote(_remoteChainId, _path);
    }

    function setTrustedRemoteAddress(uint16 _remoteChainId, bytes calldata _remoteAddress) external onlyAdmin {
        trustedRemoteLookup[_remoteChainId] = abi.encodePacked(_remoteAddress, address(this));
        emit SetTrustedRemoteAddress(_remoteChainId, _remoteAddress);
    }

    /**
     * @notice getTrustedRemoteAddress() retrieves the trusted remote address for a given chain ID.
     * @dev The function reverts if no trusted path is found for the given chain ID. The last 20 bytes of the path should be address(this).
     */
    function getTrustedRemoteAddress(uint16 _remoteChainId) external view returns (bytes memory) {
        bytes memory path = trustedRemoteLookup[_remoteChainId];
        if (path.length == 0) revert NoTrustedPath();
        return path.slice(0, path.length - 20); // the last 20 bytes should be address(this)
    }

    /**
     * @notice This function allows an admin to set the address of the Precrime contract.
     * @dev This function sets the address of the Precrime contract and emits an event.
     */
    function setPrecrime(address _precrime) external onlyAdmin {
        precrime = _precrime;
        emit SetPrecrime(_precrime);
    }

    /**
     * @dev Sets the minimum gas for a packet type on a destination chain.
     * @param _dstChainId The ID of the destination chain.
     * @param _packetType The type of packet.
     * @param _minGas The minimum gas for the packet type.
     * @return None.
     */
    function setMinDstGas(uint16 _dstChainId, uint16 _packetType, uint256 _minGas) external onlyAdmin {
        if (_minGas == 0) revert InvalidMinGas();
        minDstGasLookup[_dstChainId][_packetType] = _minGas;
        emit SetMinDstGas(_dstChainId, _packetType, _minGas);
    }

    // if the size is 0, it means default size limit
    /**
     * @notice This function sets the payload size limit for a given destination chain.
     * @dev This function is only callable by the admin and sets the payload size limit for a given destination chain.
     */
    function setPayloadSizeLimit(uint16 _dstChainId, uint256 _size) external onlyAdmin {
        payloadSizeLimitLookup[_dstChainId] = _size;
    }

    //--------------------------- VIEW FUNCTION ----------------------------------------
    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
        return keccak256(trustedSource) == keccak256(_srcAddress);
    }
}
