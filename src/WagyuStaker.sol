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

    struct Record {
        uint128 totalDeposited;
        uint128 totalWithdrawn;
        uint128 totalRewardsPaid;
        uint128 totalValidatorExitsPaid;
    }

    /// @notice Record of total deposits, withdraws, rewards paid and validators exited
    Record public record;
    /// @notice The number of validators on the consensus layer registered under this contract
    uint256 public validators;
    /// @notice The address of the MevEth contract
    address public mevEth;
    /// @notice Validator deposit size.
    uint256 public constant override VALIDATOR_DEPOSIT_SIZE = 32 ether;
    /// @notice The Canonical Address of the BeaconChainDepositContract
    IBeaconDepositContract public immutable BEACON_CHAIN_DEPOSIT_CONTRACT;

    /// @notice Event emitted when a validator is registered
    event NewValidator(address indexed operator, bytes pubkey, bytes32 withdrawalCredentials, bytes signature, bytes32 deposit_data_root);
    /// @notice Event emitted when tokens are recovered from the contract.
    event TokenRecovered(address indexed recipient, address indexed token, uint256 indexed amount);
    /// @notice Event emitted when rewards are paid to the MevEth contract.
    event RewardsPaid(uint256 indexed amount);
    /// @notice Event emitted when funds representing a validator withdrawal are sent to the MevEth contract.
    event ValidatorWithdraw(address sender, uint256 amount);
    /// @notice Event emitted when the mevEth address is updated.
    event MevEthUpdated(address indexed meveth);

    /// @notice Construction sets authority, MevEth, and deposit contract addresses
    /// @param _authority The address of the controlling admin authority
    /// @param _depositContract The address of the beacon deposit contract
    /// @param _mevEth The address of the mevETH contract
    constructor(address _authority, address _depositContract, address _mevEth) Auth(_authority) {
        mevEth = _mevEth;
        BEACON_CHAIN_DEPOSIT_CONTRACT = IBeaconDepositContract(_depositContract);
    }

    /// @notice Function to deposit funds into the BEACON_CHAIN_DEPOSIT_CONTRACT, and register a validator
    function deposit(IStakingModule.ValidatorData calldata data, bytes32 latestDepositRoot) external payable {
        // Only the MevEth contract can call this function
        if (msg.sender != mevEth) {
            revert MevEthErrors.UnAuthorizedCaller();
        }
        // Ensure the deposit amount is equal to the VALIDATOR_DEPOSIT_SIZE
        if (msg.value != VALIDATOR_DEPOSIT_SIZE) {
            revert MevEthErrors.WrongDepositAmount();
        }
        if (BEACON_CHAIN_DEPOSIT_CONTRACT.get_deposit_root() != latestDepositRoot) {
            revert MevEthErrors.DepositWasFrontrun();
        }

        // Update the contract balance and validator count
        unchecked {
            record.totalDeposited += uint128(VALIDATOR_DEPOSIT_SIZE);
            validators += 1;
        }

        // Deposit the funds into the BeaconChainDepositContract
        BEACON_CHAIN_DEPOSIT_CONTRACT.deposit{ value: VALIDATOR_DEPOSIT_SIZE }(
            data.pubkey, abi.encodePacked(data.withdrawal_credentials), data.signature, data.deposit_data_root
        );

        // Emit an event inidicating a new validator has been registered, allowing for offchain listeners to track the validator registry
        emit NewValidator(data.operator, data.pubkey, data.withdrawal_credentials, data.signature, data.deposit_data_root);
    }

    /// @notice Function to pay rewards to the MevEth contract
    /// @dev Only callable by an operator
    /// @param rewards rewards to pay to the MevEth contract
    function payRewards(uint256 rewards) external onlyOperator {
        if (rewards > address(this).balance) revert MevEthErrors.NotEnoughEth();

        unchecked {
            record.totalRewardsPaid += uint128(rewards);
            // lagging withdrawn indicator, as including in receive can cause transfer out of gas
            record.totalWithdrawn += uint128(rewards);
        }

        // Send the rewards to the MevEth contract
        ITinyMevEth(mevEth).grantRewards{ value: rewards }();

        // Emit an event to track the rewards paid
        emit RewardsPaid(rewards);
    }

    function registerExit() external {
        // Only the MevEth contract can call this function
        if (msg.sender != mevEth) {
            revert MevEthErrors.UnAuthorizedCaller();
        }
        uint128 exitSize = uint128(VALIDATOR_DEPOSIT_SIZE);
        unchecked {
            record.totalValidatorExitsPaid += exitSize;
            // lagging withdrawn indicator, as including in receive can cause transfer out of gas
            record.totalWithdrawn += exitSize;
        }
        if (validators > 0) {
            unchecked {
                validators -= 1;
            }
        }
    }

    /// @notice Function to pay MevEth when withdrawing funds from a validator
    /// @dev This function is only callable by an operator and emits an event for offchain validator registry tracking.
    function payValidatorWithdraw() external onlyOperator {
        uint256 exitSize = VALIDATOR_DEPOSIT_SIZE;
        if (exitSize > address(this).balance) revert MevEthErrors.NotEnoughEth();
        ITinyMevEth(mevEth).grantValidatorWithdraw{ value: exitSize }();
        emit ValidatorWithdraw(msg.sender, exitSize);
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

    /// @notice Batch register Validators for migration
    /// @dev only Admin
    /// @param batchData list of each validators' data struct
    function batchMigrate(IStakingModule.ValidatorData[] calldata batchData) external onlyAdmin {
        uint256 length = batchData.length;
        // Update the contract balance and validator count
        unchecked {
            record.totalDeposited += uint128(length * VALIDATOR_DEPOSIT_SIZE);
            validators += length;
        }
        for (uint256 i = 0; i < length;) {
            IStakingModule.ValidatorData memory data = batchData[i];
            // Emit an event inidicating a new validator has been registered, allowing for offchain listeners to track the validator registry
            emit NewValidator(data.operator, data.pubkey, data.withdrawal_credentials, data.signature, data.deposit_data_root);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Function to receive Ether
    receive() external payable { }
}
