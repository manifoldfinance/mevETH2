# MevEth - Maximizing Ethereum Value

**Version: 1.0**

## 1. Introduction

The `MevEth` contract serves as a sophisticated platform for Liquid Staking Receipt (LSR) management, designed to optimize Ethereum value through efficient staking and reward distribution. This contract leverages multiple core modules to achieve its objectives, including admin control, staking management, share vault updates, ERC4626 integration, withdrawal queues and omni-chain tokens.

- [Documentation for staking management contract](wagyu.md)
- [Documentation for reward management contract](share-vault.md)

## 2. Core Modules and Functionality

The `MevEth` contract comprises several core modules, each contributing to its comprehensive functionality:

- **Accounting**: Transparent fractional accounting system
- **Admin Control Panel**: Empowers administrators with control over staking, module updates, and share vault management.
- **Staking Management**: Allows efficient staking of Ether in the Beacon Chain, ensuring validators' registration and interaction with the staking module.
- **Share Vault Updates**: Facilitates seamless updates to the MevEth share vault, ensuring accurate reward distribution and protocol management.
- **ERC4626 Integration**: Supports ERC4626 interface for yield source integration, enabling compatibility with Yearn Vault and other protocols.
- **Role management**: Supports roles management
- **Withdrawal Queues**: First come, first served queues for withdrawal requests beyond buffer balances
- **Omni-chain fungible tokens**: Allows `MevEth` tokens to be sent accross chains

## 3. Contract Details

### Accounting

The `MevEth` contract includes various accounting features that help track and manage the assets, shares, and fractions associated with the protocol. These accounting mechanisms ensure accurate calculations and maintain the integrity of the contract's financial operations.

The contract uses a fractional representation called "elastic" and "base" to maintain the relationship between assets and shares. These fractions are used to calculate the conversion between assets and shares, ensuring consistency and accuracy.

- **Elastic**: The elastic fraction represents the total amount of assets controlled by the contract. It increases when assets are deposited and decreases when assets are withdrawn.

- **Base**: The base fraction represents the total number of shares issued by the contract. It increases when shares are minted and decreases when shares are burned.

### Admin Control Panel

- **Events**:

  - `MevEthInitialized`: Emitted upon successful initialization of the `MevEth` contract.
  - `StakingPaused`, `StakingUnpaused`: Emitted when staking is paused or unpaused.
  - `StakingModuleUpdateCommitted`, `StakingModuleUpdateFinalized`, `StakingModuleUpdateCanceled`: Emitted during staking module updates.
  - `MevEthShareVaultUpdateCommitted`, `MevEthShareVaultUpdateFinalized`, `MevEthShareVaultUpdateCanceled`: Emitted during MevEth share vault updates.

- **Functions**:
  - `init(address initialShareVault, address initialStakingModule) external`: Initializes the contract with the share vault and staking module addresses.
  - `pauseStaking()`, `unpauseStaking()`: Pauses or unpauses staking operations.
  - `commitUpdateStakingModule(IStakingModule newModule)`, `finalizeUpdateStakingModule()`, `cancelUpdateStakingModule()`: Manages staking module updates.
  - `commitUpdateMevEthShareVault(address newMevEthShareVault)`, `finalizeUpdateMevEthShareVault()`, `cancelUpdateMevEthShareVault()`: Manages MevEth share vault updates.

### Staking Management

- **Events**:

  - `NewValidator`: Emitted upon successful registration of a new validator.
  - `TokenRecovered`: Emitted when tokens are recovered from the contract.
  - `RewardsPaid`, `ValidatorWithdraw`: Emitted during reward payments and validator withdrawals.

- **Functions**:
  - `deposit(IStakingModule.ValidatorData calldata data, bytes32 latestDepositRoot) external payable`: Deposits Ether and registers a validator.
  - `oracleUpdate(uint256 newBalance, uint256 newValidators) external`: Updates balance and validator count.
  - `payRewards() external`: Distributes rewards to the `MevEth` contract.
  - `payValidatorWithdraw(uint256 amount)`, `recoverToken(address token, address recipient, uint256 amount)`: Token and Ether management functions.

### Share Vault Updates

- **Events**:

  - `RewardPayment`: Emitted when rewards are received.
  - `RewardsCollected`, `TokenRecovered`, `ProtocolFeeToUpdated`, `FeesSent`, `RewardsPaid`, `BeneficiaryUpdated`, `ValidatorWithdraw`: Emitted during reward distribution and protocol management.

- **Functions**:
  - `payRewards()`, `fees()`, `rewards()`, `sendFees()`, `setProtocolFeeTo(address newProtocolFeeTo)`: Manages reward distribution and protocol fees.
  - `logRewards(uint128 protocolFeesOwed)`, `setNewBeneficiary(address newBeneficiary)`: Logs rewards, updates balances, and manages beneficiary.
  - `recoverToken(address token, address recipient, uint256 amount)`, `payValidatorWithdraw(uint128 amount)`: Token and Ether management functions.

### ERC4626 Integration

- **Functions**:
  - `asset()` Returns the address of the underlying asset token of the `MevEth` contract.
  - `totalAssets()` Returns the total amount of assets controlled by the `MevEth` contract.
  - `convertToShares(uint256 assets)` Converts a specified amount of assets to shares based on the elastic and base parameters.
  - `convertToAssets(uint256 shares)` Converts a specified amount of shares to assets based on the elastic and base parameters.
  - `maxDeposit(address)` Indicates the maximum deposit possible for Omni-Chain Fungible Tokens (OFT).
  - `previewDeposit(uint256 assets)` Simulates the amount of shares that would be minted for a given deposit at the current ratio.
  - `deposit(uint256 assets, address receiver)` Deposits Omni-Chain Fungible Tokens (OFT) into the `MevEth` contract, converting assets to shares and minting shares to the receiver.
  - `maxMint(address)` Indicates the maximum amount of shares that can be minted at the current ratio.
  - `previewMint(uint256 shares)` Simulates the amount of assets that would be required to mint a given amount of shares at the current ratio.
  - `mint(uint256 shares, address receiver)` Mints shares of the `MevEth` contract, converting shares to assets and depositing assets while minting shares to the receiver.
  - `maxWithdraw(address owner)` Indicates the maximum amount of assets that can be withdrawn at the current state.
  - `previewWithdraw(uint256 assets)` Simulates the amount of shares that would be allocated for a specified amount of assets.
  - `withdraw(uint256 assets, address receiver, address owner)` Withdraws assets from the `MevEth` contract, burning shares and transferring assets to the receiver.
  - `maxRedeem(address owner)` Simulates the maximum amount of shares that can be redeemed by the owner.
  - `previewRedeem(uint256 shares)` Simulates the amount of assets that would be withdrawn for a specified amount of shares.
  - `redeem(uint256 shares, address receiver, address owner)` Redeems shares from the `MevEth` contract, burning shares and transferring assets to the receiver.

### Role Management

The `MevEth` contract implements a role-based access control system, which defines specific roles and grants permissions to certain functions based on these roles. Role management enhances security and control by ensuring that only authorized addresses can perform critical operations within the contract.

The following roles are defined in the `MevEth` contract:

- **Operator**: The operator role is responsible for managing various administrative and operational functions, such as updating parameters, processing withdrawal queues, and managing rewards distribution.

- **Admin**: The admin role has the authority to perform administrative tasks, such as updating protocol parameters, adjusting protocol fees, and managing beneficiary addresses.

### Withdrawal Queues

- `struct WithdrawalTicket`: This struct represents a withdrawal ticket, which is added to the withdrawal queue. It contains the following fields:

  - `claimed`: A boolean indicating whether the ticket has been claimed by the receiver.
  - `receiver`: The address of the receiver who will receive the ETH specified in the ticket.
  - `amount`: The amount of ETH to be sent to the receiver when the ticket is processed.
  - `accumulatedAmount`: A running sum of all requested ETH.

- **Events**:

  - `WithdrawalQueueOpened`: An event emitted when a withdrawal ticket is added to the queue.
  - `WithdrawalQueueClosed`: An event emitted when a withdrawal ticket is processed and closed.

- **State variables**:

  - `queueLength`: The length of the withdrawal queue.
  - `requestsFinalisedUntil`: Keeps track of the latest withdrawal request that was finalized.
  - `withdrawlAmountQueued`: The total amount of ETH currently queued for withdrawal.
  - `withdrawalQueue`: A mapping representing the withdrawal queue. The key is the index in the queue, and the value is a WithdrawalTicket struct.

- **Functions**:

  - `claim` function: This function allows a receiver to claim their ETH from a specific withdrawal ticket. It checks if the ticket is final, not already claimed, and then transfers the ETH to the receiver.

  - `processWithdrawalQueue` function: This function is used by the contract operator to process the withdrawal queue. It checks the available ETH balance of the contract and reserves any pending withdrawals with the available balance. It updates the requestsFinalisedUntil variable and the withdrawlAmountQueued accordingly.

  - `_withdraw` internal function: This function is called to withdraw assets (ETH) from the contract. It checks the available balance, and if the available balance is insufficient, it adds a new withdrawal ticket to the queue. It then emits a WithdrawalQueueOpened event. Finally, it transfers the available assets (ETH) to the receiver.

### Omni-Chain Fungible Token (OFT)

- **Functions**:
  - `sendFrom` enables a user to send their tokens accross chains

## 4. Security Considerations

Role-based access control ensures proper authorization for critical functions, enhancing contract security. The design minimizes potential vulnerabilities and follows best practices for Ethereum smart contracts.
