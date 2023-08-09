# WagyuStaker - Beacon Chain Staking

**Version: 1.0**

## 1. Introduction

The WagyuStaker contract enables the seamless staking of Ether on the Beacon Chain. By directly interfacing with the BeaconChainDepositContract, this contract empowers users to register validators and earn rewards within the Ethereum 2.0 ecosystem.

## 2. Core Functionality

The WagyuStaker contract offers the following key features:

- **Validator Registration**: Users can deposit Ether and initiate the registration of a validator on the Beacon Chain.

- **Oracle Integration**: Updates the contract's balance and validator count based on real-time data from the MevEth contract.

- **Reward Distribution**: Facilitates the distribution of rewards to the MevEth contract, enhancing overall yield opportunities.

- **Token Recovery**: Allows the recovery of mistakenly sent tokens to the contract.

- **Beneficiary Management**: Enables the assignment of a beneficiary address for fund recovery in case of unforeseen issues.

## 3. Contract Details

- **State Variables**:

  - `balance`: The total amount of staked Ether on the Beacon Chain.
  - `beneficiary`: The address designated to manage fund recovery.
  - `validators`: The count of validators registered under this contract.
  - `MEV_ETH`: The address of the MevEth contract.
  - `BEACON_CHAIN_DEPOSIT_CONTRACT`: The address of the BeaconChainDepositContract.

- **Events**:

  - `NewValidator`: Emitted upon successful registration of a new validator, providing key registration data.
  - `TokenRecovered`: Emitted when tokens are recovered from the contract.
  - `RewardsPaid`: Emitted when rewards are distributed to the MevEth contract.
  - `ValidatorWithdraw`: Emitted when funds representing a validator withdrawal are sent to the MevEth contract.
  - `BeneficiaryUpdated`: Emitted when the beneficiary address is updated.

- **Constructor**:
  - Initializes the contract with the addresses of the MevEth contract and BeaconChainDepositContract. Assigns the initial beneficiary as the contract's owner.

## 4. Functionality

- `deposit(IStakingModule.ValidatorData calldata data, bytes32 latestDepositRoot) external payable`: Allows the MevEth contract to initiate validator registration by depositing the required Ether. Validates deposit amount and ensures data integrity before initiating the deposit process.

- `oracleUpdate(uint256 newBalance, uint256 newValidators) external`: Allows the MevEth contract to update the contract's balance and validator count based on oracle data.

- `payRewards() external`: Allows the MevEth contract's operator to distribute rewards to the MevEth contract. In case of error, secures funds to the beneficiary for manual allocation.

- `payValidatorWithdraw(uint256 amount) external`: Enables the admin to distribute MevEth when withdrawing funds from a validator.

- `recoverToken(address token, address recipient, uint256 amount) external`: Allows the admin to recover mistakenly sent tokens to the contract.

- `setNewBeneficiary(address newBeneficiary) external`: Allows the admin to update the beneficiary address for fund recovery.

- `receive() external payable`: Receives Ether sent to the contract.

## 5. Security Considerations

The contract leverages role-based access control to ensure proper authorization for key functions. The ability to recover tokens and set a new beneficiary is restricted to the contract's admin.

## 6. Future Enhancements

The WagyuStaker contract is expected to undergo further development to enhance functionality, improve security, and optimize rewards distribution.
