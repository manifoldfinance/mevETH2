// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

contract Auth {
    error Unauthorized();
    error NoAdmin();

    event AdminAdded(address indexed newAdmin);
    event AdminDeleted(address indexed oldAdmin);
    event OperatorAdded(address indexed newOperator);
    event OperatorDeleted(address indexed oldOperator);

    // admin counter (assuming 255 admins to be max)
    uint8 adminsCounter;

    // Keeps track of all operators
    mapping(address => bool) public operators;

    // Keeps track of all admins
    mapping(address => bool) public admins;

    constructor(address initialAdmin) {
        admins[initialAdmin] = true;
        unchecked {
            ++adminsCounter;
        }
        operators[initialAdmin] = true;
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
    function addAdmin(address newAdmin) external onlyAdmin {
        ++adminsCounter;
        admins[newAdmin] = true;
        emit AdminAdded(newAdmin);
    }

    function deleteAdmin(address oldAdmin) external onlyAdmin {
        --adminsCounter;
        if (adminsCounter == 0) revert NoAdmin();
        admins[oldAdmin] = false;
        emit AdminDeleted(oldAdmin);
    }

    function addOperator(address newOperator) external onlyAdmin {
        operators[newOperator] = true;
        emit OperatorAdded(newOperator);
    }

    function deleteOperator(address oldOperator) external onlyAdmin {
        operators[oldOperator] = false;
        emit OperatorDeleted(oldOperator);
    }
}
