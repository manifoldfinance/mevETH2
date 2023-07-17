/// SPDX: License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../MevEthTest.sol";
import { MevEthShareVault } from "src/MevEthShareVault.sol";
import { Empty } from "test/mocks/Empty.sol";
import "src/libraries/Auth.sol";
import "../mocks/DepositContract.sol";
import { IStakingModule } from "../../src/interfaces/IStakingModule.sol";
import "../../src/interfaces/IMevEthShareVault.sol";
import "../../lib/safe-tools/src/SafeTestTools.sol";

contract MevEthShareVaultTest is MevEthTest {
    MevEthShareVault mevEthShareVault;

    function setUp() public override {
        super.setUp();

        //Update the share vault to MevEthShareVault
        address newShareVault = address(new MevEthShareVault(SamBacha, address(mevEth), SamBacha, SamBacha));
        _updateShareVault(newShareVault);

        mevEthShareVault = MevEthShareVault(payable(mevEth.mevEthShareVault()));
        vm.prank(SamBacha);
        mevEthShareVault.addOperator(Operator01);
    }

    function testPayRewards(uint128 rewards) public {
        _addToProtocolBalance(0, rewards);

        vm.prank(Operator01);
        vm.expectEmit(true, false, false, false, address(mevEthShareVault));
        emit RewardsPaid(rewards);
        mevEthShareVault.payRewards();

        assertEq(mevEthShareVault.fees(), 0);
        assertEq(mevEthShareVault.rewards(), 0);

        assertEq(address(mevEth).balance, rewards);
    }

    function testNegativePayRewards(uint128 rewards) public {
        _addToProtocolBalance(0, rewards);
        vm.expectRevert(Auth.Unauthorized.selector);
        mevEthShareVault.payRewards();

        assertEq(mevEthShareVault.fees(), 0);
        assertEq(mevEthShareVault.rewards(), rewards);

        assertEq(address(mevEth).balance, 0);
    }

    function testSendFees(uint128 fees) public {
        _addToProtocolBalance(fees, 0);

        vm.prank(SamBacha);
        vm.expectEmit(true, false, false, false, address(mevEthShareVault));
        emit FeesSent(fees);
        IMevEthShareVault(mevEthShareVault).sendFees();

        assertEq(mevEthShareVault.fees(), 0);
        assertEq(mevEthShareVault.rewards(), 0);

        assertEq(mevEthShareVault.protocolFeeTo().balance, fees);
    }

    function testNegativeSendFees(uint128 fees) public {
        _addToProtocolBalance(fees, 0);

        vm.expectRevert(Auth.Unauthorized.selector);
        mevEthShareVault.sendFees();

        address newProtocolFeeTo = address(new Empty());
        vm.prank(SamBacha);
        mevEthShareVault.setProtocolFeeTo(newProtocolFeeTo);

        vm.prank(SamBacha);
        vm.expectRevert(MevEthShareVault.SendError.selector);
        mevEthShareVault.sendFees();

        assertEq(mevEthShareVault.fees(), fees);
        assertEq(mevEthShareVault.rewards(), 0);
        assertEq(mevEthShareVault.protocolFeeTo().balance, 0);
    }

    function testSetProtocolFeeTo(address newProtocolFeeTo) public {
        vm.prank(SamBacha);
        vm.expectEmit(true, false, false, false, address(mevEthShareVault));
        emit ProtocolFeeToUpdated(newProtocolFeeTo);
        mevEthShareVault.setProtocolFeeTo(newProtocolFeeTo);

        assertEq(mevEthShareVault.protocolFeeTo(), newProtocolFeeTo);
    }

    function testNegativeSetProtocolFeeTo(address newProtocolFeeTo) public {
        address currentProtocolFeeTo = mevEthShareVault.protocolFeeTo();

        vm.expectRevert(Auth.Unauthorized.selector);
        mevEthShareVault.setProtocolFeeTo(newProtocolFeeTo);

        assertEq(mevEthShareVault.protocolFeeTo(), currentProtocolFeeTo);
    }

    function testLogRewards(uint128 fees, uint128 rewards) public {
        uint256 sum;
        unchecked {
            sum = fees + rewards;
        }
        vm.assume(sum >= fees && sum >= rewards);

        uint256 amount = fees + rewards;

        vm.deal(address(mevEthShareVault), amount);

        vm.prank(Operator01);
        vm.expectEmit(true, true, false, false, address(mevEthShareVault));
        emit RewardsCollected(fees, rewards);
        mevEthShareVault.logRewards(fees);

        assertEq(mevEthShareVault.fees(), fees);
        assertEq(mevEthShareVault.rewards(), rewards);
    }

    function testNegativeLogRewards(uint128 fees, uint128 rewards) public {
        uint128 sum;
        unchecked {
            sum = fees + rewards;
        }
        vm.assume(sum >= fees && sum >= rewards && fees + rewards < type(uint128).max - 1);

        uint128 amount = fees + rewards;

        vm.deal(address(mevEthShareVault), amount);

        vm.expectRevert(Auth.Unauthorized.selector);
        mevEthShareVault.logRewards(fees);

        vm.expectRevert(MevEthShareVault.FeesTooHigh.selector);
        vm.prank(Operator01);
        mevEthShareVault.logRewards(amount + 1);

        assertEq(mevEthShareVault.fees(), 0);
        assertEq(mevEthShareVault.rewards(), 0);
    }

    function recoverToken(uint128 amount) public {
        vm.assume(amount > 10_000);

        // Allocate weth to the mevEthSharevault
        vm.deal(address(this), amount);
        weth.deposit{ value: amount }();
        weth.transfer(address(mevEthShareVault), amount);
        assertEq(weth.balanceOf(address(mevEthShareVault)), amount);

        // Recover the token funds
        vm.expectEmit(true, true, true, false, address(mevEthShareVault));
        emit TokenRecovered(SamBacha, address(weth), amount);
        vm.prank(SamBacha);
        mevEthShareVault.recoverToken(address(weth), SamBacha, amount);

        // Assert that the balance was removed from the share vault and added to the recipient address
        assertEq(weth.balanceOf(address(mevEthShareVault)), 0);
        assertEq(weth.balanceOf(SamBacha), amount);
    }

    function testNegativeRecoverToken(uint256 amount) public {
        vm.assume(amount > 10_000);

        // Allocate weth to the mevEthSharevault
        vm.deal(address(this), amount);
        weth.deposit{ value: amount }();
        weth.transfer(address(mevEthShareVault), amount);
        assertEq(weth.balanceOf(address(mevEthShareVault)), amount);

        // Expect a revert due to an unaurhtorized error
        vm.expectRevert(Auth.Unauthorized.selector);
        mevEthShareVault.recoverToken(address(weth), SamBacha, amount);

        // Assert that the balance is still in the mevEthShareVault and the recipient address is still zero
        assertEq(weth.balanceOf(address(mevEthShareVault)), amount);
        assertEq(weth.balanceOf(SamBacha), 0);
    }

    function testReceive(uint256 amount) public {
        vm.deal(address(this), amount);
        vm.expectEmit(true, true, true, false, address(mevEthShareVault));
        emit RewardPayment(block.number, block.coinbase, amount);
        payable(mevEthShareVault).transfer(amount);
    }

    function testSetNewBeneficiary(address newBeneficiary) public {
        vm.prank(SamBacha);
        vm.expectEmit(true, false, false, false, address(mevEthShareVault));
        emit BeneficiaryUpdated(newBeneficiary);
        mevEthShareVault.setNewBeneficiary(newBeneficiary);
        assertEq(mevEthShareVault.beneficiary(), newBeneficiary);
    }

    function testNegativeSetNewBeneficiary(address newBeneficiary) public {
        address currentBeneficiary = mevEthShareVault.beneficiary();

        vm.expectRevert(Auth.Unauthorized.selector);
        mevEthShareVault.setNewBeneficiary(newBeneficiary);
        assertEq(mevEthShareVault.beneficiary(), currentBeneficiary);
    }

    function _addToProtocolBalance(uint128 fees, uint128 rewards) internal {
        uint256 amount = fees + rewards;

        vm.deal(address(this), amount);
        payable(mevEthShareVault).transfer(amount);

        vm.prank(Operator01);
        mevEthShareVault.logRewards(fees);

        assertEq(mevEthShareVault.fees(), fees);
        assertEq(mevEthShareVault.rewards(), rewards);
    }

    function testPayValidatorWithdrawGt32Ether(uint128 amount) public {
        vm.assume(amount > 32 ether && amount < type(uint128).max);
        // Assume that the amount is greater than the minimum deposit amount
        vm.assume(amount >= mevEth.MIN_DEPOSIT());

        vm.deal(address(mevEthShareVault), amount);
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

        vm.prank(SamBacha);
        mevEthShareVault.payValidatorWithdraw(amount);

        (uint128 elasticAfter, uint128 baseAfter) = mevEth.fraction();
        assertEq(elasticAfter, expectedElastic);
        assertEq(baseAfter, baseBefore);
    }

    function testPayValidatorWithdrawLt32Ether(uint128 amount) public {
        vm.assume(amount > 0 && amount < 32 ether);
        // Assume that the amount is greater than the minimum deposit amount
        vm.assume(amount >= mevEth.MIN_DEPOSIT());

        vm.deal(address(mevEthShareVault), amount);
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

        vm.prank(SamBacha);
        mevEthShareVault.payValidatorWithdraw(amount);

        (uint128 elasticAfter, uint128 baseAfter) = mevEth.fraction();
        assertEq(elasticAfter, expectedElastic);
        assertEq(baseAfter, baseBefore);
    }

    function testPayValidatorWithdrawEq32Ether() public {
        uint128 amount = 32 ether;
        vm.deal(address(mevEthShareVault), amount);

        (uint256 elasticBefore, uint256 baseBefore) = mevEth.fraction();

        vm.prank(SamBacha);
        mevEthShareVault.payValidatorWithdraw(amount);

        (uint256 elasticAfter, uint256 baseAfter) = mevEth.fraction();

        assertEq(elasticAfter, elasticBefore);
        assertEq(baseAfter, baseBefore);
    }

    function testNegativePayValidatorWithdraw() public {
        uint128 minDeposit = mevEth.MIN_DEPOSIT();
        // Expect Unauthorized
        vm.expectRevert(Auth.Unauthorized.selector);
        mevEthShareVault.payValidatorWithdraw(minDeposit);

        // Expect ZeroValue error
        vm.prank(SamBacha);
        vm.expectRevert(MevEthErrors.ZeroValue.selector);
        mevEthShareVault.payValidatorWithdraw(0);

        // Configure MevEth elastic and base to uint128 max
        uint256 amount = type(uint128).max;
        vm.deal(address(mevEthShareVault), amount);
        vm.deal(address(this), amount);
        _mockMevEthDeposit(amount, address(this));

        (uint256 elastic, uint256 base) = mevEth.fraction();
        assertEq(elastic, amount);
        assertEq(base, amount);

        // Expect overflow when msg.value > 32 eth and elastic + msg.value - 32 ether > max uint128
        vm.prank(SamBacha);
        vm.expectRevert(stdError.arithmeticError);
        mevEthShareVault.payValidatorWithdraw(33 ether);
    }

    function _mockMevEthDeposit(uint256 amount, address receiver) internal {
        weth.deposit{ value: amount }();
        weth.approve(address(mevEth), amount);
        mevEth.deposit(amount, receiver);
    }
}
