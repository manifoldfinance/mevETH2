// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IMevEthShareVault {
    function payRewards(uint256 amount) external;

    // onlyAdmin Functions
    function recoverFunds(address recipient, uint256 amount) external;
    function recoverToken(address token, address recipient, uint256 amount) external;
}
