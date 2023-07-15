# IStakingModule
[Git Source](https://github.com/manifoldfinance/mevETH/blob/744c86166044c40a1c176b100f17322ace7974b4/src/interfaces/IStakingModule.sol)


## Functions
### deposit


```solidity
function deposit(ValidatorData calldata data) external payable;
```

### oracleUpdate


```solidity
function oracleUpdate(uint256 newBalance, uint256 newValidators) external;
```

### validators


```solidity
function validators() external view returns (uint256);
```

### balance


```solidity
function balance() external view returns (uint256);
```

### MEV_ETH


```solidity
function MEV_ETH() external view returns (address);
```

### VALIDATOR_DEPOSIT_SIZE


```solidity
function VALIDATOR_DEPOSIT_SIZE() external view returns (uint256);
```

### payValidatorWithdraw


```solidity
function payValidatorWithdraw(uint256 amount) external;
```

### recoverToken


```solidity
function recoverToken(address token, address recipient, uint256 amount) external;
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

