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
        vm.deal(address(this), amount);
        payable(wagyuStaker).transfer(amount);

        vm.prank(SamBacha);
        vm.expectEmit(true, false, false, false, address(wagyuStaker));
        emit RewardsPaid(amount);
        wagyuStaker.payRewards();

        assertEq(address(wagyuStaker).balance - wagyuStaker.balance(), 0);
    }

    function testNegativePayRewards(uint128 amount) public {
        vm.deal(address(this), amount);
        payable(wagyuStaker).transfer(amount);

        vm.expectRevert(Auth.Unauthorized.selector);
        wagyuStaker.payRewards();

        assertEq(address(wagyuStaker).balance - wagyuStaker.balance(), amount);
    }

    function testSetNewBeneficiary(address newBeneficiary) public {
        vm.assume(newBeneficiary != address(0));

        vm.prank(SamBacha);
        vm.expectEmit(true, false, false, false, address(wagyuStaker));
        emit BeneficiaryUpdated(newBeneficiary);
        wagyuStaker.setNewBeneficiary(newBeneficiary);

        assertEq(wagyuStaker.beneficiary(), newBeneficiary);
    }

    function testNegativeSetNewBeneficiary(address newBeneficiary) public {
        address currentBeneficiary = wagyuStaker.beneficiary();

        vm.expectRevert(Auth.Unauthorized.selector);
        wagyuStaker.setNewBeneficiary(newBeneficiary);
        assertEq(wagyuStaker.beneficiary(), currentBeneficiary);

        vm.expectRevert(MevEthErrors.ZeroAddress.selector);
        vm.prank(SamBacha);
        wagyuStaker.setNewBeneficiary(address(0));
        assertEq(wagyuStaker.beneficiary(), currentBeneficiary);
    }

    function testPayValidatorWithdrawGt32Ether(uint128 amount) public {
        vm.assume(amount > 32 ether && amount < type(uint128).max);
        // Assume that the amount is greater than the minimum deposit amount
        vm.assume(amount >= mevEth.MIN_DEPOSIT());

        vm.deal(address(wagyuStaker), amount);
        vm.deal(address(this), amount);

        _mockMevEthDeposit(amount, address(this));
        (uint128 elasticBefore, uint128 baseBefore) = mevEth.fraction();
        assertEq(elasticBefore, amount);
        assertEq(baseBefore, amount);

        uint128 expectedElastic;
        unchecked {
            expectedElastic = elasticBefore + uint128(amount - 32 ether);
        }
        // Make sure that the amount does not overflow the elastic
        vm.assume(expectedElastic >= elasticBefore);

        vm.expectEmit(true, true, false, false, address(mevEth));
        emit ValidatorWithdraw(address(wagyuStaker), amount);
        vm.expectEmit(true, true, false, false, address(wagyuStaker));
        emit ValidatorWithdraw(SamBacha, amount);
        vm.prank(SamBacha);
        wagyuStaker.payValidatorWithdraw(amount);

        (uint128 elasticAfter, uint128 baseAfter) = mevEth.fraction();
        assertEq(elasticAfter, expectedElastic);
        assertEq(baseAfter, baseBefore);
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

        uint128 expectedElastic;
        unchecked {
            expectedElastic = elasticBefore - uint128(32 ether - amount);
        }
        // Make sure that the amount does not underflow the elastic
        vm.assume(expectedElastic < elasticBefore);

        vm.expectEmit(true, true, false, false, address(mevEth));
        emit ValidatorWithdraw(address(wagyuStaker), amount);
        vm.expectEmit(true, true, false, false, address(wagyuStaker));
        emit ValidatorWithdraw(SamBacha, amount);
        vm.prank(SamBacha);
        wagyuStaker.payValidatorWithdraw(amount);

        (uint128 elasticAfter, uint128 baseAfter) = mevEth.fraction();
        assertEq(elasticAfter, expectedElastic);
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
        wagyuStaker.payValidatorWithdraw(amount);

        (uint256 elasticAfter, uint256 baseAfter) = mevEth.fraction();

        assertEq(elasticAfter, elasticBefore);
        assertEq(baseAfter, baseBefore);
    }

    function testNegativePayValidatorWithdraw() public {
        uint128 minDeposit = mevEth.MIN_DEPOSIT();
        // Expect Unauthorized
        vm.expectRevert(Auth.Unauthorized.selector);
        wagyuStaker.payValidatorWithdraw(minDeposit);

        // Expect ZeroValue error
        vm.prank(SamBacha);
        vm.expectRevert(MevEthErrors.ZeroValue.selector);
        wagyuStaker.payValidatorWithdraw(0);

        // Configure MevEth elastic and base to uint128 max
        uint256 amount = type(uint128).max;
        vm.deal(address(wagyuStaker), amount);
        vm.deal(address(this), amount);
        _mockMevEthDeposit(amount, address(this));

        (uint256 elastic, uint256 base) = mevEth.fraction();
        assertEq(elastic, amount);
        assertEq(base, amount);

        // Expect overflow when msg.value > 32 eth and elastic + msg.value - 32 ether > max uint128
        vm.prank(SamBacha);
        vm.expectRevert(stdError.arithmeticError);
        wagyuStaker.payValidatorWithdraw(33 ether);
    }

    function _mockMevEthDeposit(uint256 amount, address receiver) internal {
        weth.deposit{ value: amount }();
        weth.approve(address(mevEth), amount);
        mevEth.deposit(amount, receiver);
    }
}
