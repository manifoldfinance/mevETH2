# MevEthShareVault
[Git Source](https://github.com/manifoldfinance/mevETH/blob/744c86166044c40a1c176b100f17322ace7974b4/src/MevEthShareVault.sol)

**Inherits:**
[Auth](/docs-output/src/src/libraries/Auth.sol/contract.Auth.md), [IMevEthShareVault](/docs-output/src/src/interfaces/IMevEthShareVault.sol/interface.IMevEthShareVault.md)

This contract controls the ETH Rewards earned by mevEth


## State Variables
### MEV_ETH

```solidity
ITinyMevEth public immutable MEV_ETH;
```


### avgFeeRewardsPerBlock

```solidity
uint256 avgFeeRewardsPerBlock;
```


## Functions
### receive


```solidity
receive() external payable;
```

### fallback


```solidity
fallback() external payable;
```

### constructor

Construction sets authority, MevEth, and averageFeeRewardsPerBlock


```solidity
constructor(address authority, address mevEth, uint256 initialFeeRewardsPerBlock) Auth(authority);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`authority`|`address`|The address of the controlling admin authority|
|`mevEth`|`address`|The address of the WETH contract to use for deposits|
|`initialFeeRewardsPerBlock`|`uint256`|TODO: add description for how this is used|


### payRewards


```solidity
function payRewards(uint256 amount) external;
```

### recoverToken


```solidity
function recoverToken(address token, address recipient, uint256 amount) external onlyAdmin;
```

## Events
### TokenRecovered

```solidity
event TokenRecovered(address indexed recipient, address indexed token, uint256 indexed amount);
```

