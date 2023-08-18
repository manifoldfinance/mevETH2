// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { MevEthShareVault } from "../MevEthShareVault.sol";

interface IMevEthShareVault {
    /* The receive function handles mev/validator payments. If if the msg.sender is the block.coinbase, 
    a ValditorPayment should be emitted and the fees/profits should be updated based on the median validator payment. 
    Otherwise, a MevPayment should be emitted and the fees/profits should be updated based on the medianMevPayment.
    */

    // Function to send rewards to MevEth Contract. In the case of failure, this function sends the funds to the Admin as a fallback.
    function payRewards() external;

    // Getter functions for public variables
    function fees() external view returns (uint128);
    function rewards() external view returns (uint128);

    // Function to update the protocol balance, allocating to the fees and rewards
    function logRewards(uint128 protocolFeesOwed) external;

    // Admin controls
    function recoverToken(address token, address recipient, uint256 amount) external;
    // Send the protocol fees to the `feeTo` address
    function sendFees() external;
    function setProtocolFeeTo(address newFeeTo) external;
    function setNewMevEth(address newMevEth) external;
}
