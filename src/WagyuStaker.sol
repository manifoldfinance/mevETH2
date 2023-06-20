// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

import { ITinyMevEth } from "./interfaces/ITinyMevEth.sol";
import { IStakingModule } from "./interfaces/IStakingModule.sol";
import { IBeaconDepositContract } from "./interfaces/IBeaconDepositContract.sol";

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
    address public immutable MEV_ETH;

    // Validator deposit size
    uint256 public constant override VALIDATOR_DEPOSIT_SIZE = 32 ether;

    // The Canonical Address of the BeaconChainDepositContract
    IBeaconDepositContract public immutable BEACON_CHAIN_DEPOSIT_CONTRACT;

    event NewValidator(address indexed operator, bytes pubkey, bytes32 withdrawalCredentials, bytes signature, bytes32 deposit_data_root);

    constructor(address depositContract, address mevEth) {
        MEV_ETH = mevEth;
        BEACON_CHAIN_DEPOSIT_CONTRACT = IBeaconDepositContract(depositContract);
    }

    function deposit(IStakingModule.ValidatorData calldata data) external payable {
        if (msg.sender != MEV_ETH) {
            revert UnAuthorizedCaller();
        }
        if (msg.value != VALIDATOR_DEPOSIT_SIZE) {
            revert WrongDepositAmount();
        }

        balance += VALIDATOR_DEPOSIT_SIZE;

        validators += 1;

        BEACON_CHAIN_DEPOSIT_CONTRACT.deposit{ value: VALIDATOR_DEPOSIT_SIZE }(
            data.pubkey, abi.encodePacked(data.withdrawal_credentials), data.signature, data.deposit_data_root
        );

        emit NewValidator(data.operator, data.pubkey, data.withdrawal_credentials, data.signature, data.deposit_data_root);
    }

    function oracleUpdate(uint256 newBalance, uint256 newValidators) external {
        if (msg.sender != MEV_ETH) {
            revert UnAuthorizedCaller();
        }

        balance = newBalance;
        validators = newValidators;
    }

    // TODO: permission check
    function payValidatorWithdraw(uint256 amount) external {
        ITinyMevEth(MEV_ETH).grantValidatorWithdraw{ value: amount }();
    }

    receive() external payable { }

    fallback() external payable { }
}
