# IMevEthShareVault
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/216fe89b4b259aa768c698247b6facac9d08597e/src/interfaces/IMevEthShareVault.sol)


## Functions
### payRewards


```solidity
function payRewards() external;
```

### fees


```solidity
function fees() external view returns (uint128);
```

### rewards


```solidity
function rewards() external view returns (uint128);
```

### logRewards


```solidity
function logRewards(uint128 protocolFeesOwed) external;
```

### recoverToken


```solidity
function recoverToken(address token, address recipient, uint256 amount) external;
```

### sendFees


```solidity
function sendFees() external;
```

### setProtocolFeeTo


```solidity
function setProtocolFeeTo(address newFeeTo) external;
```

### setNewMevEth


```solidity
function setNewMevEth(address newMevEth) external;
```

