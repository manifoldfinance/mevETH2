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
