// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "./interfaces/ITinyMevEth.sol";
import "./interfaces/IMevEthShareVault.sol";
import "./libraries/Auth.sol";

/// @title MevEthShareVault
/// @notice This contract controls the ETH Rewards earned by mevEth
contract MevEthShareVault is Auth, IMevEthShareVault {
    receive() external payable { }

    fallback() external payable { }

    ITinyMevEth public immutable MEV_ETH;

    uint256 avgFeeRewardsPerBlock;

    /// @notice Construction sets authority, MevEth, and averageFeeRewardsPerBlock
    /// @param authority The address of the controlling admin authority
    /// @param mevEth The address of the WETH contract to use for deposits
    /// @param initialFeeRewardsPerBlock TODO: add description for how this is used

    constructor(address authority, address mevEth, uint256 initialFeeRewardsPerBlock) Auth(authority) {
        MEV_ETH = ITinyMevEth(mevEth);
        avgFeeRewardsPerBlock = initialFeeRewardsPerBlock;
    }

    function payRewards(uint256 amount) external {
        MEV_ETH.grantRewards{ value: amount }();
    }
}
