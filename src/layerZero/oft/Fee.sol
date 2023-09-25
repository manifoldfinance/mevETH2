// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../libraries/Auth.sol";

abstract contract Fee is Auth {
    // Custom errors save gas
    error FeeBpTooLarge();
    error FeeOwnerNotSet();

    uint256 public constant BP_DENOMINATOR = 10_000;

    mapping(uint16 => FeeConfig) public chainIdToFeeBps;
    uint16 public defaultFeeBp;
    address public feeOwner; // defaults to owner

    struct FeeConfig {
        uint16 feeBP;
        bool enabled;
    }

    event SetFeeBp(uint16 dstchainId, bool enabled, uint16 feeBp);
    event SetDefaultFeeBp(uint16 feeBp);
    event SetFeeOwner(address feeOwner);

    constructor(address authority) {
        feeOwner = authority;
    }

    function setDefaultFeeBp(uint16 _feeBp) public virtual onlyAdmin {
        if (_feeBp > BP_DENOMINATOR) revert FeeBpTooLarge();
        defaultFeeBp = _feeBp;
        emit SetDefaultFeeBp(defaultFeeBp);
    }

    function setFeeBp(uint16 _dstChainId, bool _enabled, uint16 _feeBp) public virtual onlyAdmin {
        if (_feeBp > BP_DENOMINATOR) revert FeeBpTooLarge();
        chainIdToFeeBps[_dstChainId] = FeeConfig(_feeBp, _enabled);
        emit SetFeeBp(_dstChainId, _enabled, _feeBp);
    }

    /**
     * @notice Sets the fee owner address
     * @dev This function sets the fee owner address to the address passed in as an argument. If the address passed in is 0x0, the function will revert with the
     * FeeOwnerNotSet error.
     * @param _feeOwner The address to set as the fee owner
     */
    function setFeeOwner(address _feeOwner) public virtual onlyAdmin {
        if (_feeOwner == address(0x0)) revert FeeOwnerNotSet();
        feeOwner = _feeOwner;
        emit SetFeeOwner(_feeOwner);
    }

    function quoteOFTFee(uint16 _dstChainId, uint256 _amount) public view virtual returns (uint256 fee) {
        FeeConfig memory config = chainIdToFeeBps[_dstChainId];
        if (config.enabled) {
            fee = _amount * config.feeBP / BP_DENOMINATOR;
        } else if (defaultFeeBp > 0) {
            fee = _amount * defaultFeeBp / BP_DENOMINATOR;
        } else {
            fee = 0;
        }
    }

    function _payOFTFee(address _from, uint16 _dstChainId, uint256 _amount) internal virtual returns (uint256 amount, uint256 fee) {
        fee = quoteOFTFee(_dstChainId, _amount);
        amount = _amount - fee;
        if (fee > 0) {
            _transferFrom(_from, feeOwner, fee);
        }
    }

    /**
     * @notice This function is used to transfer tokens from one address to another.
     * @dev This function is called by the transferFrom() function. It is used to transfer tokens from one address to another.
     * @param _from The address from which the tokens are being transferred.
     * @param _to The address to which the tokens are being transferred.
     * @param _amount The amount of tokens being transferred.
     */
    function _transferFrom(address _from, address _to, uint256 _amount) internal virtual returns (uint256);
}
