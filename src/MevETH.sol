// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {TwoStepOwnable} from "./auth/TwoStepOwnable.sol";
import {NonblockingLzApp} from "./layerzero/NonblockingLzApp.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

// todo: send event with nonce - check opengate
// todo: add burn function permissioned to lsd
// omni-chain rewards token
// minted from manifoldLSD
contract MevETH is ERC20, TwoStepOwnable, NonblockingLzApp {
    using FixedPointMathLib for uint256;

    error OnlyManifoldLSDCallable();
    error AdapterParamsNotEmpty();

    event SendToChain(
        uint16 indexed _dstChainId,
        address indexed _from,
        address _toAddress,
        uint _amount
    );

    /**
     * @dev Emitted when `_amount` tokens are received from `_srcChainId` into the `_toAddress` on the local chain.
     * `_nonce` is the inbound nonce.
     */
    event ReceiveFromChain(
        uint16 indexed _srcChainId,
        address indexed _to,
        uint _amount
    );

    event SetUseCustomAdapterParams(bool _useCustomAdapterParams);

    event ManifoldLsdSet(address indexed manifoldLSD);

    uint256 public constant NO_EXTRA_GAS = 0;
    // packet type
    uint16 public constant PT_SEND = 0;

    address public manifoldLSD;
    bool public useCustomAdapterParams;

    address public bridgeFeeReceiver;
    uint256 public bridgeFeeBPS;

    /**
     * @dev Throws if called by any account other than manifoldLSD.
     */
    modifier onlyManifoldLSD() {
        if (msg.sender != manifoldLSD) revert OnlyManifoldLSDCallable();
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _manifoldLSD,
        address _endpoint
    ) ERC20(_name, _symbol, _decimals) NonblockingLzApp(_endpoint) {
        // todo: maybe have this be a param
        _initializeOwner(msg.sender);
        manifoldLSD = _manifoldLSD;
    }

    function setManifoldLSD(address _manifoldLSD) external onlyOwner {
        manifoldLSD = _manifoldLSD;
        emit ManifoldLsdSet(_manifoldLSD);
    }

    function mint(address to, uint256 amount) external onlyManifoldLSD {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyManifoldLSD {
        _burn(from, amount);
    }

    // ======= OMNI CHAIN LAYERZERO FUNCS ==============

    // generic config for LayerZero user Application
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint _configType,
        bytes calldata _config
    ) external override onlyOwner {
        _setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        _setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        _setReceiveVersion(_version);
    }

    function forceResumeReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress
    ) external override onlyOwner {
        _forceResumeReceive(_srcChainId, _srcAddress);
    }

    function setTrustedRemote(
        uint16 _srcChainId,
        bytes calldata _path
    ) external onlyOwner {
        _setTrustedRemote(_srcChainId, _path);
    }

    function setTrustedRemoteAddress(
        uint16 _remoteChainId,
        bytes calldata _remoteAddress
    ) external onlyOwner {
        _setTrustedRemoteAddress(_remoteChainId, _remoteAddress);
    }

    function setPrecrime(address _precrime) external onlyOwner {
        _setPrecrime(_precrime);
    }

    function setMinDstGas(
        uint16 _dstChainId,
        uint16 _packetType,
        uint _minGas
    ) external onlyOwner {
        _setMinDstGas(_dstChainId, _packetType, _minGas);
    }

    // // if the size is 0, it means default size limit
    function setPayloadSizeLimit(
        uint16 _dstChainId,
        uint _size
    ) external onlyOwner {
        _setPayloadSizeLimit(_dstChainId, _size);
    }

    // view func to estimate fees
    function estimateSendFee(
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint _amount,
        bool _useZro,
        bytes calldata _adapterParams
    ) public view returns (uint nativeFee, uint zroFee) {
        // mock the payload for sendFrom()
        bytes memory payload = abi.encode(PT_SEND, _toAddress, _amount);
        return
            lzEndpoint.estimateFees(
                _dstChainId,
                address(this),
                payload,
                _useZro,
                _adapterParams
            );
    }

    function setUseCustomAdapterParams(
        bool _useCustomAdapterParams
    ) external onlyOwner {
        useCustomAdapterParams = _useCustomAdapterParams;
        emit SetUseCustomAdapterParams(_useCustomAdapterParams);
    }

    function _calculateFee(uint256 amount) internal view returns (uint256) {
        return amount.mulDivDown(bridgeFeeBPS, 1e18);
    }

    function sendCrossChain(
        address _from,
        uint16 _dstChainId,
        address _toAddress,
        uint256 amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal {
        _checkAdapterParams(_dstChainId, PT_SEND, _adapterParams, NO_EXTRA_GAS);

        if (_from != msg.sender) {
            uint256 allowed = allowance[_from][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[_from][msg.sender] = allowed - amount;
        }

        uint256 fee = _calculateFee(amount);

        _burn(_from, amount);

        // mint fee to receiver
        _mint(bridgeFeeReceiver, fee);

        // bridge amount - fee
        bytes memory lzPayload = abi.encode(PT_SEND, _toAddress, amount - fee);

        // require todo

        _lzSend(
            _dstChainId,
            lzPayload,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams,
            msg.value
        );

        emit SendToChain(_dstChainId, _from, _toAddress, amount);
    }

    function _checkAdapterParams(
        uint16 _dstChainId,
        uint16 _pkType,
        bytes memory _adapterParams,
        uint256 _extraGas
    ) internal view {
        if (useCustomAdapterParams) {
            _checkGasLimit(_dstChainId, _pkType, _adapterParams, _extraGas);
        } else {
            if (_adapterParams.length != 0) revert AdapterParamsNotEmpty();
        }
    }

    //bytes memory lzPayload = abi.encode(PT_SEND, _toAddress, amount);
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal override {
        // uint16 packetType;
        // assembly {
        //     packetType := mload(add(_payload, 32))
        // }

        (uint16 packetType, address to, uint256 amount) = abi.decode(
            _payload,
            (uint16, address, uint256)
        );

        if (packetType == PT_SEND) {
            _mint(to, amount);
        } else {
            revert("OFTCore: unknown packet type");
        }

        emit ReceiveFromChain(_srcChainId, to, amount);
    }

    function setFee(uint256 bps) external onlyOwner {
        bridgeFeeBPS = bps;
    }

    function setFeeReceiver(address receiver) external onlyOwner {
        bridgeFeeReceiver = receiver;
    }
}
