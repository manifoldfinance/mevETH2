// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../MevEthTest.sol";

contract CreamRedeemTest is MevEthTest {
    function testRedeemCream(uint128 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < 100_000_000_000_000_000_000_000_000);
        creamToken.mint(address(this), amount);
        creamToken.approve(address(mevEth), amount);
        vm.expectEmit();
        emit CreamRedeemed(address(this), amount, amount * creamRedeem / 100);
        mevEth.redeemCream(amount);
        assertEq(mevEth.balanceOf(address(this)), amount * creamRedeem / 100);
    }

    function testNegativeRedeemCream(uint128 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < 100_000_000_000_000_000_000_000_000);
        vm.expectRevert();
        mevEth.redeemCream(amount);
    }
}
