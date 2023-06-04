// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

contract Auth {
    error Unauthorized();

    /// The address with upgrade authority, should be a multisig controlled by Manifold
    address public sourceOfAuthority;

    constructor(address _sourceOfAuthority) {
        sourceOfAuthority = _sourceOfAuthority;
    }

    function transferAuth(address newSourceOfAuthority) public authorized {
        sourceOfAuthority = newSourceOfAuthority;
    }

    modifier authorized() {
        if (msg.sender != sourceOfAuthority) {
            revert Unauthorized();
        }
        _;
    }
}
