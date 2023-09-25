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

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    /**
     * @notice This function is used to receive data from a different chain.
     *
     * @dev This function takes in four parameters:
     *  - _srcChainId: The ID of the source chain.
     *  - _srcAddress: The address of the source chain.
     *  - _nonce: A unique identifier for the transaction.
     *  - _payload: The data to be received.
     */
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}
