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

contract Auth {
    error Unauthorized();
    error AlreadySet();
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

    /**
     * @notice This constructor sets the initialAdmin address as an admin and operator.
     * @dev The adminsCounter is incremented unchecked.
     */
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
    /**
     * @notice addAdmin() function allows an admin to add a new admin to the contract.
     * @dev This function is only accessible to the existing admins and requires the address of the new admin.
     * If the new admin is already set, the function will revert. Otherwise, the adminsCounter will be incremented and the new admin will be added to the admins
     * mapping. An AdminAdded event will be emitted.
     */
    function addAdmin(address newAdmin) external onlyAdmin {
        if (admins[newAdmin]) revert AlreadySet();
        ++adminsCounter;
        admins[newAdmin] = true;
        emit AdminAdded(newAdmin);
    }

    /**
     * @notice Deletes an admin from the list of admins.
     * @dev Only admins can delete other admins. If the adminsCounter is 0, the transaction will revert.
     */
    function deleteAdmin(address oldAdmin) external onlyAdmin {
        if (!admins[oldAdmin]) revert AlreadySet();
        --adminsCounter;
        if (adminsCounter == 0) revert NoAdmin();
        admins[oldAdmin] = false;
        emit AdminDeleted(oldAdmin);
    }

    /**
     * @notice Adds a new operator to the list of operators
     * @dev Only the admin can add a new operator
     * @param newOperator The address of the new operator
     */
    function addOperator(address newOperator) external onlyAdmin {
        if (operators[newOperator]) revert AlreadySet();
        operators[newOperator] = true;
        emit OperatorAdded(newOperator);
    }

    function deleteOperator(address oldOperator) external onlyAdmin {
        if (!operators[oldOperator]) revert AlreadySet();
        operators[oldOperator] = false;
        emit OperatorDeleted(oldOperator);
    }
}
