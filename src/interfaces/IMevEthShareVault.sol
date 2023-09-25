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


pragma solidity ^0.8.19;

import { MevEthShareVault } from "../MevEthShareVault.sol";

interface IMevEthShareVault {
    /* The receive function handles mev/validator payments. If if the msg.sender is the block.coinbase, 
    a ValditorPayment should be emitted and the fees/profits should be updated based on the median validator payment. 
    Otherwise, a MevPayment should be emitted and the fees/profits should be updated based on the medianMevPayment.
    */

    // Function to send rewards to MevEth Contract. In the case of failure, this function sends the funds to the Admin as a fallback.
    /**
     * @notice This function is used to pay rewards to users.
     * @dev This function is triggered by the owner of the contract and is used to pay rewards to users.
     * It is important to note that this function should only be triggered by the owner of the contract.
     * Any other user should not be able to trigger this function.
     */
    function payRewards() external;

    // Getter functions for public variables
    /**
     * fees()
     *
     * @dev This function returns the fees associated with a transaction.
     *
     * @return uint128 The fees associated with a transaction.
     */
    function fees() external view returns (uint128);
    /**
     * @notice rewards()
     *
     * This function allows users to view the rewards they have earned.
     *
     * @dev
     * rewards() is a view function that returns the rewards earned by the user. It is an external function and does not modify the state of the contract.
     */
    function rewards() external view returns (uint128);

    // Function to update the protocol balance, allocating to the fees and rewards
    /**
     * @notice This function logs the rewards for the protocol.
     * @dev This function logs the rewards for the protocol. It takes in the protocol fees owed as an argument.
     */
    function logRewards(uint128 protocolFeesOwed) external;

    // Admin controls
    function recoverToken(address token, address recipient, uint256 amount) external;
    // Send the protocol fees to the `feeTo` address
    /**
     * @dev Function to send fees to the contract owner.
     * @notice This function should only be called by the contract owner.
     * @param None
     * @return None
     */
    function sendFees() external;
    function setProtocolFeeTo(address newFeeTo) external;
    /**
     * @notice Sets the newMevEth address
     * @dev This function sets the newMevEth address to the address passed in as an argument. This address will be used to store the MEV-ETH tokens.
     */
    function setNewMevEth(address newMevEth) external;
}
