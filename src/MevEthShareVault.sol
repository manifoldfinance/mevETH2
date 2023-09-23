// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import { Auth } from "./libraries/Auth.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { ITinyMevEth } from "./interfaces/ITinyMevEth.sol";
import { IMevEthShareVault } from "./interfaces/IMevEthShareVault.sol";
import { MevEthErrors } from "./interfaces/Errors.sol";

/// @title MevEthShareVault
/// @author Manifold Finance
/// @notice This contract controls the ETH Rewards earned by mevEth

contract MevEthShareVault is Auth, IMevEthShareVault {
    using SafeTransferLib for ERC20;

    /// @notice Struct to account for the protocol fees and rewards.
    /// @custom:field feesPaid      Accrued fees sent to the protocolFeeTo address.
    /// @custom:field rewardsPaid      Accrued rewards sent to the MevEth contract.
    /// @custom:field exitsPaid      Accrued validator exits sent to the MevEth contract.
    /// @custom:field totalWithdrawn      Accrued rewards + exits + fess sent.
    struct ProtocolBalance {
        uint128 feesPaid;
        uint128 rewardsPaid;
        uint128 exitsPaid;
        uint128 totalWithdrawn;
    }

    /// @notice ProtocolBalance struct to account for the protocol fees and rewards.
    ProtocolBalance public protocolBalance;
    /// @notice The address of the MevEth contract.
    address public mevEth;
    /// @notice The address that protocol fees are sent to.
    address public protocolFeeTo;

    /// @notice Event emitted when the protocol balance is updated during logRewards
    event RewardsCollected(uint256 indexed protocolFeesOwed, uint256 indexed rewardsOwed);
    /// @notice Event emitted when a tokens are recovered from the contract.
    event TokenRecovered(address indexed recipient, address indexed token, uint256 indexed amount);
    /// @notice Event emitted when the protocolFeeTo address is updated.
    event ProtocolFeeToUpdated(address indexed newProtocolFeeTo);
    /// @notice Event emitted when the protocol fees are sent to the protocolFeeTo address.
    event FeesSent(uint256 indexed feesSent);
    /// @notice Event emitted when rewards are paid to the MevEth contract.
    event RewardsPaid(uint256 indexed rewards);
    /// @notice Event emitted when the mevEth address is updated.
    event MevEthUpdated(address indexed meveth);
    /// @notice Event emitted when funds representing a validator withdrawal are sent to the MevEth contract.
    event ValidatorWithdraw(address sender, uint256 amount);

    /// @notice Construction sets authority, MevEth, and averageFeeRewardsPerBlock.
    /// @param authority The address of the controlling admin authority.
    /// @param _mevEth The address of the WETH contract to use for deposits.
    /// @param _protocolFeeTo The address that protocol fees are sent to.
    constructor(address authority, address _mevEth, address _protocolFeeTo) Auth(authority) {
        if (_protocolFeeTo == address(0) || authority == address(0) || _mevEth == address(0)) {
            revert MevEthErrors.ZeroAddress();
        }

        mevEth = _mevEth;
        protocolFeeTo = _protocolFeeTo;

        emit MevEthUpdated(_mevEth);
        emit ProtocolFeeToUpdated(_protocolFeeTo);
    }

    /// @notice Function to pay rewards to the MevEth contract
    /// @dev Only callable by an operator.
    /// @param rewards rewards to pay to the MevEth contract
    function payRewards(uint256 rewards) external onlyOperator {
        unchecked {
            protocolBalance.rewardsPaid += uint128(rewards);
            protocolBalance.totalWithdrawn += uint128(rewards);
        }

        // Send the rewards to the MevEth contract
        ITinyMevEth(mevEth).grantRewards{ value: rewards }();

        // Emit an event to track the rewards paid
        emit RewardsPaid(rewards);
    }

    /// @notice Function to collect the fees owed to the prorotocol.
    function sendFees(uint256 fees) external onlyAdmin {
        unchecked {
            protocolBalance.feesPaid += uint128(fees);
            protocolBalance.totalWithdrawn += uint128(fees);
        }

        bool success = payable(protocolFeeTo).send(fees);
        if (!success) revert MevEthErrors.SendError();

        emit FeesSent(fees);
    }

    function setProtocolFeeTo(address newProtocolFeeTo) external onlyAdmin {
        if (newProtocolFeeTo == address(0)) {
            revert MevEthErrors.ZeroAddress();
        }
        protocolFeeTo = newProtocolFeeTo;
        emit ProtocolFeeToUpdated(newProtocolFeeTo);
    }

    /// @notice Function to recover tokens sent to the contract.
    /// @dev This function is only callable by an admin.
    function recoverToken(address token, address recipient, uint256 amount) external onlyAdmin {
        ERC20(token).safeTransfer(recipient, amount);
        emit TokenRecovered(recipient, token, amount);
    }

    /// @notice Function to set a new mevEth address.
    function setNewMevEth(address newMevEth) external onlyAdmin {
        if (newMevEth == address(0)) {
            revert MevEthErrors.ZeroAddress();
        }
        mevEth = newMevEth;
        emit MevEthUpdated(newMevEth);
    }

    /// @notice Function to pay MevEth when withdrawing funds from a validator
    /// @dev This function is only callable by an admin and emits an event for offchain validator registry tracking.
    function payValidatorWithdraw() external onlyOperator {
        uint256 exitSize = 32 ether;
        unchecked {
            protocolBalance.exitsPaid += uint128(exitSize);
            protocolBalance.totalWithdrawn += uint128(exitSize);
        }
        ITinyMevEth(mevEth).grantValidatorWithdraw{ value: exitSize }();
        emit ValidatorWithdraw(msg.sender, exitSize);
    }

    /// @notice Function to receive ETH.
    receive() external payable { }
}
