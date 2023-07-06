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

    event ValidatorPayment(uint256 indexed blockNumber, address indexed coinbase, uint256 indexed amount);
    event MevPayment(uint256 indexed blockNumber, address indexed coinbase, uint256 indexed amount);
    event TokenRecovered(address indexed recipient, address indexed token, uint256 indexed amount);

    ProtocolBalance protocolBalance;
    address immutable mevEth;
    uint128 medianMevPayment;
    uint128 medianValidatorPayment;
    address feeTo;
    address beneficiary;

    /// @notice Construction sets authority, MevEth, and averageFeeRewardsPerBlock
    /// @param authority The address of the controlling admin authority
    /// @param _mevEth The address of the WETH contract to use for deposits
    /// @param _feeTo TODO:
    /// @param _beneficiary TODO:
    /// @param _medianMevPayment TODO:
    /// @param _medianValidatorPayment TODO:

    constructor(
        address authority,
        address _mevEth,
        address _feeTo,
        address _beneficiary,
        uint128 _medianMevPayment,
        uint128 _medianValidatorPayment
    )
        Auth(authority)
    {
        mevEth = _mevEth;
        medianMevPayment = _medianMevPayment;
        feeTo = _feeTo;
        beneficiary = _beneficiary;
        medianValidatorPayment = _medianValidatorPayment;
    }

    function payRewards() external {
        //TODO: handle failure case and send to admin
        ITinyMevEth(mevEth).grantRewards{ value: protocolBalance.rewards }();
        protocolBalance.rewards = 0;
    }

    function setMedianValidatorPayment(uint128 newMedian) external onlyOperator {
        //TODO: checks prior to updating
        medianValidatorPayment = newMedian;
    }

    function setMedianMevPayment(uint128 newMedian) external onlyOperator {
        //TODO: checks prior to updating
        medianMevPayment = newMedian;
    }

    function sendFees() external onlyAdmin { //TODO:
    }

    function setFeeTo(address newFeeTo) external onlyAdmin {
        if (newFeeTo == address(0)) {
            revert MevEthErrors.ZeroAddress();
        }

        feeTo = newFeeTo;
    }

    function setNewBeneficiary(address _newBeneficiary) external onlyAdmin { }

    function recoverToken(address token, address recipient, uint256 amount) external onlyAdmin {
        ERC20(token).safeTransfer(recipient, amount);
        emit TokenRecovered(recipient, token, amount);
    }

    receive() external payable {
        if (msg.sender == block.coinbase) {
            //TODO: handle as validator payment

            //TODO: emit ValidatorPayment
        } else {
            //TODO: handle as mev payment
            //TODO: emit MevPayment
        }
    }

    fallback() external payable { }
}
