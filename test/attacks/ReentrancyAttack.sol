/// SPDX-License-Identifier: Universal Permissive License v1.0
/// @custom:org.security.mailto='ops@manifoldfinance.com'
/// @custom:org.security.policy=' https://github.com/manifoldfinance/security'
/// @custom:org.security.vcs-url='github.com/manifoldfinance'
/// @custom:org.security.encryption='https://flowcrypt.com/pub/sam@manifoldfinance.com'
/// @custom:org.security.schema-version="2023-08-10T07:40:14-0700"
pragma solidity ^0.8.19;

import "../MevEthTest.sol";

contract ReentrancyAttackTest is MevEthTest {
    uint128 MAX_DEPOSIT = type(uint128).max;

    function setUp() public override {
        super.setUp();
        vm.deal(User02, 0.1 ether);
        vm.prank(User02);
        mevEth.deposit{ value: 0.1 ether }(0.1 ether, address(this));
    }

    // Fallback is called when MevEth sends Ether to this contract.
    fallback() external payable {
        mevEth.withdraw(msg.value, address(this), address(this));
    }

    receive() external payable { }

    function testAttack(uint128 amount) external payable {
        vm.assume(amount > mevEth.MIN_DEPOSIT());
        vm.assume(amount < MAX_DEPOSIT - 0.1 ether);
        vm.deal(address(this), amount);
        uint256 bal = address(this).balance;
        mevEth.deposit{ value: amount }(amount, address(this));
        mevEth.withdraw(amount, address(this), address(this));
        assertEq(weth.balanceOf(address(this)), amount);
        assertEq(address(this).balance, bal - amount);
    }
}
