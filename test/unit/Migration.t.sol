/// SPDX: License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../MevEthTest.sol";
import { MevEthShareVault } from "src/MevEthShareVault.sol";
import { Empty } from "test/mocks/Empty.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";
import "src/libraries/Auth.sol";
import "../mocks/DepositContract.sol";
import { IStakingModule } from "../../src/interfaces/IStakingModule.sol";
import "../../src/interfaces/IMevEthShareVault.sol";
import "../../lib/safe-tools/src/SafeTestTools.sol";

contract MevEthMigrationTest is MevEthTest {
    address internal creamTokenAddress = 0x49D72e3973900A195A155a46441F0C08179FdB64;

    function testRedeemCreamETHIsolated() external {
        MockERC20 tempCreth2 = new MockERC20("Cream Ether 2", "creth2", 18);
        vm.etch(creamTokenAddress, address(tempCreth2).code);

        MockERC20 creth2 = MockERC20(creamTokenAddress);

        vm.startPrank(User01);
        creth2.mint(User01, 1000 ether);
        creth2.approve(address(mevEth), 1000 ether);

        uint256 oldCreth2Balance = creth2.balanceOf(User01);
        uint256 oldMevEthBalance = mevEth.balanceOf(User01);

        mevEth.redeemCream(1000 ether);

        uint256 newCreth2Balance = creth2.balanceOf(User01);
        uint256 newMevEthBalance = mevEth.balanceOf(User01);

        assert(newCreth2Balance == 0 && newCreth2Balance < oldCreth2Balance);
        assert(newMevEthBalance > 0 && newMevEthBalance > oldMevEthBalance);

        assertEq(newMevEthBalance, (1000 ether * mevEth.CREAM_TO_MEV_ETH_PERCENT()) / 1000);
    }

    function testMigrateValidatorsThroughWagyu() external {
        IStakingModule wagyuStaker = mevEth.stakingModule();

        IStakingModule.ValidatorData[] memory migratedValidators = new IStakingModule.ValidatorData[](5);

        migratedValidators[0] = mockValidatorData(Operator01, 32 ether);
        migratedValidators[1] = mockValidatorData(Operator01, 32 ether);
        migratedValidators[2] = mockValidatorData(Operator01, 32 ether);
        migratedValidators[3] = mockValidatorData(Operator01, 32 ether);
        migratedValidators[4] = mockValidatorData(Operator01, 32 ether);

        uint256 oldTotalValidators = wagyuStaker.validators();
        (uint256 oldTotalDeposited,,,) = wagyuStaker.record();

        vm.prank(SamBacha);
        wagyuStaker.batchMigrate(migratedValidators);

        uint256 newTotalValidators = wagyuStaker.validators();
        (uint256 newTotalDeposited,,,) = wagyuStaker.record();

        assert(newTotalDeposited > oldTotalDeposited);
        assert(newTotalValidators > oldTotalValidators);

        assertEq(newTotalValidators, oldTotalValidators + 5);
        assertEq(newTotalDeposited, oldTotalDeposited + (32 ether * 5));
    }
}
