// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IAuth {
    event AdminAdded(address indexed newAdmin);
    event AdminDeleted(address indexed oldAdmin);
    event OperatorAdded(address indexed newOperator);
    event OperatorDeleted(address indexed oldOperator);

    function addAdmin(address newAdmin) external;
    function addOperator(address newOperator) external;
    function admins(address) external view returns (bool);
    function deleteAdmin(address oldAdmin) external;
    function deleteOperator(address oldOperator) external;
    function operators(address) external view returns (bool);
}
