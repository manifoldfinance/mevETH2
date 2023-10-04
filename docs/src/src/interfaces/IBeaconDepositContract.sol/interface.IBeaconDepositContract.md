# IBeaconDepositContract
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/3090c0b460080053b688ae3504dd322da59dd255/src/interfaces/IBeaconDepositContract.sol)

SPDX-License-Identifier: SSPL-1.-0


## Functions
### deposit

Submit a Phase 0 DepositData object.


```solidity
function deposit(bytes calldata pubkey, bytes calldata withdrawal_credentials, bytes calldata signature, bytes32 deposit_data_root) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pubkey`|`bytes`|A BLS12-381 public key.|
|`withdrawal_credentials`|`bytes`|Commitment to a public key for withdrawals.|
|`signature`|`bytes`|A BLS12-381 signature.|
|`deposit_data_root`|`bytes32`|The SHA-256 hash of the SSZ-encoded DepositData object. Used as a protection against malformed input.|


### get_deposit_root

Query the current deposit root hash.


```solidity
function get_deposit_root() external view returns (bytes32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|The deposit root hash.|


