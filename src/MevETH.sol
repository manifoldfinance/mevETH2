// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {TwoStepOwnable} from "./auth/TwoStepOwnable.sol";
import {NonblockingLzApp} from "./layerzero/NonblockingLzApp.sol";

// omni-chain rewards token
// minted from manifoldLSD
contract MevETH is ERC20, TwoStepOwnable, NonblockingLzApp {
    error OnlyManifoldLSDCallable();

    address public manifoldLSD;

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
        // todo: emit event
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

    // todo: implement credit/debit omnichain funcs
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal override {}
}
