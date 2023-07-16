/// SPDX: License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/console.sol";
import "../MevEthTest.sol";
import "src/interfaces/Errors.sol";

contract QueueTest is MevEthTest {
  function testOverflowsDepositsToQueue() public {
    vm.deal(User01, 96 ether);
    vm.startPrank(User01);

    IStakingModule.ValidatorData memory validatorData = mockValidatorData(User01, 32 ether / 1 gwei);
    
    // Deposit 1 ETH
    weth.deposit{value: 96 ether}();
    // Approve the mevETH contract to spend 1 ETH
    weth.approve(address(mevEth), 96 ether);

    // Deposit 1 ETH into the mevETH contract
    mevEth.deposit(96 ether, User01);

    vm.stopPrank();
    vm.startPrank(Operator01);
    mevEth.createValidator(validatorData);

    assertEq(address(mevEth).balance, 64 ether);
    (uint128 elastic, uint128 base) = mevEth.fraction();
    assertEq(base, 96 ether);
    assertEq(elastic, 96 ether);

    vm.stopPrank();
    vm.startPrank(User01);
    vm.recordLogs();
    mevEth.withdraw(1 ether, User01, User01);
    //Vm.Log[] memory entries = vm.getRecordedLogs();

    //assertEq(entries[1].topics[0], keccak256("WithdrawalQueueOpened(address,uint256)"));
  }
}
