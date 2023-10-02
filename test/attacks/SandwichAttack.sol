/// SPDX: License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

import "../MevEthTest.sol";

contract SandwichAttackTest is MevEthTest {
    uint128 MAX_DEPOSIT = type(uint128).max;

    function setUp() public override {
        super.setUp();
        vm.deal(User02, 0.1 ether);
        vm.prank(User02);
        mevEth.deposit{ value: 0.1 ether }(0.1 ether, address(this));
    }

    function testSandwichAttack(uint128 amount) external payable {
        vm.assume(amount > mevEth.MIN_DEPOSIT() * 10_002 / 10_000);
        vm.assume(amount < 100_000_000_000_000_000_000_000_000);
        vm.deal(address(this), 2 * amount);

        mevEth.deposit{ value: amount }(amount, address(this));
        payable(address(mevEth.stakingModule())).transfer(amount);
        vm.prank(address(mevEth.stakingModule()));
        mevEth.grantRewards{ value: amount }();
        vm.expectRevert(MevEthErrors.SandwichProtection.selector);
        mevEth.withdraw(amount * 9999 / 10_000, address(this), address(this));
    }

    function testSandwichTransferAttack(uint128 amount) external payable {
        vm.assume(amount > mevEth.MIN_DEPOSIT() * 10_002 / 10_000);
        vm.assume(amount < 100_000_000_000_000_000_000_000_000);
        vm.deal(address(this), 2 * amount);

        uint256 shares = mevEth.deposit{ value: amount }(amount, address(this));
        payable(address(mevEth.stakingModule())).transfer(amount);
        vm.prank(address(mevEth.stakingModule()));
        mevEth.grantRewards{ value: amount }();
        mevEth.transfer(User03, shares);
        vm.expectRevert(MevEthErrors.SandwichProtection.selector);
        vm.prank(User03);
        mevEth.redeem(shares, User03, User03);
    }

    function testSandwichApproveAttack(uint128 amount) external payable {
        vm.assume(amount > mevEth.MIN_DEPOSIT() * 10_002 / 10_000);
        vm.assume(amount < 100_000_000_000_000_000_000_000_000);
        vm.deal(address(this), 2 * amount);

        uint256 shares = mevEth.deposit{ value: amount }(amount, address(this));
        payable(address(mevEth.stakingModule())).transfer(amount);
        vm.prank(address(mevEth.stakingModule()));
        mevEth.grantRewards{ value: amount }();
        mevEth.approve(User03, shares);
        vm.expectRevert(MevEthErrors.SandwichProtection.selector);
        address me = address(this);
        vm.prank(User03);
        mevEth.redeem(shares, User03, me);
    }

    function testSandwichRecieveAttack(uint128 amount) external payable {
        vm.assume(amount > mevEth.MIN_DEPOSIT() * 10_002 / 10_000);
        vm.assume(amount < 100_000_000_000_000_000_000_000_000);
        vm.deal(address(this), 2 * amount);

        uint256 shares = mevEth.deposit{ value: amount }(amount, User03);
        payable(address(mevEth.stakingModule())).transfer(amount);
        vm.prank(address(mevEth.stakingModule()));
        mevEth.grantRewards{ value: amount }();
        vm.expectRevert(MevEthErrors.SandwichProtection.selector);
        address me = address(this);
        vm.prank(User03);
        mevEth.redeem(shares, me, User03);
    }
}
