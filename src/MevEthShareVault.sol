// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import { Auth } from "./libraries/Auth.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { ITinyMevEth } from "./interfaces/ITinyMevEth.sol";
import { IMevEthShareVault } from "./interfaces/IMevEthShareVault.sol";
import { MevEthErrors } from "./interfaces/Errors.sol";

/// @title MevEthShareVault
/// @notice This contract controls the ETH Rewards earned by mevEth
contract MevEthShareVault is Auth, IMevEthShareVault {
    using SafeTransferLib for ERC20;

    struct ProtocolBalance {
        // Accrued fees above the median mev payment
        uint128 fees;
        // Accrued mev payments at or below the median mev payment
        uint128 rewards;
    }

    event RewardPayment(uint256 indexed blockNumber, address indexed coinbase, uint256 indexed amount);
    event RewardsCollected(uint256 indexed protocolFeesOwed, uint256 indexed rewardsOwed);
    event TokenRecovered(address indexed recipient, address indexed token, uint256 indexed amount);
    event ProtocolFeeToUpdated(address indexed newProtocolFeeTo);
    event FeesSent(uint256 indexed feesSent);
    event RewardsPaid(uint256 indexed rewards);
    event BeneficiaryUpdated(address indexed beneficiary);

    error SendError();
    error FeesTooHigh();

    ProtocolBalance protocolBalance;
    address immutable mevEth;
    address public beneficiary;
    address public protocolFeeTo;

    /// @notice Construction sets authority, MevEth, and averageFeeRewardsPerBlock
    /// @param authority The address of the controlling admin authority
    /// @param _mevEth The address of the WETH contract to use for deposits
    /// @param _protocolFeeTo TODO:
    /// @param _beneficiary  TODO:

    constructor(address authority, address _mevEth, address _protocolFeeTo, address _beneficiary) Auth(authority) {
        mevEth = _mevEth;
        protocolFeeTo = _protocolFeeTo;
        beneficiary = _beneficiary;
    }

    function payRewards() external onlyOperator {
        uint256 _rewards = protocolBalance.rewards;

        try ITinyMevEth(mevEth).grantRewards{ value: _rewards }() { }
        catch {
            // Catch the error and send to the admin for further fund recovery
            bool success = payable(beneficiary).send(_rewards);
            if (!success) revert SendError();
        }

        protocolBalance.rewards = 0;

        emit RewardsPaid(_rewards);
    }

    function fees() external view returns (uint128) {
        return protocolBalance.fees;
    }

    function rewards() external view returns (uint128) {
        return protocolBalance.rewards;
    }

    function sendFees() external onlyAdmin {
        uint256 _fees = protocolBalance.fees;

        bool success = payable(protocolFeeTo).send(_fees);
        if (!success) revert SendError();
        protocolBalance.fees = 0;

        emit FeesSent(_fees);
    }

    function setProtocolFeeTo(address newProtocolFeeTo) external onlyAdmin {
        protocolFeeTo = newProtocolFeeTo;
        emit ProtocolFeeToUpdated(newProtocolFeeTo);
    }

    /* @notice Operators are tracking the RewardPayment events to calculate the protocolFeesOwed. 
    
    @dev The logRewards function is then called to update the fees and rewards within the protocol balance.
    Validators associated with the MevETH protocol set the block builder's address as the feeRecepient for the block. 
    The block builder attaches a transaction to the end of the block sending the MEV rewards to the MevEthShareVault. 
    This then emits the RewardPayment event, allowing the offchain operators to track the protocolFeesOwed. 
    This approach trusts that the operators are acting honestly and the protocolFeesOwed is accurately caculated.
    */

    //TODO: think through attack vectors
    function logRewards(uint128 protocolFeesOwed) external onlyOperator {
        ProtocolBalance memory balances = protocolBalance;
        uint256 rewardsEarned = address(this).balance - (balances.fees + protocolBalance.rewards);
        if (protocolFeesOwed > uint128(rewardsEarned)) {
            revert FeesTooHigh();
        }

        uint128 _rewards;
        unchecked {
            _rewards = uint128(rewardsEarned) - protocolFeesOwed;
        }

        protocolBalance.rewards += _rewards;
        protocolBalance.fees += protocolFeesOwed;

        emit RewardsCollected(protocolFeesOwed, rewardsEarned - protocolFeesOwed);
    }

    function logWithdraws(uint256 withdrawsOwed) public {
        //TODO:
    }

    function recoverToken(address token, address recipient, uint256 amount) external onlyAdmin {
        ERC20(token).safeTransfer(recipient, amount);
        emit TokenRecovered(recipient, token, amount);
    }

    function setNewBeneficiary(address newBeneficiary) external onlyAdmin {
        beneficiary = newBeneficiary;
        emit BeneficiaryUpdated(newBeneficiary);
    }

    receive() external payable {
        emit RewardPayment(block.number, block.coinbase, msg.value);
    }
}
