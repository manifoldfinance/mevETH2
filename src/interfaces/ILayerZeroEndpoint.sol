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

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    /**
     * @notice This function is used to send a payload to a destination on a different chain.
     * @dev The function takes in the following parameters:
     *  - _dstChainId: The ID of the destination chain.
     *  - _destination: The address of the destination on the destination chain.
     *  - _payload: The payload to be sent.
     *  - _refundAddress: The address to which the funds should be refunded in case of failure.
     *  - _zroPaymentAddress: The address of the ZROPayment contract.
     *  - _adapterParams: The parameters to be passed to the adapter.
     */
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    )
        external
        payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    /**
     * @dev receivePayload is used to receive payloads from other chains.
     * @param _srcChainId The source chain ID.
     * @param _srcAddress The source address.
     * @param _dstAddress The destination address.
     * @param _nonce The nonce of the transaction.
     * @param _gasLimit The gas limit of the transaction.
     * @param _payload The payload of the transaction.
     */
    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint64 _nonce,
        uint256 _gasLimit,
        bytes calldata _payload
    )
        external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    /**
     * @notice getInboundNonce() is a function that returns the inbound nonce of a given source chain and address.
     * @dev getInboundNonce() takes two parameters: _srcChainId and _srcAddress. The _srcChainId is a uint16 representing the source chain ID and the
     * _srcAddress is a bytes calldata representing the source address. The function returns a uint64 representing the inbound nonce.
     */
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    /**
     * @notice This function estimates the fees for a cross-chain transaction.
     * @dev The function takes in the destination chain ID, user application address, payload, boolean value for whether to pay in ZRO, and adapter parameter as
     * input. It returns the native fee and ZRO fee as output.
     */
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    )
        external
        view
        returns (uint256 nativeFee, uint256 zroFee);

    // @notice get this Endpoint's immutable source identifier
    /**
     * getChainId()
     *
     * @dev Returns the chain ID of the current blockchain.
     *
     * @return uint16 - The chain ID of the current blockchain.
     */
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    /**
     * @dev retryPayload is used to retry a payload from a source chain to a destination chain.
     * @param _srcChainId The source chain ID.
     * @param _srcAddress The source address.
     * @param _payload The payload to be retried.
     */
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    /**
     * @notice This function checks if a payload is being sent.
     * @dev This function is used to check if a payload is being sent. It returns a boolean value.
     */
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    /**
     * @notice getConfig() is a function that allows users to retrieve a configuration from the contract.
     * @dev getConfig() takes four parameters: _version, _chainId, _userApplication, and _configType. It returns a bytes memory containing the configuration.
     */
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint256 _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    /**
     * @notice getSendVersion() is a function that returns the version of the user application.
     * @dev getSendVersion() takes in an address of the user application and returns a uint16 value representing the version of the user application.
     */
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    /**
     * @notice This function returns the version of the user application.
     * @dev This function is used to get the version of the user application. It takes in an address of the user application and returns a uint16 representing
     * the version of the user application.
     */
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}
