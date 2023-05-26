// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Ownable} from "solady/auth/Ownable.sol";

contract TwoStepOwnable is Ownable {
    constructor() {}

    /// remove the potential for single ownership handoff, only allow 2 step handoff.
    /// prevent renounce ownership as that will brick the mevETH accounting

    /// @dev Allows the owner to transfer the ownership to `newOwner`.
    function transferOwnership(address newOwner) public payable override onlyOwner {
        revert();
    }

    /// @dev Allows the owner to renounce their ownership.
    function renounceOwnership() public payable override onlyOwner {
        revert();
    }
}
