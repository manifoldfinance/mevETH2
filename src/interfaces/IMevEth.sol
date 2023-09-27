/// SPDX-License-Identifier: SSPL-1.-0

/**
 * @custom:org.protocol='mevETH LST Protocol'
 * @custom:org.security='mailto:security@manifoldfinance.com'
 * @custom:org.vcs-commit=$GIT_COMMIT_SHA
 * @custom:org.vendor='CommodityStream, Inc'
 * @custom:org.schema-version="1.0"
 * @custom.org.encryption="manifoldfinance.com/.well-known/pgp-key.asc"
 * @custom:org.preferred-languages="en"
 */

pragma solidity ^0.8.19;

/// @title IMevEth
interface IMevEth {
    /**
     * convertToAssets()
     *
     * @dev Converts a given number of shares to assets.
     * @param shares The number of shares to convert.
     * @return The number of assets.
     */
    function convertToAssets(uint256 shares) external view returns (uint256);
}
