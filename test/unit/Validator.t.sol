/// SPDX: License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

import "../MevEthTest.sol";
import "src/libraries/Auth.sol";
import "../mocks/DepositContract.sol";
import { IStakingModule } from "../../src/interfaces/IStakingModule.sol";

contract ValidatorTest is MevEthTest {
    /**
     * Tests validator creation. Creates new mock validator data, deposits ETH into the mevEth contract, and creates the validator.
     */

    function testCreateValidator() public {
        uint256 stakingModuleDepositSize = mevEth.stakingModule().VALIDATOR_DEPOSIT_SIZE();
        IStakingModule.ValidatorData memory validatorData = mockValidatorData(User01, 32 ether / 1 gwei);

        //Deal User01 the staking module deposit size and deposit into the mevEth contract
        vm.deal(User01, stakingModuleDepositSize * 2);
        vm.prank(User01);
        mevEth.deposit{ value: stakingModuleDepositSize * 2 }(stakingModuleDepositSize * 2, User01);

        //Cache the balance before validator creation, create the validator, and check the balance after
        uint256 balanceBeforeCreation = address(mevEth).balance;
        address stakingModule = address(mevEth.stakingModule());
        bytes32 depositRoot = latestDepositRoot();
        vm.expectEmit(true, false, false, true, address(mevEth));
        emit ValidatorCreated(stakingModule, validatorData);
        vm.prank(Operator01);
        mevEth.createValidator(validatorData, depositRoot);

        uint256 balanceAfterCreation = address(mevEth).balance;
        assertEq(stakingModuleDepositSize, balanceBeforeCreation - balanceAfterCreation);
    }

    /**
     * Ensures that the Operator cannot front-run a validator creation to register an existing validato
     */
    function testValidatorIsNotFrontrun() public {
        IStakingModule.ValidatorData memory data = mockValidatorData(User01, 32 ether / 1 gwei);
        bytes32 depositRoot = latestDepositRoot();
        uint256 stakingModuleDepositSize = mevEth.stakingModule().VALIDATOR_DEPOSIT_SIZE();
        vm.startPrank(Operator01);
        vm.deal(Operator01, 96 ether);

        depositContract.deposit{ value: 32 ether }(data.pubkey, abi.encodePacked(data.withdrawal_credentials), data.signature, data.deposit_data_root);
        mevEth.deposit{ value: stakingModuleDepositSize * 2 }(stakingModuleDepositSize * 2, User01);

        vm.expectRevert(MevEthErrors.DepositWasFrontrun.selector);
        mevEth.createValidator(data, depositRoot);
    }

    /**
     * Tests validator creation failure cases. This function should revert when the caller is unauthorized or when the contract does not have enough eth.
     */
    function testNegativeCreateValidator() public {
        IStakingModule.ValidatorData memory validatorData = mockValidatorData(User01, 32 ether / 1 gwei);

        bytes32 depositRoot = latestDepositRoot();
        //Expect a revert when the caller is unauthorized
        vm.expectRevert(Auth.Unauthorized.selector);
        mevEth.createValidator(validatorData, depositRoot);

        //Expect a revert when the contract does not have enough eth
        vm.prank(Operator01);
        vm.expectRevert(MevEthErrors.NotEnoughEth.selector);
        mevEth.createValidator(validatorData, depositRoot);
    }

    /**
     * Tests updating to Wagyu staking module. This function should update the staking module to the WagyuStaker and create a new validator
     * asserting that the new module's balance and validator count increase accordingly.
     */
    function testUpdateToWagyuStakingModule() public {
        // Update the staking module to the WagyuStaker and create a new validator
        address depositContract = address(new DepositContract());
        IStakingModule wagyuStakingModule = IStakingModule(address(new WagyuStaker(SamBacha, depositContract, address(mevEth))));
        _updateStakingModule(wagyuStakingModule);

        uint256 depositSize = mevEth.stakingModule().VALIDATOR_DEPOSIT_SIZE();
        IStakingModule.ValidatorData memory validatorData = mockValidatorData(User01, 32 ether / 1 gwei);

        //Deal User01 the staking module deposit size and deposit into the mevEth contract
        vm.deal(User01, depositSize * 2);
        vm.prank(User01);
        mevEth.deposit{ value: depositSize * 2 }(depositSize * 2, User01);

        bytes32 depositRoot = latestDepositRoot();

        vm.prank(Operator01);
        vm.expectEmit(true, true, true, true, address(wagyuStakingModule));
        emit NewValidator(
            validatorData.operator, validatorData.pubkey, validatorData.withdrawal_credentials, validatorData.signature, validatorData.deposit_data_root
        );
        mevEth.createValidator(validatorData, depositRoot);

        assertEq(wagyuStakingModule.balance(), depositSize);
        assertEq(wagyuStakingModule.validators(), 1);
    }
}
