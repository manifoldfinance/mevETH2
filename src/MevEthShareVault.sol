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
    uint256  feePercent; //TODO: this is the percent applied to payments over the median to accrue fees //TODO: consider making this packed if efficient

    /// @notice Construction sets authority, MevEth, and averageFeeRewardsPerBlock
    /// @param authority The address of the controlling admin authority
    /// @param _mevEth The address of the WETH contract to use for deposits
    /// @param _feeTo TODO:
    /// @param _beneficiary TODO:
    /// @param _medianMevPayment TODO:
    /// @param _medianValidatorPayment TODO:
    /// @param _feePercent TODO:

    constructor(
        address authority,
        address _mevEth,
        address _feeTo,
        address _beneficiary,
        uint128 _medianMevPayment,
        uint128 _medianValidatorPayment,
        uint256 _feePercent
    )
        Auth(authority)
    {
        mevEth = _mevEth;
        medianMevPayment = _medianMevPayment;
        feeTo = _feeTo;
        beneficiary = _beneficiary;
        medianValidatorPayment = _medianValidatorPayment;
        feePercent = _feePercent;
    }

    function payRewards() external onlyOperator {
        //TODO: handle failure case and send to admin
        //TODO: handle medians have not been updated yet
        ITinyMevEth(mevEth).grantRewards{ value: protocolBalance.rewards }();
        protocolBalance.rewards = 0;
    }



    function setMedianValidatorPayment(uint128 newMedian) external onlyOperator {
        medianValidatorPayment = newMedian;
    }

    function setMedianMevPayment(uint128 newMedian) external onlyOperator {
        medianMevPayment = newMedian;
    }

    function fees() external view returns (uint256) {
        return protocolBalance.fees;
    }

    function rewards() external view returns (uint256) {
        return protocolBalance.rewards;
    }

    function sendFees() external onlyAdmin { 
        
        //TODO:
    }

    function setFeeTo(address newFeeTo) external onlyAdmin {
        if (newFeeTo == address(0)) {
            revert MevEthErrors.ZeroAddress();
        }

        feeTo = newFeeTo;
    }

    function updateFeePercent(uint256 newFeePercent) external onlyAdmin{
        feePercent = newFeePercent;
    }

    function setNewBeneficiary(address _newBeneficiary) external onlyAdmin { }

    function recoverToken(address token, address recipient, uint256 amount) external onlyAdmin {
        ERC20(token).safeTransfer(recipient, amount);
        emit TokenRecovered(recipient, token, amount);
    }
    


    //TODO: write strong tests to ensure that the receive function is always being called when sending ether to the contract, otherwise the contract should revert

    receive() external payable {




        //TODO: check the balance of the contract against the rewards + fees. Any gaps should be considered assumed validator payments
        

        //TODO: if asp > 0 handle assumed validator payments, anything above the median should have the fee applied
        // NOTE: anything above the median, a percent is allocated to the fees, the rest is the rewards

        //TODO: emit AssumedValidatorPayment;

        //TODO: handle the msg.value as a mev payment
        //TODO: emit MevPayment

    }


    //TODO: remove this?
    fallback() external payable { }
}
