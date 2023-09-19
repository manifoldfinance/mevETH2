# AuthManager
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/216fe89b4b259aa768c698247b6facac9d08597e/src/libraries/AuthManager.sol)

Periphery contract to unify Auth updates across MevEth, MevEthShareVault and WagyuStaker

*deployment address should be added as admin in initial setup*

*contract addresses are upgradeable. To upgrade auth a redeploy is necessary*


## State Variables
### auth

```solidity
address public immutable auth;
```


### mevEth

```solidity
address public mevEth;
```


### mevEthShareVault

```solidity
address public mevEthShareVault;
```


### wagyuStaker

```solidity
address public wagyuStaker;
```


## Functions
### constructor


```solidity
constructor(address initialAdmin, address initialMevEth, address initialShareVault, address initialStaker);
```

### onlyAuth


```solidity
modifier onlyAuth();
```

### updateMevEth


```solidity
function updateMevEth(address newMevEth) external onlyAuth;
```

### updateMevEthShareVault


```solidity
function updateMevEthShareVault(address newMevEthShareVault) external onlyAuth;
```

### updateWagyuStaker


```solidity
function updateWagyuStaker(address newWagyuStaker) external onlyAuth;
```

### addAdmin


```solidity
function addAdmin(address newAdmin) external onlyAuth;
```

### deleteAdmin


```solidity
function deleteAdmin(address oldAdmin) external onlyAuth;
```

### addOperator


```solidity
function addOperator(address newOperator) external onlyAuth;
```

### deleteOperator


```solidity
function deleteOperator(address oldOperator) external onlyAuth;
```

## Events
### MevEthShareVaultAuthUpdateMissed
emitted when MevEthShareVault is a multisig to log missed auth updates

*missed updates will need to be manually added when upgrading from a multisig*


```solidity
event MevEthShareVaultAuthUpdateMissed(address changeAddress, Operation operation);
```

## Errors
### Unauthorized

```solidity
error Unauthorized();
```

## Enums
### Operation

```solidity
enum Operation {
  ADDADMIN,
  DELETEADMIN,
  ADDOPERATOR,
  DELETEOPERATOR
}
```

