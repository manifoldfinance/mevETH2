/// SPDX: License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/console.sol";
import "../MevEthTest.sol";
import "src/interfaces/Errors.sol";

contract QueueTest is MevEthTest {
    function testOverflowsDepositsToQueueWithWithdraw() public {
        vm.deal(User01, 64 ether);
        vm.startPrank(User01);

        IStakingModule.ValidatorData memory validatorData = mockValidatorData(User01, 32 ether / 1 gwei);

        // Deposit 64 ETH
        weth.deposit{ value: 64 ether }();
        // Approve the mevETH contract to spend 1 ETH
        weth.approve(address(mevEth), 64 ether);

        // Deposit 64 ETH into the mevETH contract
        mevEth.deposit(64 ether, User01);

        vm.stopPrank();
        vm.startPrank(Operator01);
        mevEth.createValidator(validatorData);

        assertEq(address(mevEth).balance, 32 ether);

        vm.stopPrank();
        vm.startPrank(User01);
        vm.recordLogs();
        mevEth.withdraw(63 ether, User01, User01);
        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries[2].topics[0], keccak256("WithdrawalQueueOpened(address,uint256)"));
        assertEq(uint256(entries[2].topics[2]), 31 ether);

        assertEq(weth.balanceOf(User01), 32 ether);

        // Now that an unprocessed withdrawal has been created
        // time to ensure it can be properly processed back

        vm.stopPrank();
        vm.startPrank(address(mevEth.stakingModule()));

        vm.deal(address(mevEth.stakingModule()), 32 ether);
        IStakingModule(mevEth.stakingModule()).payValidatorWithdraw(32 ether);

        mevEth.processWithdrawalQueue();

        assertEq(weth.balanceOf(User01), 63 ether);
    }

    function testOverflowsDepositsToQueueWithRedeem() public {
        vm.deal(User01, 64 ether);
        vm.startPrank(User01);

        IStakingModule.ValidatorData memory validatorData = mockValidatorData(User01, 32 ether / 1 gwei);

        // Deposit 64 ETH
        weth.deposit{ value: 64 ether }();
        // Approve the mevETH contract to spend 1 ETH
        weth.approve(address(mevEth), 64 ether);

        // Deposit 64 ETH into the mevETH contract
        mevEth.deposit(64 ether, User01);

        vm.stopPrank();
        vm.startPrank(Operator01);
        mevEth.createValidator(validatorData);

        assertEq(address(mevEth).balance, 32 ether);

        vm.stopPrank();
        vm.startPrank(User01);
        vm.recordLogs();
        mevEth.redeem(mevEth.convertToShares(63 ether), User01, User01);
        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries[2].topics[0], keccak256("WithdrawalQueueOpened(address,uint256)"));
        assertEq(uint256(entries[2].topics[2]), 31 ether);

        assertEq(weth.balanceOf(User01), 32 ether);

        // Now that an unprocessed withdrawal has been created
        // time to ensure it can be properly processed back

        vm.stopPrank();
        vm.startPrank(address(mevEth.stakingModule()));

        vm.deal(address(mevEth.stakingModule()), 32 ether);
        IStakingModule(mevEth.stakingModule()).payValidatorWithdraw(32 ether);

        mevEth.processWithdrawalQueue();

        assertEq(weth.balanceOf(User01), 63 ether);
    }
}
