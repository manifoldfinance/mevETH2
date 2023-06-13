// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

import { IStakingModule } from "./interfaces/IStakingModule.sol";

/// Interface for the Beacon Chain Deposit Contract
interface IBeaconDepositContract {
    /// @notice Submit a Phase 0 DepositData object.
    /// @param pubkey A BLS12-381 public key.
    /// @param withdrawal_credentials Commitment to a public key for withdrawals.
    /// @param signature A BLS12-381 signature.
    /// @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.

    /// Used as a protection against malformed input.
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;
}


/// @title 🥩 Wagyu Staker 🥩
/// @dev This contract stakes Ether inside of the BeaconChainDepositContract directly
contract WagyuStaker is IStakingModule {

    error WrongDepositAmount();
    error UnAuthorizedCaller();


    // The amount of staked Ether on the beaconchain    
    uint256 public balance;

    // The number of 32 validators on the consensus layer registered under this contract
    uint256 public validators;

    // The address of the MevEth contract
    address public immutable mevEth;

    // Validator deposit size
    uint256 public constant override validatorDepositSize = 32 ether;

    // The Canonical Address of the BeaconChainDepositContract
    IBeaconDepositContract immutable public BEACON_CHAIN_DEPOSIT_CONTRACT;

    event NewValidator(
        address indexed operator,
        bytes pubkey,
        bytes32 withdrawalCredentials,
        bytes signature,
        bytes32 deposit_data_root
    );

    constructor(address depositContract, address _mevEth) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        IBeaconDepositContract _BEACON_CHAIN_DEPOSIT_CONTRACT; 
        if (chainId != 1) {
            _BEACON_CHAIN_DEPOSIT_CONTRACT = IBeaconDepositContract(0x00000000219ab540356cBB839Cbe05303d7705Fa);
        } else {
            _BEACON_CHAIN_DEPOSIT_CONTRACT = IBeaconDepositContract(depositContract);
        }

        mevEth = _mevEth;
        BEACON_CHAIN_DEPOSIT_CONTRACT = _BEACON_CHAIN_DEPOSIT_CONTRACT;
    }

    function deposit(IStakingModule.ValidatorData calldata _data) external payable {
        if (msg.sender != mevEth) {
            revert UnAuthorizedCaller();
        }
        if (msg.value != 32 ether) {
            revert WrongDepositAmount();
        }

        BEACON_CHAIN_DEPOSIT_CONTRACT.deposit{value: 32 ether}(
            _data.pubkey,
            abi.encodePacked(_data.withdrawal_credentials),
            _data.signature,
            _data.deposit_data_root
        );

        emit NewValidator(
            _data.operator,
            _data.pubkey,
            _data.withdrawal_credentials,
            _data.signature,
            _data.deposit_data_root
        );

        balance += 32 ether;

        validators += 1;
    }

    function oracleUpdate(uint256 newBalance, uint256 newValidators) external {
        if (msg.sender != mevEth) {
            revert UnAuthorizedCaller();
        }

        balance = newBalance;
        validators = newValidators;        
    }
}