// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

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
    error UnAuthorizedCaller();
    error WithdrawTooSmall();
    error NotFinalised();
    error AlreadyClaimed();
    error AlreadyFinalised();
    error IndexExceedsQueueLength();
    error DepositWasFrontrun();
}
