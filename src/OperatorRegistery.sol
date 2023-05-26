// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {TwoStepOwnable} from "./auth/TwoStepOwnable.sol";
import {IOperatorRegistery} from "./interfaces/IOperatorRegistery.sol";

// todo: ensure withdrawal addresses are the same. check tg

contract OperatorRegistery is IOperatorRegistery, TwoStepOwnable {
    error OperatorsNotCommitted();
    error OperatorMaxValidatorsReached();
    error OperatorNotCommitted();
    error MaxValidatorError();
    error InvalidOperator();
    error ValidatorPreviouslyRegistered();

    event OperatorCommited(address indexed operator);
    event OperatorUncommited(address indexed operator);
    event OperatorRemoved(address indexed operator);
    event OperatorMaxValidatorsSet(address indexed operator, uint256 maxValidators);

    uint256 public totalValidators;
    address public manifoldLSD;

    mapping(address => Operator) public operators;

    // Maps hash of the validator data to whether it is registered.
    mapping(bytes32 => bool) public validators;

    modifier onlyManifoldLSD() {
        if (msg.sender != manifoldLSD) revert();
        _;
    }

    constructor(address _manifoldLSD) {
        // todo: maybe make this a param
        _initializeOwner(msg.sender);
        manifoldLSD = _manifoldLSD;
    }

    function commitOperator(address newOperator) external onlyOwner {
        if (newOperator == address(0)) revert InvalidOperator();
        Operator storage operator = operators[newOperator];

        operator.commited = true;

        emit OperatorCommited(newOperator);
    }

    function uncommitOperator(address operator) external onlyOwner {
        if (operator == address(0)) revert InvalidOperator();
        Operator storage operatorToUncommit = operators[operator];

        operatorToUncommit.commited = false;

        emit OperatorUncommited(operator);
    }

    function removeOperator(address operator) external onlyOwner {
        delete operators[operator];

        emit OperatorRemoved(operator);
    }

    function setMaxValidators(address operator, uint64 maxValidators) external onlyOwner {
        Operator storage op = operators[operator];
        if (!op.commited) revert OperatorNotCommitted();
        if (op.validatorsActive > maxValidators) revert MaxValidatorError();

        op.maxValidators = maxValidators;

        emit OperatorMaxValidatorsSet(operator, maxValidators);
    }

    function registerValidator(ValidatorData calldata depositData) external onlyManifoldLSD {
        Operator storage op = operators[depositData.operator];

        if (!op.commited) revert OperatorsNotCommitted();
        if (op.validatorsActive + 1 > op.maxValidators) {
            revert OperatorMaxValidatorsReached();
        }

        // mark validator as registered -> prevents from registering the same validator twice
        bytes32 validatorId = keccak256(abi.encode(depositData.pubkey));
        if (validators[validatorId]) revert ValidatorPreviouslyRegistered();

        validators[validatorId] = true;
        op.validatorsActive++;
        totalValidators++;
    }
}
