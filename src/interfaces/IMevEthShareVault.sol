// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMevEthShareVault {
    /* The receive function handles mev/validator payments. If if the msg.sender is the block.coinbase,
    a ValditorPayment should be emitted and the fees/profits should be updated based on the median validator payment.
    Otherwise, a MevPayment should be emitted and the fees/profits should be updated based on the medianMevPayment.
    */

    function protocolBalance() external view returns (uint128 feesPaid, uint128 rewardsPaid, uint128 exitsPaid, uint128 totalWithdrawn);
    // Function to send rewards to MevEth Contract. In the case of failure, this function sends the funds to the Admin as a fallback.
    function payRewards(uint256 rewards) external;

    // Admin controls
    function recoverToken(address token, address recipient, uint256 amount) external;
    // Send the protocol fees to the `feeTo` address
    function sendFees(uint256 fees) external;
    function setProtocolFeeTo(address newFeeTo) external;
    function setNewMevEth(address newMevEth) external;
}
