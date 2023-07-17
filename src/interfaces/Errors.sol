// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface MevEthErrors {
    /// Errors
    error BelowMinimum();
    error DepositFailed();
    error InsufficientBufferedEth();
    error TooManyValidatorRegistrations();
    error ExceedsStakingAllowance();
    error StakingPaused();
    error NotEnoughEth();
    error DepositTooLow();
    error ZeroShares();
    error ZeroValue();
    error ReportedBeaconValidatorsGreaterThanTotalValidators();
    error ReportedBeaconValidatorsDecreased();
    error BeaconDepositFailed();
    error InvalidWithdrawalCredentials();
    error OperatorsNotCommitted();
    error OperatorMaxValidatorsReached();
    error OperatorNotCommitted();
    error MaxValidatorError();
    error InvalidOperator();
    error ValidatorPreviouslyRegistered();
    error NotAuthorized();
    error DepositTooSmall();
    error InvalidSender();
    error PrematureStakingModuleUpdateFinalization();
    error PrematureMevEthShareVaultUpdateFinalization();
    error InvalidPendingStakingModule();
    error InvalidPendingMevEthShareVault();
    error TransferExceedsAllowance();
    error TransferFailed();
    error ZeroAddress();
    error AlreadyInitialized();
    error SendError();
    error FeesTooHigh();
    error WrongDepositAmount();
    error UnAuthorizedCaller();
}
