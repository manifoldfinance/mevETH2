# IBeaconDepositContract
[Git Source](https://github.com/manifoldfinance/mevETH/blob/744c86166044c40a1c176b100f17322ace7974b4/src/interfaces/IBeaconDepositContract.sol)

Interface for the Beacon Chain Deposit Contract


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


