// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

contract Auth {
    error Unauthorized();
    error WrongRole();

    enum Roles {
        OPERATOR,
        ADMIN
    }

    // Keeps track of all operators
    mapping(address => bool) public operators;

    // Keeps track of all admins
    mapping(address => bool) public admins;

    constructor(address _initialAdmin) {
        admins[_initialAdmin] = true;
    }

    /*//////////////////////////////////////////////////////////////
                           Access Control Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyAdmin() {
        if (!admins[msg.sender]) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyOperator() {
        if (!operators[msg.sender]) {
            revert Unauthorized();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                           Maintenance Functions
    //////////////////////////////////////////////////////////////*/
    function addAdmin(address _newAdmin) external onlyAdmin {
        admins[_newAdmin] = true;
    }

    function deleteAdmin(address _oldAdmin) external onlyAdmin {
        admins[_oldAdmin] = false;
    }

    function addOperator(address _newOperator) external onlyAdmin {
        operators[_newOperator] = true;
    }

    function deleteOperator(address _oldOperator) external onlyAdmin {
        operators[_oldOperator] = false;
    }
}
