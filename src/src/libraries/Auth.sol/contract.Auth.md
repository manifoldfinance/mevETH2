# Auth
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/fb1b10e0f4766c0b96be04b99ddfd379368057c1/src/libraries/Auth.sol)

SPDX-License-Identifier: SSPL-1.-0


## State Variables
### adminsCounter

```solidity
uint8 adminsCounter;
```


### operators

```solidity
mapping(address => bool) public operators;
```


### admins

```solidity
mapping(address => bool) public admins;
```


## Functions
### constructor

This constructor sets the initialAdmin address as an admin and operator.

*The adminsCounter is incremented unchecked.*


```solidity
constructor(address initialAdmin);
```

### onlyAdmin


```solidity
modifier onlyAdmin();
```

### onlyOperator


```solidity
modifier onlyOperator();
```

### addAdmin

addAdmin() function allows an admin to add a new admin to the contract.

*This function is only accessible to the existing admins and requires the address of the new admin.
If the new admin is already set, the function will revert. Otherwise, the adminsCounter will be incremented and the new admin will be added to the admins
mapping. An AdminAdded event will be emitted.*


```solidity
function addAdmin(address newAdmin) external onlyAdmin;
```

### deleteAdmin

Deletes an admin from the list of admins.

*Only admins can delete other admins. If the adminsCounter is 0, the transaction will revert.*


```solidity
function deleteAdmin(address oldAdmin) external onlyAdmin;
```

### addOperator

Adds a new operator to the list of operators

*Only the admin can add a new operator*


```solidity
function addOperator(address newOperator) external onlyAdmin;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOperator`|`address`|The address of the new operator|


### deleteOperator


```solidity
function deleteOperator(address oldOperator) external onlyAdmin;
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

## Errors
### Unauthorized

```solidity
error Unauthorized();
```

### AlreadySet

```solidity
error AlreadySet();
```

### NoAdmin

```solidity
error NoAdmin();
```

