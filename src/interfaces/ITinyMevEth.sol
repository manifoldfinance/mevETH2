/// SPDX-License-Identifier: SSPL-1.-0



pragma solidity ^0.8.19;

/// @title TinyMevEth
/// @notice smol interface for interacting with MevEth
interface ITinyMevEth {
    /**
     * @dev Function to grant rewards to other users.
     * @notice This function is payable and should be called with the amount of rewards to be granted.
     */
    function grantRewards() external payable;
    /**
     * @dev Function to allow a validator to withdraw funds from the contract.
     * @notice This function must be called with a validator address and a payable amount.
     */
    function grantValidatorWithdraw() external payable;
}
