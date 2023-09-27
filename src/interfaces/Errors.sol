/// SPDX-License-Identifier: SSPL-1.-0

/**
 * @custom:org.protocol='mevETH LST Protocol'
 * @custom:org.security='mailto:security@manifoldfinance.com'
 * @custom:org.vcs-commit=$GIT_COMMIT_SHA
 * @custom:org.vendor='CommodityStream, Inc'
 * @custom:org.schema-version="1.0"
 * @custom.org.encryption="manifoldfinance.com/.well-known/pgp-key.asc"
 * @custom:org.preferred-languages="en"
 */

pragma solidity ^0.8.19;

interface MevEthErrors {
    /// Errors
    error StakingPaused();
    error NotEnoughEth();
    error ZeroValue();
    error InvalidOperator();
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
    error WrongWithdrawAmount();
    error UnAuthorizedCaller();
    error WithdrawTooSmall();
    error NotFinalised();
    error AlreadyClaimed();
    error AlreadyFinalised();
    error IndexExceedsQueueLength();
    error DepositWasFrontrun();
    error SandwichProtection();
    error NonZeroVaultBalance();
    error AlreadyDeposited();
    error IncorrectWithdrawalCredentials();
}
