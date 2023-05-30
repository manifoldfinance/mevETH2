// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

contract auth {
    error Unauthorized();

    /// The address with upgrade authority, should be a multisig controlled by Manifold
    address public source_of_authority;

    constructor(address _source_of_authority) {
        source_of_authority = _source_of_authority;
    }

    function transferAuth(address new_source_of_authority) public authorized {
        source_of_authority = new_source_of_authority;
    }

    modifier authorized() {
        if (msg.sender != source_of_authority) {
            revert Unauthorized();
        }
        _;
    }
}