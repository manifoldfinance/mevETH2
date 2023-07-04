// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import { Auth } from "./libraries/Auth.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { ITinyMevEth } from "./interfaces/ITinyMevEth.sol";
import { IMevEthShareVault } from "./interfaces/IMevEthShareVault.sol";

/// @title MevEthShareVault
/// @notice This contract controls the ETH Rewards earned by mevEth
contract MevEthShareVault is Auth, IMevEthShareVault {
    using SafeTransferLib for ERC20;

    receive() external payable { }

    fallback() external payable { }

    ITinyMevEth public immutable MEV_ETH;

    uint256 avgFeeRewardsPerBlock;

    event TokenRecovered(address indexed recipient, address indexed token, uint256 indexed amount);

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

    function recoverToken(address token, address recipient, uint256 amount) external onlyAdmin {
        ERC20(token).safeTransfer(recipient, amount);
        emit TokenRecovered(recipient, token, amount);
    }
}
