/// SPDX: License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../MevEthTest.sol";
import "src/libraries/Auth.sol";
import "../mocks/DepositContract.sol";
import { IStakingModule } from "../../src/interfaces/IStakingModule.sol";

contract ValidatorTest is MevEthTest {
    function mockValidatorData(address operator, uint256 depositAmount) internal pure returns (IStakingModule.ValidatorData memory) {
        bytes memory pubkey =
            abi.encodePacked(bytes32(0x1234567890123456789012345678901234567890123456789012345678901234), bytes16(0x12345678901234567890123456789012));
        bytes32 withdrawalCredentials = bytes32(0x1234567890123456789012345678901234567890123456789012345678901234);

        bytes memory signatureFirst64Bytes = abi.encodePacked(
            bytes32(0x1234567890123456789012345678901234567890123456789012345678901234),
            bytes32(0x1234567890123456789012345678901234567890123456789012345678901234)
        );

        bytes32 signatureLast32Bytes = bytes32(0x1234567890123456789012345678901234567890123456789012345678901234);
        bytes memory signature = abi.encodePacked(
            bytes32(0x1234567890123456789012345678901234567890123456789012345678901234),
            bytes32(0x1234567890123456789012345678901234567890123456789012345678901234),
            bytes32(0x1234567890123456789012345678901234567890123456789012345678901234)
        );

        bytes memory amount = to_little_endian_64(uint64(depositAmount));
        // Compute deposit data root (`DepositData` hash tree root)
        bytes32 pubkeyRoot = sha256(abi.encodePacked(pubkey, bytes16(0)));
        bytes32 signatureRoot =
            sha256(abi.encodePacked(sha256(abi.encodePacked(signatureFirst64Bytes)), sha256(abi.encodePacked(signatureLast32Bytes, bytes32(0)))));
        bytes32 depositDataRoot =
            sha256(abi.encodePacked(sha256(abi.encodePacked(pubkeyRoot, withdrawalCredentials)), sha256(abi.encodePacked(amount, bytes24(0), signatureRoot))));

        return IStakingModule.ValidatorData({
            operator: operator,
            pubkey: pubkey,
            withdrawal_credentials: withdrawalCredentials,
            signature: signature,
            deposit_data_root: depositDataRoot
        });
    }

    function to_little_endian_64(uint64 value) internal pure returns (bytes memory ret) {
        ret = new bytes(8);
        bytes8 bytesValue = bytes8(value);
        // Byteswapping during copying to bytes.
        ret[0] = bytesValue[7];
        ret[1] = bytesValue[6];
        ret[2] = bytesValue[5];
        ret[3] = bytesValue[4];
        ret[4] = bytesValue[3];
        ret[5] = bytesValue[2];
        ret[6] = bytesValue[1];
        ret[7] = bytesValue[0];
    }

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
        vm.prank(Operator01);

        mevEth.createValidator(validatorData);
        uint256 balanceAfterCreation = address(mevEth).balance;
        assertEq(stakingModuleDepositSize, balanceBeforeCreation - balanceAfterCreation);
    }

    /**
     * Tests validator creation failure cases. This function should revert when the caller is unauthorized or when the contract does not have enough eth.
     */

    function testNegativeCreateValidator() public {
        IStakingModule.ValidatorData memory validatorData = mockValidatorData(User01, 32 ether / 1 gwei);

        //Expect a revert when the caller is unauthorized
        vm.expectRevert(Auth.Unauthorized.selector);
        mevEth.createValidator(validatorData);

        //Expect a revert when the contract does not have enough eth
        vm.prank(Operator01);
        vm.expectRevert(MevEthErrors.NotEnoughEth.selector);
        mevEth.createValidator(validatorData);
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

        vm.prank(Operator01);
        vm.expectEmit(true, true, true, true, address(wagyuStakingModule));
        emit NewValidator(
            validatorData.operator, validatorData.pubkey, validatorData.withdrawal_credentials, validatorData.signature, validatorData.deposit_data_root
        );
        mevEth.createValidator(validatorData);

        assertEq(wagyuStakingModule.balance(), depositSize);
        assertEq(wagyuStakingModule.validators(), 1);
    }
}
