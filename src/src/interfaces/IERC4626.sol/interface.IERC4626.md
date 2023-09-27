# IERC4626
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/fb1b10e0f4766c0b96be04b99ddfd379368057c1/src/interfaces/IERC4626.sol)

SPDX-License-Identifier: SSPL-1.-0


## Functions
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
|`totalManagedAssets`|`uint256`|The amount of eth controlled by the vault|


### convertToShares


```solidity
function convertToShares(uint256 assets) external view returns (uint256 shares);
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
function convertToAssets(uint256 shares) external view returns (uint256 assets);
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
function maxDeposit(address reciever) external view returns (uint256 maxAssets);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`reciever`|`address`|The address in question of who would be depositing, doesn't matter in this case|

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


### deposit


```solidity
function deposit(uint256 assets, address receiver) external payable returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The amount of WETH which should be deposited|
|`receiver`|`address`|The address user whom should recieve the mevEth out|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares minted|


### maxMint


```solidity
function maxMint(address reciever) external view returns (uint256 maxShares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`reciever`|`address`|The address in question of who would be minting, doesn't matter in this case|

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
function mint(uint256 shares, address receiver) external payable returns (uint256 assets);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares that should be minted|
|`receiver`|`address`|The address user whom should recieve the mevEth out|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The amount of assets deposited|


### maxWithdraw


```solidity
function maxWithdraw(address owner) external view returns (uint256 maxAssets);
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
|`receiver`|`address`|The address user whom should recieve the mevEth out|
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
|`receiver`|`address`|The address user whom should recieve the wETH out|
|`owner`|`address`|The address of the owner of the mevEth|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The amount of assets withdrawn|


## Events
### Deposit
*Emitted when a deposit is made, either through mint or deposit*


```solidity
event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
```

### Withdraw
*Emitted when a withdrawal is made, either through redeem or withdraw*


```solidity
event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);
```

