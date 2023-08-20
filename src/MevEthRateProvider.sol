// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.20;

import "src/interfaces/IRateProvider.sol";
import "src/interfaces/IMevEth.sol";

/**
 * @title MevEth Rate Provider
 * @notice Returns the value of mevETH in terms of ETH
 */
contract MevETHRateProvider is IRateProvider {
    /// @notice The address of the mevETH contract
    IMevEth public immutable mevETH;

    /// @notice Constructs the MevETHRateProvider contract, setting the mevETH address
    constructor(IMevEth _mevETH) {
        mevETH = _mevETH;
    }

    /// @notice Returns the value of mevETH in terms of ETH
    /// @return the value of mevETH in terms of ETH
    function getRate() external view override returns (uint256) {
        return mevETH.convertToAssets(1 ether);
    }
}
