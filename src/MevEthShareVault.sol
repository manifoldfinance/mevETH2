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
    /// @custom:field fees      Accrued fees to be sent to the protocolFeeTo address.
    /// @custom:field rewards      Accrued rewards to be sent to the MevEth contract.
    struct ProtocolBalance {
        uint128 fees;
        uint128 rewards;
    }

    /// @notice ProtocolBalance struct to account for the protocol fees and rewards.
    ProtocolBalance protocolBalance;
    /// @notice The address of the MevEth contract.
    address immutable mevEth;
    /// @notice The address of the beneficiary, used to secure funds in the case of failure while paying out rewards.
    address public beneficiary;
    /// @notice The address that protocol fees are sent to.
    address public protocolFeeTo;

    /// @notice Event emitted when a reward payment is made
    event RewardPayment(uint256 indexed blockNumber, address indexed coinbase, uint256 indexed amount);
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
    /// @notice Event emitted when the beneficiary address is updated.
    event BeneficiaryUpdated(address indexed beneficiary);
    /// @notice Event emitted when funds representing a validator withdrawal are sent to the MevEth contract.
    event ValidatorWithdraw(address sender, uint256 amount);

    /// @notice Construction sets authority, MevEth, and averageFeeRewardsPerBlock.
    /// @param authority The address of the controlling admin authority.
    /// @param _mevEth The address of the WETH contract to use for deposits.
    /// @param _protocolFeeTo The address that protocol fees are sent to.
    /// @param _beneficiary  The address that protocol rewards are secured to in the case of failure while paying rewards.
    constructor(address authority, address _mevEth, address _protocolFeeTo, address _beneficiary) Auth(authority) {
        if (_protocolFeeTo == address(0) || _beneficiary == address(0)) {
            revert MevEthErrors.ZeroAddress();
        }

        mevEth = _mevEth;
        protocolFeeTo = _protocolFeeTo;
        beneficiary = _beneficiary;
    }

    /// @notice Function to pay rewards to the MevEth contract
    /// @dev Only callable by an operator. Additionally, if there is an issue when granting rewards to the MevEth contract, funds are secured to the
    ///      beneficiary address for manual allocation to the MevEth contract.
    function payRewards() external onlyOperator {
        // Cache the rewards balance and update the balance to 0.
        uint256 _rewards = protocolBalance.rewards;
        protocolBalance.rewards = 0;

        // Send the rewards to the MevEth contract
        try ITinyMevEth(mevEth).grantRewards{ value: _rewards }() { }
        catch {
            // Catch the error and send to the admin for further fund recovery
            bool success = payable(beneficiary).send(_rewards);
            if (!success) revert MevEthErrors.SendError();
        }

        // Emit an event to track the rewards paid
        emit RewardsPaid(_rewards);
    }

    /// @notice View function to return the fees balance of the protocol
    /// @return uint128 fees balance of the protocol
    function fees() external view returns (uint128) {
        return protocolBalance.fees;
    }

    /// @notice View function to return the rewards balance of the protocol
    /// @return uint128 rewards balance of the protocol
    function rewards() external view returns (uint128) {
        return protocolBalance.rewards;
    }

    /// @notice Function to collect the fees owed to the prorotocol.
    function sendFees() external onlyAdmin {
        uint256 _fees = protocolBalance.fees;
        protocolBalance.fees = 0;

        bool success = payable(protocolFeeTo).send(_fees);
        if (!success) revert MevEthErrors.SendError();

        emit FeesSent(_fees);
    }

    function setProtocolFeeTo(address newProtocolFeeTo) external onlyAdmin {
        if (newProtocolFeeTo == address(0)) {
            revert MevEthErrors.ZeroAddress();
        }
        protocolFeeTo = newProtocolFeeTo;
        emit ProtocolFeeToUpdated(newProtocolFeeTo);
    }

    /// @notice Function to log rewards, updating the protocol balance. Once all balances are updated, the RewardPayment event is emitted.
    /// @dev Operators are tracking the RewardPayment events to calculate the protocolFeesOwed.
    ///      The logRewards function is then called to update the fees and rewards within the protocol balance.
    ///      Validators associated with the MevETH protocol set the block builder's address as the feeRecepient for the block.
    ///      The block builder attaches a transaction to the end of the block sending the MEV rewards to the MevEthShareVault.
    ///      This then emits the RewardPayment event, allowing the offchain operators to track the protocolFeesOwed.
    ///      This approach trusts that the operators are acting honestly and the protocolFeesOwed is accurately calculated.

    function logRewards(uint128 protocolFeesOwed) external onlyOperator {
        // Cahce the protocol balance
        ProtocolBalance memory balances = protocolBalance;

        // Calculate the rewards earned
        uint256 rewardsEarned = address(this).balance - (balances.fees + balances.rewards);
        if (protocolFeesOwed > uint128(rewardsEarned)) {
            revert MevEthErrors.FeesTooHigh();
        }

        // Calculate the updated protocol reward balance and update the rewards and fees.
        uint128 _rewards;
        unchecked {
            _rewards = uint128(rewardsEarned) - protocolFeesOwed;
        }
        protocolBalance.rewards += _rewards;
        protocolBalance.fees += protocolFeesOwed;

        emit RewardsCollected(protocolFeesOwed, rewardsEarned - protocolFeesOwed);
    }

    /// @notice Function to recover tokens sent to the contract.
    /// @dev This function is only callable by an admin.
    function recoverToken(address token, address recipient, uint256 amount) external onlyAdmin {
        ERC20(token).safeTransfer(recipient, amount);
        emit TokenRecovered(recipient, token, amount);
    }

    /// @notice Function to set a new beneficiary address.
    /// @dev The beneficiary is used to recover funds if needed.
    function setNewBeneficiary(address newBeneficiary) external onlyAdmin {
        if (newBeneficiary == address(0)) {
            revert MevEthErrors.ZeroAddress();
        }
        beneficiary = newBeneficiary;
        emit BeneficiaryUpdated(newBeneficiary);
    }

    /// @notice Function to pay MevEth when withdrawing funds from a validator
    /// @dev This function is only callable by an admin and emits an event for offchain validator registry tracking.
    function payValidatorWithdraw(uint128 amount) external onlyAdmin {
        ITinyMevEth(mevEth).grantValidatorWithdraw{ value: amount }();
        emit ValidatorWithdraw(msg.sender, amount);
    }

    /// @notice Function to receive ETH.
    /// @dev All Ether sent to the contract is handled as a MevPayment.
    receive() external payable {
        emit RewardPayment(block.number, block.coinbase, msg.value);
    }
}
