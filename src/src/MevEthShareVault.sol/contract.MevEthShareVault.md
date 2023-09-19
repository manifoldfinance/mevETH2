# MevEthShareVault
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/216fe89b4b259aa768c698247b6facac9d08597e/src/MevEthShareVault.sol)

**Inherits:**
[Auth](/src/libraries/Auth.sol/contract.Auth.md), [IMevEthShareVault](/src/interfaces/IMevEthShareVault.sol/interface.IMevEthShareVault.md)

**Author:**
Manifold Finance

This contract controls the ETH Rewards earned by mevEth


## State Variables
### protocolBalance
ProtocolBalance struct to account for the protocol fees and rewards.


```solidity
ProtocolBalance public protocolBalance;
```


### mevEth
The address of the MevEth contract.


```solidity
address public mevEth;
```


### protocolFeeTo
The address that protocol fees are sent to.


```solidity
address public protocolFeeTo;
```


## Functions
### constructor

Construction sets authority, MevEth, and averageFeeRewardsPerBlock.


```solidity
constructor(address authority, address _mevEth, address _protocolFeeTo) Auth(authority);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`authority`|`address`|The address of the controlling admin authority.|
|`_mevEth`|`address`|The address of the WETH contract to use for deposits.|
|`_protocolFeeTo`|`address`|The address that protocol fees are sent to.|


### payRewards

Function to pay rewards to the MevEth contract

*Only callable by an operator.*


```solidity
function payRewards() external onlyOperator;
```

### fees

View function to return the fees balance of the protocol


```solidity
function fees() external view returns (uint128);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint128`|uint128 fees balance of the protocol|


### rewards

View function to return the rewards balance of the protocol


```solidity
function rewards() external view returns (uint128);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint128`|uint128 rewards balance of the protocol|


### sendFees

Function to collect the fees owed to the prorotocol.


```solidity
function sendFees() external onlyAdmin;
```

### setProtocolFeeTo


```solidity
function setProtocolFeeTo(address newProtocolFeeTo) external onlyAdmin;
```

### logRewards

Function to log rewards, updating the protocol balance. Once all balances are updated, the RewardsCollected event is emitted.

*Operators are tracking the RewardPayment events to calculate the protocolFeesOwed.
The logRewards function is then called to update the fees and rewards within the protocol balance.
Validators associated with the MevETH protocol set the block builder's address as the feeRecepient for the block.
The block builder attaches a transaction to the end of the block sending the MEV rewards to the MevEthShareVault.
This then emits the RewardPayment event, allowing the offchain operators to track the protocolFeesOwed.
This approach trusts that the operators are acting honestly and the protocolFeesOwed is accurately calculated.*


```solidity
function logRewards(uint128 protocolFeesOwed) external onlyOperator;
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

### payValidatorWithdraw

Function to pay MevEth when withdrawing funds from a validator

*This function is only callable by an admin and emits an event for offchain validator registry tracking.*


```solidity
function payValidatorWithdraw() external onlyOperator;
```

### receive

Function to receive ETH.

*All Ether sent to the contract is handled as a MevPayment.*


```solidity
receive() external payable;
```

## Events
### RewardPayment
Event emitted when a reward payment is made


```solidity
event RewardPayment(uint256 indexed blockNumber, address indexed coinbase, uint256 indexed amount);
```

### RewardsCollected
Event emitted when the protocol balance is updated during logRewards


```solidity
event RewardsCollected(uint256 indexed protocolFeesOwed, uint256 indexed rewardsOwed);
```

### TokenRecovered
Event emitted when a tokens are recovered from the contract.


```solidity
event TokenRecovered(address indexed recipient, address indexed token, uint256 indexed amount);
```

### ProtocolFeeToUpdated
Event emitted when the protocolFeeTo address is updated.


```solidity
event ProtocolFeeToUpdated(address indexed newProtocolFeeTo);
```

### FeesSent
Event emitted when the protocol fees are sent to the protocolFeeTo address.


```solidity
event FeesSent(uint256 indexed feesSent);
```

### RewardsPaid
Event emitted when rewards are paid to the MevEth contract.


```solidity
event RewardsPaid(uint256 indexed rewards);
```

### MevEthUpdated
Event emitted when the mevEth address is updated.


```solidity
event MevEthUpdated(address indexed meveth);
```

### ValidatorWithdraw
Event emitted when funds representing a validator withdrawal are sent to the MevEth contract.


```solidity
event ValidatorWithdraw(address sender, uint256 amount);
```

## Structs
### ProtocolBalance
Struct to account for the protocol fees and rewards.


```solidity
struct ProtocolBalance {
  uint128 fees;
  uint128 rewards;
}
```

