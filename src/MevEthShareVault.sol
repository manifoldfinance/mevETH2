// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

import "./interfaces/ITinyMevEth.sol";

/// @title MevEthShareVault
/// @notice This contract controls the ETH Rewards earned by mevEth
contract MevEthShareVault {
    receive() external payable { }

    fallback() external payable { }

    ITinyMevEth public immutable MEV_ETH;

    uint256 avgFeeRewardsPerBlock;

    constructor(address mevEth, uint256 initialFeeRewardsPerBlock) {
        MEV_ETH = ITinyMevEth(mevEth);
        avgFeeRewardsPerBlock = initialFeeRewardsPerBlock;
    }

    function payRewards(uint256 amount) external {
        MEV_ETH.grantRewards{ value: amount }();
    }
}
