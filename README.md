# 🚧 mev-eth 🚧

**Under construction**

mev-eth is a leading Liquid 🥩 Staking 🥩 Reciept

## Design Doc

mev-eth is has a couple core modules and functionality.

### Ownership

First, because mev-eth is a centralized LSR, and dependent on Manifold Finance to actuall stake the Ether, ownership is given, with a couple key roles. An address can be designed as an operator, operators are intended to be automated, keeper style addresses which can redirect Ether to beacon chain validators. Operators are also expected to post oracle updates from the Beacon chain to update the contract on any rewards accrued. Additionally, there is the ManifoldOwner role, which gives the rights to control key management functions such as withdrawing fees, and setting various configuration variables such as cache balance threshold, where Ether will be held to buffer withdrawls.

### Token Design

mev-eth supports the ERC4626 interface to handle itself as an LSR. This allows many key integrations, such as Yearn Vault integrations, or any other protocols which require a yield source. This also means that mev-eth supports ERC20 as a base transferable token. Breaking from ERC4626, mev-eth also supports deposits via its fallback (recieve technically) function for call-data free deposits.

The token keeps track of this by accounting with simple Rebase math, which while a bit confusing, is the most simplistic approach, where each mev-eth token is a share which accumulates interest, and as interest grows will eventually be worth greater than it 1 eth per.

### Beacon Chain Support
