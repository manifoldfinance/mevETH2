# WagyuStaker
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/216fe89b4b259aa768c698247b6facac9d08597e/src/WagyuStaker.sol)

**Inherits:**
[Auth](/src/libraries/Auth.sol/contract.Auth.md), [IStakingModule](/src/interfaces/IStakingModule.sol/interface.IStakingModule.md)

*This contract stakes Ether inside of the BeaconChainDepositContract directly*


## State Variables
### record
Record of total deposits, withdraws, rewards paid and validators exited


```solidity
Record public record;
```


### validators
The number of validators on the consensus layer registered under this contract


```solidity
uint256 public validators;
```


### mevEth
The address of the MevEth contract


```solidity
address public mevEth;
```


### VALIDATOR_DEPOSIT_SIZE
Validator deposit size.


```solidity
uint256 public constant override VALIDATOR_DEPOSIT_SIZE = 32 ether;
```


### BEACON_CHAIN_DEPOSIT_CONTRACT
The Canonical Address of the BeaconChainDepositContract


```solidity
IBeaconDepositContract public immutable BEACON_CHAIN_DEPOSIT_CONTRACT;
```


## Functions
### constructor

Construction sets authority, MevEth, and deposit contract addresses


```solidity
constructor(address _authority, address _depositContract, address _mevEth) Auth(_authority);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_authority`|`address`|The address of the controlling admin authority|
|`_depositContract`|`address`|The address of the beacon deposit contract|
|`_mevEth`|`address`|The address of the mevETH contract|


### deposit

Function to deposit funds into the BEACON_CHAIN_DEPOSIT_CONTRACT, and register a validator


```solidity
function deposit(IStakingModule.ValidatorData calldata data, bytes32 latestDepositRoot) external payable;
```

### payRewards

Function to pay rewards to the MevEth contract

*Only callable by an operator. Additionally, if there is an issue when granting rewards to the MevEth contract, funds are secured to the
beneficiary address for manual allocation to the MevEth contract.*


```solidity
function payRewards(uint256 rewards) external onlyOperator;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`rewards`|`uint256`|rewards to pay to the MevEth contract|


### registerExit


```solidity
function registerExit() external;
```

### payValidatorWithdraw

Function to pay MevEth when withdrawing funds from a validator

*This function is only callable by an admin and emits an event for offchain validator registry tracking.*


```solidity
function payValidatorWithdraw() external onlyOperator;
```

### recoverToken

Function to recover tokens sent to the contract.

*This function is only callable by an admin.*


```solidity
function recoverToken(address token, address recipient, uint256 amount) external onlyAdmin;
```

### setNewMevEth

Function to set a new mevEth address.


```solidity
function setNewMevEth(address newMevEth) external onlyAdmin;
```

### batchMigrate

Batch register Validators for migration

*only Admin*


```solidity
function batchMigrate(IStakingModule.ValidatorData[] calldata batchData) external onlyAdmin;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`batchData`|`IStakingModule.ValidatorData[]`|list of each validators' data struct|


### receive

Function to receive Ether


```solidity
receive() external payable;
```

## Events
### NewValidator
Event emitted when a validator is registered


```solidity
event NewValidator(address indexed operator, bytes pubkey, bytes32 withdrawalCredentials, bytes signature, bytes32 deposit_data_root);
```

### TokenRecovered
Event emitted when tokens are recovered from the contract.


```solidity
event TokenRecovered(address indexed recipient, address indexed token, uint256 indexed amount);
```

### RewardsPaid
Event emitted when rewards are paid to the MevEth contract.


```solidity
event RewardsPaid(uint256 indexed amount);
```

### ValidatorWithdraw
Event emitted when funds representing a validator withdrawal are sent to the MevEth contract.


```solidity
event ValidatorWithdraw(address sender, uint256 amount);
```

### MevEthUpdated
Event emitted when the mevEth address is updated.


```solidity
event MevEthUpdated(address indexed meveth);
```

## Structs
### Record

```solidity
struct Record {
  uint128 totalDeposited;
  uint128 totalWithdrawn;
  uint128 totalRewardsPaid;
  uint128 totalValidatorExitsPaid;
}
```

