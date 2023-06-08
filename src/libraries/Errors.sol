pragma solidity 0.8.20;

library MevEthErrors {
    /// Errors
    error DepositFailed();
    error InsufficientBufferedEth();
    error TooManyValidatorRegistrations();
    error ExceedsStakingAllowance();
    error StakingIsPaused();
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
}