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

    event AssumedValidatorPayment(uint256 indexed blockNumber, address indexed coinbase, uint256 indexed amount);
    event MevPayment(uint256 indexed blockNumber, address indexed coinbase, uint256 indexed amount);
    event TokenRecovered(address indexed recipient, address indexed token, uint256 indexed amount);

    error DataNotUpdated();
    error FeesToHigh();

    ProtocolBalance protocolBalance;
    address immutable mevEth;
    uint128 medianMevPayment;
    uint128 medianValidatorPayment;
    address protocolFeeTo;
    uint256 dataLastUpdated;
    uint256 feePercent; //TODO: this is the percent applied to payments over the median to accrue fees

    /// @notice Construction sets authority, MevEth, and averageFeeRewardsPerBlock
    /// @param authority The address of the controlling admin authority
    /// @param _mevEth The address of the WETH contract to use for deposits
    /// @param _protocolFeeTo The address which should recieve protocol fees
    /// @param _medianMevPayment Initial expected mev payment
    /// @param _feePercent The percent of which revenues above the median should be taken as fees

    constructor(
        address authority,
        address _mevEth,
        address _protocolFeeTo,
        address _beneficiary,
        uint128 _medianMevPayment,
        uint256 _feePercent
    )
        Auth(authority)
    {
        mevEth = _mevEth;
        medianMevPayment = _medianMevPayment;
        protocolFeeTo = _protocolFeeTo;
        beneficiary = _beneficiary;
        medianValidatorPayment = _medianValidatorPayment;
        feePercent = _feePercent;
        dataLastUpdated = block.number;
    }

    function payRewards() external onlyOperator {
        if (dataLastUpdated != block.number) {
            revert DataNotUpdated();
        }
        try ITinyMevEth(mevEth).grantRewards{ value: protocolBalance.rewards }() { }
        catch {
            // Catch the error and send to the admin for further fund recovery
            payable(admin).send(protocolBalance.rewards);
        }
        protocolBalance.rewards = 0;
    }

    function setMedianMevPayment(uint128 newMedian) external onlyOperator {
        dataLastUpdated = block.number;
        medianMevPayment = newMedian;
    }

    function fees() external view returns (uint256) {
        return protocolBalance.fees;
    }

    function rewards() external view returns (uint256) {
        return protocolBalance.rewards;
    }

    function sendFees() external onlyAdmin {
        require(protocolFeeTo.send(protocolBalance.fees), "fee payout failed");
        protocolBalance.fees = 0;
    }

    function setFeeTo(address newFeeTo) external onlyAdmin {
        feeTo = newFeeTo;
    }

    function updateFeePercent(uint256 newFeePercent) external onlyAdmin {
        feePercent = newFeePercent;
    }

    function logValidatorRewards(uint256 protocolFeesOwed) external onlyOperator {
        // See https://twitter.com/_prestwich/status/1678082879765766144 for further explanation
        // but essentially validator rewards accrue on CL, then can be sent over as a type of withdrawal, but avoid
        // the fallback function, and just add straight to account balance, so we require an external operator to trigger this,
        // then call this function to log the payment, however, because frequent withdrawals may not be possible or prudent, we rely on
        // off-chain logic to correctly measure fees, fun fact: You can manipulate the value of validator rewards via SENDALL / SELFDESCTRUCT
        // but because we are tracking this balance off chain, and it in essence just means you can donate money on behalf of the protocl, its
        // stricty a non issue
        ProtocolBalance balances = protocolBalance;
        // Since validator payment skips the fallback, we can assume all unaccounted for eth is from the CL withdrawal
        uint256 rewardsEarned = address(this).balance - (balances.fees + protocolBalance.rewards);
        if (protocolFeesOwed > rewardsEarned) {
            revert FeesToHigh();
        }
        emit AssumedValidatorPayment(block.number, block.coinbase, rewardsEarned);
        protocolBalance.rewards += (rewardsEarned - protocolFeesOwed);
        protocolFeesOwed += protocolFeesOwed;
    }

    function recoverToken(address token, address recipient, uint256 amount) external onlyAdmin {
        ERC20(token).safeTransfer(recipient, amount);
        emit TokenRecovered(recipient, token, amount);
    }

    receive() external payable {
        emit MevPayment(block.number, block.coinbase, msg.value);
        protocolBalance.rewards += msg.value;
    }
}
