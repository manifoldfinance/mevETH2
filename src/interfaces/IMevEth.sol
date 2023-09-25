// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IMevEth {
    /**
     * @dev Converts a given number of shares to assets.
     * @param shares The number of shares to convert.
     * @return The number of assets.
     */
    function convertToAssets(uint256 shares) external view returns (uint256);
}
