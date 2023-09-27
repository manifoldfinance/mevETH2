# ILayerZeroUserApplicationConfig
[Git Source](https://github.com/manifoldfinance/mevETH2/blob/fb1b10e0f4766c0b96be04b99ddfd379368057c1/src/interfaces/ILayerZeroUserApplicationConfig.sol)

SPDX-License-Identifier: SSPL-1.-0


## Functions
### setConfig

This function sets the configuration of the contract.

*This function sets the configuration of the contract. It takes in four parameters:
- _version: The version of the configuration.
- _chainId: The chain ID of the configuration.
- _configType: The type of configuration.
- _config: The configuration data.*


```solidity
function setConfig(uint16 _version, uint16 _chainId, uint256 _configType, bytes calldata _config) external;
```

### setSendVersion


```solidity
function setSendVersion(uint16 _version) external;
```

### setReceiveVersion

Sets the version of the receive protocol.

*This function sets the version of the receive protocol. It is used to ensure that the protocol is up to date.*


```solidity
function setReceiveVersion(uint16 _version) external;
```

### forceResumeReceive

This function is used to force resume receive on a given source chain and address.

*This function is used to force resume receive on a given source chain and address. It takes two parameters, _srcChainId and _srcAddress. _srcChainId
is a uint16 representing the source chain ID and _srcAddress is a bytes calldata representing the source address. This function is only callable by the
owner of the contract.*


```solidity
function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
```

