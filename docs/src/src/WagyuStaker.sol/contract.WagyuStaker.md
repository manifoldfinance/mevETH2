# WagyuStaker
[Git Source](https://github.com/manifoldfinance/mevETH/blob/744c86166044c40a1c176b100f17322ace7974b4/src/WagyuStaker.sol)

**Inherits:**
[Auth](/src/libraries/Auth.sol/contract.Auth.md), [IStakingModule](/src/interfaces/IStakingModule.sol/interface.IStakingModule.md)

*This contract stakes Ether inside of the BeaconChainDepositContract directly*


## State Variables
### balance

```solidity
uint256 public balance;
```


### validators

```solidity
uint256 public validators;
```


### MEV_ETH

```solidity
address public immutable MEV_ETH;
```


### VALIDATOR_DEPOSIT_SIZE

```solidity
uint256 public constant override VALIDATOR_DEPOSIT_SIZE = 32 ether;
```


### BEACON_CHAIN_DEPOSIT_CONTRACT

```solidity
IBeaconDepositContract public immutable BEACON_CHAIN_DEPOSIT_CONTRACT;
```


## Functions
### constructor

Construction sets authority, MevEth, and deposit contract addresses


```solidity
constructor(address authority, address depositContract, address mevEth) Auth(authority);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`authority`|`address`|The address of the controlling admin authority|
|`depositContract`|`address`|The address of the WETH contract to use for deposits|
|`mevEth`|`address`|The address of the WETH contract to use for deposits|


### deposit


```solidity
function deposit(IStakingModule.ValidatorData calldata data) external payable;
```

### oracleUpdate


```solidity
function oracleUpdate(uint256 newBalance, uint256 newValidators) external;
```

### payValidatorWithdraw


```solidity
function payValidatorWithdraw(uint256 amount) external;
```

### recoverToken


```solidity
function recoverToken(address token, address recipient, uint256 amount) external onlyAdmin;
```

### receive


```solidity
receive() external payable;
```

### fallback


```solidity
fallback() external payable;
```

## Events
### NewValidator

```solidity
event NewValidator(
    address indexed operator, bytes pubkey, bytes32 withdrawalCredentials, bytes signature, bytes32 deposit_data_root
);
```

### TokenRecovered

```solidity
event TokenRecovered(address indexed recipient, address indexed token, uint256 indexed amount);
```

## Errors
### WrongDepositAmount

```solidity
error WrongDepositAmount();
```

### UnAuthorizedCaller

```solidity
error UnAuthorizedCaller();
```

