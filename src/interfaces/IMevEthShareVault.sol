// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IMevEthShareVault {
    struct ProtocolBalance {
        // Accrued fees above the median mev payment
        uint128 fees;
        // Accrued mev payments at or below the median mev payment
        uint128 rewards;
    }

    /* The receive function handles mev/validator payments. If if the msg.sender is the block.coinbase, 
    a ValditorPayment should be emitted and the fees/profits should be updated based on the median validator payment. 
    Otherwise, a MevPayment should be emitted and the fees/profits should be updated based on the medianMevPayment.
    */

    // Function to send rewards to MevEth Contract. In the case of failure, this function sends the funds to the Admin as a fallback.
    function payRewards() external;

    // Two-Step Ownable, have the same commit scheme as mevEth
    // TODO: @controlcpluscontrolv do we need these if we have admin updgrade functions?
    //TODO: if we are going to have a fallback address in the case of failure during payRewards, we will might still want an address other than the admins
    // mapping.
    function commitNewOwner(address newOwner) external;
    function setNewOwner() external;

    // Getter functions for public variables
    function feeTo() external view returns (address feeTo);
    function mevEth() external view returns (address mevEth);
    function admins(address admin) external view returns (bool);
    function operators(address operator) external view returns (bool);
    function protocolBalance() external view returns (ProtocolBalance memory protocolBalance);
    function medianValidatorPayment() external view returns (uint256 median);
    function medianMevPayment() external view returns (uint256 median);

    // Admin controls
    function recoverToken(address token, address recipient, uint256 amount) external;
    // Function to set the `feeTo` address
    function setFeeTo(address newFeeTo) external;
    // Send the protocol fees to the `feeTo` address
    function sendFees() external;
    function addAdmin(address newAdmin) external;
    function deleteAdmin(address oldAdmin) external;
    function addOperator(address newOperator) external;
    function deleteOperator(address oldOperator) external;

    // Operator controls
    function setMedianValidatorPayment(uint256 newMedian) external;
    function setMedianMevPayment(uint256 newMedian) external;
}
