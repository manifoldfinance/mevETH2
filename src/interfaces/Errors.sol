pragma solidity 0.8.20;

interface MevEthErrors {
    /// Errors
    error DepositFailed();
    error InsufficientBufferedEth();
    error TooManyValidatorRegistrations();
    error ExceedsStakingAllowance();
    error StakingPaused();
    error NotEnoughEth();
    error DepositTooLow();
    error ZeroShares();
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
    error PrematureStakingModuleUpdateFinalization(uint64 finalizationTimestamp, uint64 currentTimestamp);
    error InvalidPendingStakingModule();
    error TransferExceedsAllowance();
    error TransferFailed();
}
