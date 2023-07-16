/// SPDX: License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../MevEthTest.sol";

contract ReentrancyAttackTest is MevEthTest {
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
