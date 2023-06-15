// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

/// @title TinyMevEth
/// @notice smol interface for interacting with MevEth
interface ITinyMevEth {
    function grantRewards() external payable;
}
