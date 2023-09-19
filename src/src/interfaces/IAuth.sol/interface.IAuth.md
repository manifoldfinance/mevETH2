# IAuth
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/216fe89b4b259aa768c698247b6facac9d08597e/src/interfaces/IAuth.sol)


## Functions
### addAdmin


```solidity
function addAdmin(address newAdmin) external;
```

### addOperator


```solidity
function addOperator(address newOperator) external;
```

### admins


```solidity
function admins(address) external view returns (bool);
```

### deleteAdmin


```solidity
function deleteAdmin(address oldAdmin) external;
```

### deleteOperator


```solidity
function deleteOperator(address oldOperator) external;
```

### operators


```solidity
function operators(address) external view returns (bool);
```

## Events
### AdminAdded

```solidity
event AdminAdded(address indexed newAdmin);
```

### AdminDeleted

```solidity
event AdminDeleted(address indexed oldAdmin);
```

### OperatorAdded

```solidity
event OperatorAdded(address indexed newOperator);
```

### OperatorDeleted

```solidity
event OperatorDeleted(address indexed oldOperator);
```

