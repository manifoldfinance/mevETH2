# IMevEthShareVault
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/3090c0b460080053b688ae3504dd322da59dd255/src/interfaces/IMevEthShareVault.sol)

SPDX-License-Identifier: SSPL-1.-0


## Functions
### payRewards

!
The receive function handles mev/validator payments.
If if the msg.sender is the block.coinbase, a `ValditorPayment` should be emitted
The profits (less fees) should be updated based on the median validator payment.
Otherwise, a MevPayment should be emitted and the fees/profits should be updated based on the medianMevPayment.
payRewards()

Function to send rewards to MevEth Contract.

*This function is triggered by the owner of the contract and is used to pay rewards to MevETH Contract.
In the case of failure, this function sends the funds to the Admin as a fallback.*


```solidity
function payRewards(uint256 rewards) external;
```

### recoverToken


```solidity
function recoverToken(address token, address recipient, uint256 amount) external;
```

### sendFees

sendFees()

This function should only be called by the contract owner.

*Function to send fees to the contract owner.*


```solidity
function sendFees(uint256 fees) external;
```

### setProtocolFeeTo


```solidity
function setProtocolFeeTo(address newFeeTo) external;
```

### setNewMevEth

setNewMevEth()

Sets the newMevEth address

*This function sets the newMevEth address to the address passed in as an argument. This address will be used to store the MEV-ETH tokens.*


```solidity
function setNewMevEth(address newMevEth) external;
```

