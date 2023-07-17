/// SPDX: License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../MevEthTest.sol";

contract ReentrancyAttackTest is MevEthTest {
    function setUp() override public {
        super.setUp();
        vm.deal(User02, 0.1 ether);
        vm.prank(User02);
        mevEth.deposit{value: 0.1 ether}(0.1 ether, address(this));
    }

    // Fallback is called when MevEth sends Ether to this contract.
    fallback() external payable {
        mevEth.withdraw(msg.value, address(this), address(this));
    }

    receive() external payable { }

    function testAttack(uint128 amount) external payable {
        vm.assume(amount > mevEth.MIN_DEPOSIT());
        vm.deal(address(this), amount);
        uint256 bal = address(this).balance;
        mevEth.deposit{ value: amount }(amount, address(this));
        mevEth.withdraw(amount, address(this), address(this));
        assertEq(weth.balanceOf(address(this)), amount);
        assertEq(address(this).balance, bal - amount);
    }
}
