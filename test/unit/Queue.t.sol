/// SPDX: License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/console.sol";
import "../MevEthTest.sol";
import "src/interfaces/Errors.sol";

contract QueueTest is MevEthTest {
    function setUp() public override {
        super.setUp();
    }

    function testOverflowsDepositsToQueueWithLeave() public {
        vm.deal(User01, 64 ether);
        vm.startPrank(User01);
        address stakingModuleAddress = address(mevEth.stakingModule());

        IStakingModule.ValidatorData memory validatorData = mockValidatorData(User01, 32 ether / 1 gwei);

        // Deposit 64 ETH
        weth.deposit{ value: 64 ether }();
        // Approve the mevETH contract to spend 1 ETH
        weth.approve(address(mevEth), 64 ether);

        // Deposit 64 ETH into the mevETH contract
        mevEth.deposit(64 ether, User01);

        vm.stopPrank();
        vm.startPrank(Operator01);
        mevEth.createValidator(validatorData, latestDepositRoot());

        assertEq(address(mevEth).balance, 32 ether);

        vm.stopPrank();
        vm.startPrank(User01);
        vm.recordLogs();

        mevEth.withdrawQueue(63 ether, User01, User01);
        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries[1].topics[0], keccak256("WithdrawalQueueOpened(address,uint256,uint256)"));
        assertEq(abi.decode(entries[1].data, (uint256)), 31 ether);

        assertEq(weth.balanceOf(User01), 32 ether);

        // Now that an unprocessed withdrawal has been created
        // time to ensure it can be properly processed back

        vm.stopPrank();

        vm.deal(stakingModuleAddress, 32 ether);
        vm.prank(SamBacha);
        IStakingModule(stakingModuleAddress).payValidatorWithdraw(32 ether);
        vm.startPrank(Operator01);
        mevEth.processWithdrawalQueue(mevEth.queueLength());

        mevEth.claim(1);
        Vm.Log[] memory entries2 = vm.getRecordedLogs();

        assertEq(entries2[2].topics[0], keccak256("WithdrawalQueueClosed(address,uint256,uint256)"));
        assertEq(abi.decode(entries2[2].data, (uint256)), 31 ether);

        assertEq(weth.balanceOf(User01), 63 ether);
    }
}
