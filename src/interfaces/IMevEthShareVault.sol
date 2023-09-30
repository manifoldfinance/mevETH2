/// SPDX-License-Identifier: SSPL-1.-0



pragma solidity ^0.8.19;

/// @title IMevEthShareVault
interface IMevEthShareVault {

    /**!
    * The receive function handles mev/validator payments.
    * If if the msg.sender is the block.coinbase, a `ValditorPayment` should be emitted
    * The profits (less fees) should be updated based on the median validator payment.
    * Otherwise, a MevPayment should be emitted and the fees/profits should be updated based on the medianMevPayment.
    */

    /**
     * payRewards()
     *
     * @notice Function to send rewards to MevEth Contract.
     * @dev This function is triggered by the owner of the contract and is used to pay rewards to MevETH Contract.
     *      In the case of failure, this function sends the funds to the Admin as a fallback.
     */
    function payRewards(uint256 rewards) external;

    // Function to update the protocol balance, allocating to the fees and rewards

    //! Admin controls //
    function recoverToken(address token, address recipient, uint256 amount) external;

    // Send the protocol fees to the `feeTo` address
    /**
     * sendFees()
     *
     * @dev Function to send fees to the contract owner.
     * @notice This function should only be called by the contract owner.
     */
    function sendFees(uint256 fees) external;
    function setProtocolFeeTo(address newFeeTo) external;

    /**
     * setNewMevEth()
     *
     * @notice Sets the newMevEth address
     * @dev This function sets the newMevEth address to the address passed in as an argument. This address will be used to store the MEV-ETH tokens.
     */
    function setNewMevEth(address newMevEth) external;
}
