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

interface IAuth {
    event AdminAdded(address indexed newAdmin);
    event AdminDeleted(address indexed oldAdmin);
    event OperatorAdded(address indexed newOperator);
    event OperatorDeleted(address indexed oldOperator);

    /**
     * @notice Adds an admin to the contract.
     * @dev Only existing admins can add new admins.
     */
    function addAdmin(address newAdmin) external;
    /**
     * @notice This function adds a new operator to the contract.
     * @dev This function adds a new operator to the contract. It is only callable by the contract owner. The new operator must be a valid Ethereum address.
     */
    function addOperator(address newOperator) external;
    /**
     * @notice This function is used to check if an address is an admin.
     * @dev This function is used to check if an address is an admin. It takes an address as an argument and returns a boolean value.
     */
    function admins(address) external view returns (bool);
    /**
     * @notice This function is used to delete an admin from the list of admins.
     * @dev This function requires the address of the admin to be deleted. It will delete the admin from the list of admins.
     */
    function deleteAdmin(address oldAdmin) external;
    /**
     * @notice This function is used to delete an operator from the contract.
     * @dev This function is called by the owner of the contract to delete an operator from the contract. The address of the operator to be deleted is passed as
     * an argument.
     */
    function deleteOperator(address oldOperator) external;
    /**
     * @notice This function checks if the given address is an operator.
     * @dev This function is used to check if the given address is an operator. It returns a boolean value indicating whether the address is an operator or not.
     */
    function operators(address) external view returns (bool);
}
