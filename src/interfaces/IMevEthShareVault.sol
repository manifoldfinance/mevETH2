// SPDX-License-Identifier: MIT
import { MevEthShareVault } from "../MevEthShareVault.sol";

pragma solidity ^0.8.19;

interface IMevEthShareVault {
    /* The receive function handles mev/validator payments. If if the msg.sender is the block.coinbase, 
    a ValditorPayment should be emitted and the fees/profits should be updated based on the median validator payment. 
    Otherwise, a MevPayment should be emitted and the fees/profits should be updated based on the medianMevPayment.
    */

    // Function to send rewards to MevEth Contract. In the case of failure, this function sends the funds to the Admin as a fallback.
    function payRewards() external;

    // Getter functions for public variables
    // function feeTo() external view returns (address feeTo);
    // function mevEth() external view returns (address mevEth);
    // function protocolBalance() external view returns (MevEthShareVault.ProtocolBalance memory protocolBalance);
    // function medianValidatorPayment() external view returns (uint256 median);
    // function medianMevPayment() external view returns (uint256 median);
    // function beneficiary() external view returns (address beneficiary);

    // Admin controls
    function recoverToken(address token, address recipient, uint256 amount) external;
    // Send the protocol fees to the `feeTo` address
    function sendFees() external;
    function setFeeTo(address newFeeTo) external;
    function setNewBeneficiary(address newBeneficiary) external;

    // Operator controls
    function setMedianValidatorPayment(uint128 newMedian) external;
    function setMedianMevPayment(uint128 newMedian) external;
}
