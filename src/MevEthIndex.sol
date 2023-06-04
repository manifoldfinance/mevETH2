// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title MevEthIndex
/// @notice This contract is used to store the events, and other data needed for off-chain indexing systems
contract MevEthIndex {
    /// ERC4626 events
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(
        address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );

    event OracleUpdate(uint256 indexed prevBalance, uint256 prevValidators, uint256 newBalance, uint256 newValidators);
    event NewValidator(
        address indexed operator,
        bytes pubkey,
        bytes32 withdrawalCredentials,
        bytes signature,
        bytes32 deposit_data_root
    );
    event RewardsMinted(address indexed rewardsReceiver, uint256 feesAccrued);
    event StakingPaused();
    event StakingUnpaused();
    event FeeSet(uint256 indexed newFee);
    event FeeReceiverSet(address indexed newFeeReciever);
    event WithdrawalCredentialsSet(bytes32 indexed withdrawalCredentials);
    event MevEthSet(address indexed mevEthAddress);
    event OperatorRegistrySet(address indexed operatorRegistry);

    /// Errors
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
}
