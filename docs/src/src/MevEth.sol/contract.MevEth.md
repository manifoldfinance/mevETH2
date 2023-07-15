# MevEth
[Git Source](https://github.com/manifoldfinance/mevETH/blob/744c86166044c40a1c176b100f17322ace7974b4/src/MevEth.sol)

**Inherits:**
[OFTV2](/src/layerZero/oft/OFTV2.sol/contract.OFTV2.md), [IERC4626](/src/interfaces/IERC4626.sol/interface.IERC4626.md), [ITinyMevEth](/src/interfaces/ITinyMevEth.sol/interface.ITinyMevEth.md)

**Author:**
Manifold Finance

*Contract that allows deposit of ETH, for a Liquid Staking Receipt (LSR) in return.*

*LSR is represented through an ERC4626 token and interface*


## State Variables
### stakingPaused

```solidity
bool public stakingPaused;
```


### initialized

```solidity
bool public initialized;
```


### bufferPercentNumerator
amount of eth to retain on contract for withdrawls as a percent numerator


```solidity
uint8 public bufferPercentNumerator;
```


### pendingStakingModuleCommittedTimestamp

```solidity
uint64 public pendingStakingModuleCommittedTimestamp;
```


### pendingMevEthShareVaultCommittedTimestamp

```solidity
uint64 public pendingMevEthShareVaultCommittedTimestamp;
```


### MODULE_UPDATE_TIME_DELAY

```solidity
uint64 public constant MODULE_UPDATE_TIME_DELAY = 7 days;
```


### MAX_DEPOSIT

```solidity
uint128 public constant MAX_DEPOSIT = 2 ** 128 - 1;
```


### MIN_DEPOSIT

```solidity
uint128 public constant MIN_DEPOSIT = 10_000_000_000_000_000;
```


### mevEthShareVault

```solidity
address public mevEthShareVault;
```


### pendingMevEthShareVault

```solidity
address public pendingMevEthShareVault;
```


### stakingModule

```solidity
IStakingModule public stakingModule;
```


### pendingStakingModule

```solidity
IStakingModule public pendingStakingModule;
```


### WETH
WETH Implementation used by MevEth


```solidity
IWETH public immutable WETH;
```


### fraction

```solidity
Fraction public fraction;
```


## Functions
### constructor

Construction creates mevETH token, sets authority and weth address

*pending staking module and committed timestamp will both be zero on deployment*


```solidity
constructor(address authority, address weth, address layerZeroEndpoint)
    OFTV2("Mev Liquid Staked Ether", "mevETH", 18, 8, authority, layerZeroEndpoint);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`authority`|`address`|The address of the controlling admin authority|
|`weth`|`address`|The address of the WETH contract to use for deposits|
|`layerZeroEndpoint`|`address`|chain specific endpoint|


### calculateNeededEtherBuffer


```solidity
function calculateNeededEtherBuffer() public view returns (uint256);
```

### init


```solidity
function init(address initialShareVault, address initialStakingModule) external onlyAdmin;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`initialShareVault`|`address`|The initial share vault to set when initializing the contract.|
|`initialStakingModule`|`address`|The initial staking module to set when initializing the contract.|


### updateBufferPercentNumerator

Update bufferPercentNumerator


```solidity
function updateBufferPercentNumerator(uint8 newBufferPercentNumerator) external onlyAdmin;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newBufferPercentNumerator`|`uint8`|updated percent numerator|


### stakingUnpaused

Modifier that checks if staking is paused, and reverts if so


```solidity
modifier stakingUnpaused();
```

### pauseStaking

This function pauses staking for the contract.

*Only the owner of the contract can call this function.*


```solidity
function pauseStaking() external onlyAdmin;
```

### unpauseStaking

This function unpauses staking

*This function is only callable by the owner and sets the stakingPaused variable to false. It also emits the StakingUnpaused event.*


```solidity
function unpauseStaking() external onlyAdmin;
```

### commitUpdateStakingModule

Starts the process to update the staking module. To finalize the update, the MODULE_UPDATE_TIME_DELAY must elapse and the
finalizeUpdateStakingModule function must be called


```solidity
function commitUpdateStakingModule(IStakingModule newModule) external onlyAdmin;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newModule`|`IStakingModule`|The new staking module to replace the existing one|


### finalizeUpdateStakingModule

Finalizes the staking module update after the timelock delay has elapsed.


```solidity
function finalizeUpdateStakingModule() external onlyAdmin;
```

### cancelUpdateStakingModule

Cancels a pending staking module update


```solidity
function cancelUpdateStakingModule() external onlyAdmin;
```

### commitUpdateMevEthShareVault

Starts the process to update the mevEthShareVault. To finalize the update, the MODULE_UPDATE_TIME_DELAY must elapse and the
finalizeUpdateMevEthShareVault function must be called


```solidity
function commitUpdateMevEthShareVault(address newMevEthShareVault) external onlyAdmin;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newMevEthShareVault`|`address`|The new vault to replace the existing one|


### finalizeUpdateMevEthShareVault

Finalizes the mevEthShareVault update after the timelock delay has elapsed.


```solidity
function finalizeUpdateMevEthShareVault() external onlyAdmin;
```

### cancelUpdateMevEthShareVault

Cancels a pending mevEthShareVault.


```solidity
function cancelUpdateMevEthShareVault() external onlyAdmin;
```

### createValidator

This function passes through the needed Ether to the Staking module, and the assosiated credentials with it


```solidity
function createValidator(IStakingModule.ValidatorData calldata newData) external onlyOperator stakingUnpaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newData`|`IStakingModule.ValidatorData`|The data needed to create a new validator|


### grantRewards


```solidity
function grantRewards() external payable;
```

### grantValidatorWithdraw


```solidity
function grantValidatorWithdraw() external payable;
```

### asset


```solidity
function asset() external view returns (address assetTokenAddress);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assetTokenAddress`|`address`|The address of the asset token|


### totalAssets


```solidity
function totalAssets() external view returns (uint256 totalManagedAssets);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`totalManagedAssets`|`uint256`|The amount of eth controlled by the mevEth contract|


### convertToShares


```solidity
function convertToShares(uint256 assets) public view returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The amount of assets to convert to shares|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The value of the given assets in shares|


### convertToAssets


```solidity
function convertToAssets(uint256 shares) public view returns (uint256 assets);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares to convert to assets|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The value of the given shares in assets|


### maxDeposit


```solidity
function maxDeposit(address) external view returns (uint256 maxAssets);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`maxAssets`|`uint256`|The maximum amount of assets that can be deposited|


### previewDeposit


```solidity
function previewDeposit(uint256 assets) external view returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The amount of assets that would be deposited|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares that would be minted, *under ideal conditions* only|


### _deposit

*internal deposit function to process Weth or Eth deposits*


```solidity
function _deposit(uint256 assets) internal;
```

### deposit


```solidity
function deposit(uint256 assets, address receiver) external payable stakingUnpaused returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The amount of WETH which should be deposited|
|`receiver`|`address`|The address user whom should receive the mevEth out|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares minted|


### maxMint


```solidity
function maxMint(address) external view returns (uint256 maxShares);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`maxShares`|`uint256`|The maximum amount of shares that can be minted|


### previewMint


```solidity
function previewMint(uint256 shares) external view returns (uint256 assets);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares that would be minted|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The amount of assets that would be required, *under ideal conditions* only|


### mint


```solidity
function mint(uint256 shares, address receiver) external payable stakingUnpaused returns (uint256 assets);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares that should be minted|
|`receiver`|`address`|The address user whom should receive the mevEth out|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The amount of assets deposited|


### maxWithdraw


```solidity
function maxWithdraw(address owner) public view returns (uint256 maxAssets);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|The address in question of who would be withdrawing|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`maxAssets`|`uint256`|The maximum amount of assets that can be withdrawn|


### previewWithdraw


```solidity
function previewWithdraw(uint256 assets) external view returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The amount of assets that would be withdrawn|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares that would be burned, *under ideal conditions* only|


### withdraw


```solidity
function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The amount of assets that should be withdrawn|
|`receiver`|`address`|The address user whom should receive the mevEth out|
|`owner`|`address`|The address of the owner of the mevEth|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares burned|


### maxRedeem


```solidity
function maxRedeem(address owner) external view returns (uint256 maxShares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|The address in question of who would be redeeming their shares|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`maxShares`|`uint256`|The maximum amount of shares they could redeem|


### previewRedeem


```solidity
function previewRedeem(uint256 shares) external view returns (uint256 assets);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares that would be burned|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The amount of assets that would be withdrawn, *under ideal conditions* only|


### redeem


```solidity
function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares that should be burned|
|`receiver`|`address`|The address user whom should receive the wETH out|
|`owner`|`address`|The address of the owner of the mevEth|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The amount of assets withdrawn|


### max

*Returns the largest of two numbers.*


```solidity
function max(uint256 a, uint256 b) internal pure returns (uint256);
```

### min

*Returns the smallest of two numbers.*


```solidity
function min(uint256 a, uint256 b) internal pure returns (uint256);
```

### _isZero

*gas efficient zero check*


```solidity
function _isZero(uint256 value) internal pure returns (bool boolValue);
```

### receive

*Only Weth withdraw is defined for the behaviour. Deposits should be directed to deposit / mint. Rewards via grantRewards and validator withdraws
via grantValidatorWithdraw.*


```solidity
receive() external payable;
```

### fallback

*Only Weth withdraw is defined for the behaviour. Deposits should be directed to deposit / mint. Rewards via grantRewards and validator withdraws
via grantValidatorWithdraw.*


```solidity
fallback() external payable;
```

## Events
### MevEthInitialized
*Emitted when contract is initialized*


```solidity
event MevEthInitialized(address indexed mevEthShareVault, address indexed stakingModule);
```

### StakingPaused
*Emitted when staking is paused*


```solidity
event StakingPaused();
```

### StakingUnpaused
*Emitted when staking is unpaused*


```solidity
event StakingUnpaused();
```

### StakingModuleUpdateCommitted

```solidity
event StakingModuleUpdateCommitted(
    address indexed oldModule, address indexed pendingModule, uint64 indexed eligibleForFinalization
);
```

### StakingModuleUpdateFinalized

```solidity
event StakingModuleUpdateFinalized(address indexed oldModule, address indexed newModule);
```

### StakingModuleUpdateCanceled

```solidity
event StakingModuleUpdateCanceled(address indexed oldModule, address indexed pendingModule);
```

### MevEthShareVaultUpdateCommitted

```solidity
event MevEthShareVaultUpdateCommitted(
    address indexed oldVault, address indexed pendingVault, uint64 indexed eligibleForFinalization
);
```

### MevEthShareVaultUpdateFinalized

```solidity
event MevEthShareVaultUpdateFinalized(address indexed oldVault, address indexed newVault);
```

### MevEthShareVaultUpdateCanceled

```solidity
event MevEthShareVaultUpdateCanceled(address indexed oldVault, address indexed newVault);
```

### Rewards
*Emitted when rewards are received*


```solidity
event Rewards(address sender, uint256 amount);
```

### ValidatorWithdraw
*Emitted when validator withdraw funds are received*


```solidity
event ValidatorWithdraw(address sender, uint256 amount);
```

## Structs
### Fraction
Central struct used for share accounting + math


```solidity
struct Fraction {
    uint128 elastic;
    uint128 base;
}
```

