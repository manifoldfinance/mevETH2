// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface IMevEth {
    function convertToAssets(uint256 shares) external view returns (uint256);
}
