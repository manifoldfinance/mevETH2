// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import { ITinyMevEth } from "./interfaces/ITinyMevEth.sol";
import { IStakingModule } from "./interfaces/IStakingModule.sol";
import { IBeaconDepositContract } from "./interfaces/IBeaconDepositContract.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { Auth } from "./libraries/Auth.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { MevEthErrors } from "./interfaces/Errors.sol";

/// @title 🥩 Wagyu Staker 🥩
/// @dev This contract stakes Ether inside of the BeaconChainDepositContract directly
contract WagyuStaker is Auth, IStakingModule {
    using SafeTransferLib for ERC20;

    // The amount of staked Ether on the beaconchain
    uint256 public balance;

    //TODO:
    address public beneficiary;

    // The number of 32 validators on the consensus layer registered under this contract
    uint256 public validators;

    // The address of the MevEth contract
    address public immutable MEV_ETH;

    // Validator deposit size
    uint256 public constant override VALIDATOR_DEPOSIT_SIZE = 32 ether;

    // The Canonical Address of the BeaconChainDepositContract
    IBeaconDepositContract public immutable BEACON_CHAIN_DEPOSIT_CONTRACT;

    event NewValidator(address indexed operator, bytes pubkey, bytes32 withdrawalCredentials, bytes signature, bytes32 deposit_data_root);
    event TokenRecovered(address indexed recipient, address indexed token, uint256 indexed amount);
    event BeneficiaryUpdated(address indexed beneficiary);
    event RewardsPaid(uint256 indexed amount);

    /// @notice Construction sets authority, MevEth, and deposit contract addresses
    /// @param _authority The address of the controlling admin authority
    /// @param _depositContract The address of the WETH contract to use for deposits
    /// @param _mevEth The address of the WETH contract to use for deposits
    constructor(address _authority, address _depositContract, address _mevEth) Auth(_authority) {
        MEV_ETH = _mevEth;
        BEACON_CHAIN_DEPOSIT_CONTRACT = IBeaconDepositContract(_depositContract);
        beneficiary = _authority;
    }

    function deposit(IStakingModule.ValidatorData calldata data) external payable {
        if (msg.sender != MEV_ETH) {
            revert MevEthErrors.UnAuthorizedCaller();
        }
        if (msg.value != VALIDATOR_DEPOSIT_SIZE) {
            revert MevEthErrors.WrongDepositAmount();
        }
        unchecked {
            balance += VALIDATOR_DEPOSIT_SIZE;
            validators += 1;
        }

        BEACON_CHAIN_DEPOSIT_CONTRACT.deposit{ value: VALIDATOR_DEPOSIT_SIZE }(
            data.pubkey, abi.encodePacked(data.withdrawal_credentials), data.signature, data.deposit_data_root
        );

        emit NewValidator(data.operator, data.pubkey, data.withdrawal_credentials, data.signature, data.deposit_data_root);
    }

    function oracleUpdate(uint256 newBalance, uint256 newValidators) external {
        if (msg.sender != MEV_ETH) {
            revert MevEthErrors.UnAuthorizedCaller();
        }

        balance = newBalance;
        validators = newValidators;
    }

    function payRewards() external onlyOperator {
        uint256 _rewards = address(this).balance - balance;

        try ITinyMevEth(MEV_ETH).grantRewards{ value: _rewards }() { }
        catch {
            // Catch the error and send to the admin for further fund recovery
            bool success = payable(beneficiary).send(_rewards);
            if (!success) revert MevEthErrors.SendError();
        }

        emit RewardsPaid(_rewards);
    }

    function payValidatorWithdraw(uint256 amount) external onlyAdmin {
        ITinyMevEth(MEV_ETH).grantValidatorWithdraw{ value: amount }();
    }

    function recoverToken(address token, address recipient, uint256 amount) external onlyAdmin {
        ERC20(token).safeTransfer(recipient, amount);
        emit TokenRecovered(recipient, token, amount);
    }

    function setNewBeneficiary(address newBeneficiary) external onlyAdmin {
        beneficiary = newBeneficiary;
        emit BeneficiaryUpdated(newBeneficiary);
    }

    receive() external payable { }

    fallback() external payable { }
}
