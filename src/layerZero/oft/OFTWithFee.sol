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



pragma solidity ^0.8.0;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import "./BaseOFTWithFee.sol";

contract OFTWithFee is BaseOFTWithFee, ERC20 {
    // Custom errors save gas
    error InsufficientAllowance();
    error InsufficientBalance();
    error SharedDecimalsTooLarge();
    error ZeroAddress();

    uint256 internal immutable ld2sdRate;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 decimals,
        uint8 _sharedDecimals,
        address authority,
        address _lzEndpoint
    )
        ERC20(_name, _symbol, decimals)
        BaseOFTWithFee(_sharedDecimals, authority, _lzEndpoint)
    {
        if (_sharedDecimals > decimals) revert SharedDecimalsTooLarge();
        ld2sdRate = 10 ** (decimals - _sharedDecimals);
    }

    /**
     *
     * public functions
     *
     */
    function circulatingSupply() public view virtual override returns (uint256) {
        return totalSupply;
    }

    /**
     * @notice This function returns the address of the token contract.
     * @dev This function is used to return the address of the token contract. It is a public view virtual override function.
     */
    function token() public view virtual override returns (address) {
        return address(this);
    }

    /**
     *
     * internal functions
     *
     */
    function _debitFrom(address _from, uint16, bytes32, uint256 _amount) internal virtual override returns (uint256) {
        address spender = msg.sender;
        if (_from != spender) _spendAllowance(_from, spender, _amount);
        _burn(_from, _amount);
        return _amount;
    }

    /**
     * @notice This function is used to credit an amount to a given address.
     * @dev This function is used to mint a given amount to a given address. It is an internal virtual override function.
     */
    function _creditTo(uint16, address _toAddress, uint256 _amount) internal virtual override returns (uint256) {
        _mint(_toAddress, _amount);
        return _amount;
    }

    /**
     * @notice This function transfers tokens from one address to another.
     * @dev If the transfer is from this contract, no allowance check is necessary. Otherwise, the allowance of the spender is checked.
     */
    function _transferFrom(address _from, address _to, uint256 _amount) internal virtual override returns (uint256) {
        address spender = msg.sender;
        // if transfer from this contract, no need to check allowance
        if (_from != address(this) && _from != spender) _spendAllowance(_from, spender, _amount);
        _transfer(_from, _to, _amount);
        return _amount;
    }

    /**
     * @notice This function returns the rate of conversion from LD to SD.
     * @dev This function is internal and view virtual override.
     */
    function _ld2sdRate() internal view virtual override returns (uint256) {
        return ld2sdRate;
    }

    /**
     * OpenZeppelin ERC20 extensions
     */

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance[owner][spender];
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) {
                revert InsufficientAllowance();
            }
            if (owner == address(0) || spender == address(0)) revert ZeroAddress();
            unchecked {
                allowance[owner][spender] = currentAllowance - amount;
            }
        }
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     */
    function _transfer(address from, address to, uint256 amount) internal {
        if (from == address(0) || to == address(0)) revert ZeroAddress();
        if (balanceOf[from] < amount) revert InsufficientBalance();
        unchecked {
            balanceOf[from] -= amount;
            balanceOf[to] += amount;
        }
        emit Transfer(from, to, amount);
    }
}
