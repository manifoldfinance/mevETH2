# MevEthShareVault - Reward Management

**Version: 1.0**

## 1. Introduction

The MevEthShareVault contract plays a vital role in the MevEth ecosystem, managing and distributing ETH rewards earned through the protocol. As a core component, this contract ensures accurate accounting and secure distribution of protocol fees and rewards.

## 2. Core Functionality

The MevEthShareVault contract provides essential features for efficient reward management:

- **Reward Distribution**: Facilitates the distribution of rewards to the MevEth contract, ensuring accurate calculations and secure transfers.

- **Protocol Fee Management**: Manages the collection and secure transfer of protocol fees.

- **Beneficiary Assignment**: Allows the assignment of a beneficiary address to safeguard rewards in case of payout failures.

- **Token Recovery**: Enables the recovery of mistakenly sent tokens to the contract.

## 3. Contract Details

- **Structs**:

  - `ProtocolBalance`: Represents the protocol's fee and reward balances.

- **State Variables**:

  - `protocolBalance`: Holds the accrued protocol fees and rewards.
  - `mevEth`: The address of the MevEth contract.
  - `beneficiary`: The address designated to manage fund recovery in case of payout failures.
  - `protocolFeeTo`: The address to which protocol fees are sent.

- **Events**:

  - `RewardPayment`: Emitted when rewards are received, providing block information and reward amount.
  - `RewardsCollected`: Emitted when protocol balances are updated during reward logging.
  - `TokenRecovered`: Emitted when tokens are recovered from the contract.
  - `ProtocolFeeToUpdated`: Emitted when the protocolFeeTo address is updated.
  - `FeesSent`: Emitted when protocol fees are sent to the protocolFeeTo address.
  - `RewardsPaid`: Emitted when rewards are distributed to the MevEth contract.
  - `BeneficiaryUpdated`: Emitted when the beneficiary address is updated.
  - `ValidatorWithdraw`: Emitted when funds representing a validator withdrawal are sent to the MevEth contract.

- **Constructor**:
  - Initializes the contract with essential addresses: MevEth contract, protocol fee recipient, and beneficiary.

## 4. Functionality

- `payRewards() external`: Allows an operator to distribute rewards to the MevEth contract. In case of error, funds are secured to the beneficiary for manual allocation.

- `fees() external view returns (uint128)`: Returns the protocol's fee balance.

- `rewards() external view returns (uint128)`: Returns the protocol's reward balance.

- `sendFees() external`: Allows an admin to send protocol fees to the designated recipient.

- `setProtocolFeeTo(address newProtocolFeeTo) external`: Allows an admin to update the protocol fee recipient address.

- `logRewards(uint128 protocolFeesOwed) external`: Logs rewards, updating protocol balances. Trusted operators monitor RewardPayment events to calculate protocol fees owed.

- `recoverToken(address token, address recipient, uint256 amount) external`: Allows an admin to recover tokens sent to the contract.

- `setNewBeneficiary(address newBeneficiary) external`: Allows an admin to update the beneficiary address.

- `payValidatorWithdraw(uint128 amount) external`: Allows an admin to pay MevEth when withdrawing funds from a validator.

- `receive() external payable`: Receives ETH as MevPayments, emitting RewardPayment events.

## 5. Security Considerations

Role-based access control ensures authorized access to critical functions. The beneficiary safeguard enhances fund recovery in case of payout failures.

## 6. Future Enhancements

The MevEthShareVault contract is poised for continuous development to refine functionality, bolster security, and optimize reward distribution.
