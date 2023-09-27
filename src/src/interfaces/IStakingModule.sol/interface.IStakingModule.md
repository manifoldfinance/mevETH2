# IStakingModule
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/fb1b10e0f4766c0b96be04b99ddfd379368057c1/src/interfaces/IStakingModule.sol)

SPDX-License-Identifier: SSPL-1.-0


## Functions
### deposit

*Allows users to deposit funds into the contract.*


```solidity
function deposit(ValidatorData calldata data, bytes32 latestDepositRoot) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`data`|`ValidatorData`|ValidatorData calldata containing the validator's public key, withdrawal credentials, and amount of tokens to be deposited.|
|`latestDepositRoot`|`bytes32`|bytes32 containing the latest deposit root.|


### validators


```solidity
function validators() external view returns (uint256);
```

### mevEth


```solidity
function mevEth() external view returns (address);
```

### VALIDATOR_DEPOSIT_SIZE

VALIDATOR_DEPOSIT_SIZE()
This function returns the size of the validator deposit.

*This function is used to determine the size of the validator deposit. It is used to ensure that validators have the correct amount of funds in order
to participate in the network.*


```solidity
function VALIDATOR_DEPOSIT_SIZE() external view returns (uint256);
```

### payRewards

This function is used to pay rewards to the users.

*This function is used to pay rewards to the users. It takes in a uint256 rewards parameter which is the amount of rewards to be paid.*


```solidity
function payRewards(uint256 rewards) external;
```

### payValidatorWithdraw

This function allows a validator to withdraw their rewards from the contract.

*This function is called by a validator to withdraw their rewards from the contract. It will transfer the rewards to the validator's address.*


```solidity
function payValidatorWithdraw() external;
```

### recoverToken


```solidity
function recoverToken(address token, address recipient, uint256 amount) external;
```

### record

record() function is used to record the data in the smart contract.

*record() function takes no parameters and returns four uint128 values.*


```solidity
function record() external returns (uint128, uint128, uint128, uint128);
```

### registerExit

registerExit() allows users to exit the system.

*registerExit() is a function that allows users to exit the system. It is triggered by an external call.*


```solidity
function registerExit() external;
```

### batchMigrate


```solidity
function batchMigrate(IStakingModule.ValidatorData[] calldata batchData) external;
```

## Structs
### ValidatorData
*Structure for passing information about the validator deposit data.*


```solidity
struct ValidatorData {
    address operator;
    bytes pubkey;
    bytes32 withdrawal_credentials;
    bytes signature;
    bytes32 deposit_data_root;
}
```

