// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

/// @title tinyMevEth
/// @notice smol interface for interacting with MevEth
interface tinyMevETH {
    function grantRewards() external payable;
}

/// @title MevEthShareVault
/// @notice This contract controls the ETH Rewards earned by mevEth
contract MevEthShareVault {
    receive() external payable { }

    fallback() external payable { }

    tinyMevETH public immutable mevEth;

    uint256 avgFeeRewardsPerBlock;

    constructor(address _mevEth, uint256 _initialFeeRewardsPerBlock) {
        mevEth = tinyMevETH(_mevEth);
        avgFeeRewardsPerBlock = _initialFeeRewardsPerBlock;
    }
}
