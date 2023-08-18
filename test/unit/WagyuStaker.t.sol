/// SPDX: License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../MevEthTest.sol";
import { WagyuStaker } from "src/WagyuStaker.sol";

contract WagyuStakerTest is MevEthTest {
    WagyuStaker wagyuStaker;

    function setUp() public override {
        super.setUp();

        wagyuStaker = WagyuStaker(payable(address(mevEth.stakingModule())));
    }

    function testPayRewards(uint128 amount) public {
        vm.assume(amount > 0);
        vm.deal(address(this), amount);
        payable(wagyuStaker).transfer(amount);

        vm.prank(SamBacha);
        vm.expectEmit(true, false, false, false, address(wagyuStaker));
        emit RewardsPaid(amount);
        wagyuStaker.payRewards(amount);
        (uint128 totalDeposited,, uint128 totalRewardsPaid,) = wagyuStaker.record();
        assertEq(address(wagyuStaker).balance - totalDeposited, 0);
        assertEq(totalRewardsPaid, amount);
    }

    function testNegativePayRewards(uint128 amount) public {
        vm.assume(amount > 0);
        vm.deal(address(this), amount);
        payable(wagyuStaker).transfer(amount);

        vm.expectRevert(Auth.Unauthorized.selector);
        wagyuStaker.payRewards(amount);
        (uint128 totalDeposited,,,) = wagyuStaker.record();
        assertEq(address(wagyuStaker).balance - totalDeposited, amount);
    }

    function testSetNewMevEth(address newMevEth) public {
        vm.assume(newMevEth != address(0));

        vm.prank(SamBacha);
        vm.expectEmit(true, false, false, false, address(wagyuStaker));
        emit MevEthUpdated(newMevEth);
        wagyuStaker.setNewMevEth(newMevEth);

        assertEq(wagyuStaker.mevEth(), newMevEth);
    }

    function testNegativeSetNewMevEth(address newMevEth) public {
        address currentMevEth = wagyuStaker.mevEth();

        vm.expectRevert(Auth.Unauthorized.selector);
        wagyuStaker.setNewMevEth(newMevEth);
        assertEq(wagyuStaker.mevEth(), currentMevEth);

        vm.expectRevert(MevEthErrors.ZeroAddress.selector);
        vm.prank(SamBacha);
        wagyuStaker.setNewMevEth(address(0));
        assertEq(wagyuStaker.mevEth(), currentMevEth);
    }

    function testPayValidatorWithdrawGt32Ether(uint128 amount) public {
        vm.assume(amount > 32 ether);

        vm.deal(address(wagyuStaker), amount);
        vm.deal(address(this), amount);

        _mockMevEthDeposit(amount, address(this));
        (uint128 elasticBefore, uint128 baseBefore) = mevEth.fraction();
        assertEq(elasticBefore, amount);
        assertEq(baseBefore, amount);

        vm.expectEmit(true, true, false, false, address(mevEth));
        emit ValidatorWithdraw(address(wagyuStaker), amount);
        vm.expectEmit(true, true, false, false, address(wagyuStaker));
        emit ValidatorWithdraw(SamBacha, amount);
        vm.prank(SamBacha);
        wagyuStaker.payValidatorWithdraw();

        (uint128 elasticAfter, uint128 baseAfter) = mevEth.fraction();
        assertEq(elasticAfter, elasticBefore);
        assertEq(baseAfter, baseBefore);
        assertEq(address(wagyuStaker).balance, amount - 32 ether);
        assertGt(address(mevEth).balance, 32 ether);
    }

    function testPayValidatorWithdrawLt32Ether(uint128 amount) public {
        vm.assume(amount > 0 && amount < 32 ether);
        // Assume that the amount is greater than the minimum deposit amount
        vm.assume(amount >= mevEth.MIN_DEPOSIT());

        vm.deal(address(wagyuStaker), amount);
        vm.deal(address(this), amount);

        _mockMevEthDeposit(amount, address(this));
        (uint128 elasticBefore, uint128 baseBefore) = mevEth.fraction();
        assertEq(elasticBefore, amount);
        assertEq(baseBefore, amount);

        vm.prank(SamBacha);
        vm.expectRevert(MevEthErrors.NotEnoughEth.selector);
        wagyuStaker.payValidatorWithdraw();

        (uint128 elasticAfter, uint128 baseAfter) = mevEth.fraction();
        assertEq(elasticAfter, elasticBefore);
        assertEq(baseAfter, baseBefore);
    }

    function testPayValidatorWithdrawEq32Ether() public {
        uint128 amount = 32 ether;
        vm.deal(address(wagyuStaker), amount);

        (uint256 elasticBefore, uint256 baseBefore) = mevEth.fraction();

        vm.expectEmit(true, true, false, false, address(mevEth));
        emit ValidatorWithdraw(address(wagyuStaker), amount);
        vm.expectEmit(true, true, false, false, address(wagyuStaker));
        emit ValidatorWithdraw(SamBacha, amount);
        vm.prank(SamBacha);
        wagyuStaker.payValidatorWithdraw();

        (uint256 elasticAfter, uint256 baseAfter) = mevEth.fraction();

        assertEq(elasticAfter, elasticBefore);
        assertEq(baseAfter, baseBefore);
    }

    function testNegativePayValidatorWithdraw() public {
        // Expect Unauthorized
        vm.expectRevert(Auth.Unauthorized.selector);
        wagyuStaker.payValidatorWithdraw();

        // Expect ZeroValue error
        vm.prank(SamBacha);
        vm.expectRevert(MevEthErrors.NotEnoughEth.selector);
        wagyuStaker.payValidatorWithdraw();

        // Configure MevEth elastic and base to uint128 max
        uint256 amount = type(uint128).max;
        vm.deal(address(wagyuStaker), amount);
        vm.deal(address(this), amount);
        _mockMevEthDeposit(amount, address(this));

        (uint256 elastic, uint256 base) = mevEth.fraction();
        assertEq(elastic, amount);
        assertEq(base, amount);
    }

    function _mockMevEthDeposit(uint256 amount, address receiver) internal {
        weth.deposit{ value: amount }();
        weth.approve(address(mevEth), amount);
        mevEth.deposit(amount, receiver);
    }
}
