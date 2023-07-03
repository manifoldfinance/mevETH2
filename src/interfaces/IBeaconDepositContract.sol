// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// Interface for the Beacon Chain Deposit Contract
interface IBeaconDepositContract {
    /// @notice Submit a Phase 0 DepositData object.
    /// @param pubkey A BLS12-381 public key.
    /// @param withdrawal_credentials Commitment to a public key for withdrawals.
    /// @param signature A BLS12-381 signature.
    /// @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.

    /// Used as a protection against malformed input.
    function deposit(bytes calldata pubkey, bytes calldata withdrawal_credentials, bytes calldata signature, bytes32 deposit_data_root) external payable;
}
