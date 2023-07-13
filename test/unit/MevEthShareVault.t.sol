/// SPDX: License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../MevEthTest.sol";
import { MevEthShareVault } from "../MevEthShareVault.sol";
import "src/libraries/Auth.sol";
import "../mocks/DepositContract.sol";
import { IStakingModule } from "../../src/interfaces/IStakingModule.sol";
import "../../src/interfaces/IMevEthShareVault.sol";
import "../../lib/safe-tools/src/SafeTestTools.sol";

contract MevEthShareVaultTest is MevEthTest {
    // function setup() {
    //TODO: we need to update this somehow we could do it every test or do it in the setup or something similar
    //     //Update the share vault to MevEthShareVault
    //     address newShareVault = address(new MevEthShareVault(SamBacha, address(mevEth), SamBacha, SamBacha, medianMevPayment, medianValidatorPayment));
    //     _updateShareVault(newShareVault);
    // }

    function testPayRewards(uint256 rewards) public {
        address mevEthShareVault = mevEth.mevEthShareVault();
        _addToProtocolBalance(0, rewards);

        vm.prank(Operator1);
        vm.expectEmit(true, false, false, false, address(mevEthShareVault));
        emit RewardsPaid(amount);
        IMevEthShareVault(mevEthShareVault).payRewards();

        assertEq(IMevEthShareVault(mevEthShareVault).fees(), 0);
        assertEq(IMevEthShareVault(mevEthShareVault).rewards(), 0);
    }

    function testNegativePayRewards(uint256 rewards) public {
        address mevEthShareVault = mevEth.mevEthShareVault();

        _addToProtocolBalance(0, rewards);
        vm.expectRevert(Auth.Unauthorized.selector);
        IMevEthShareVault(mevEthShareVault).payRewards();

        assertEq(IMevEthShareVault(mevEthShareVault).fees(), 0);
        assertEq(IMevEthShareVault(mevEthShareVault).rewards(), rewards);
    }

    function testSendFees(uint256 fees) public {
        address mevEthShareVault = mevEth.mevEthShareVault();

        _addToProtocolBalance(fees, 0);

        vm.prank(SamBacha);
        vm.expectEmit(true, false, false, false, address(mevEthShareVault));
        emit FeesSent(fees);
        IMevEthShareVault(mevEthShareVault).sendFees();

        assertEq(IMevEthShareVault(mevEthShareVault).fees(), 0);
        assertEq(IMevEthShareVault(mevEthShareVault).rewards(), 0);
    }

    function testNegativeSendFees() public {
        address mevEthShareVault = mevEth.mevEthShareVault();

        _addToProtocolBalance(fees, 0);

        vm.expectRevert(Auth.Unauthorized.selector);
        IMevEthShareVault(mevEthShareVault).sendFees();

        //TODO: also test when there is a send error

        assertEq(IMevEthShareVault(mevEthShareVault).fees(), fees);
        assertEq(IMevEthShareVault(mevEthShareVault).rewards(), 0);
    }

    function testSetProtocolFeeTo(address newProtocolFeeTo) public {
        address mevEthShareVault = mevEth.mevEthShareVault();

        vm.prank(SamBacha);
        vm.expectEmit(true, false, false, false, address(mevEthShareVault));
        emit ProtocolFeeToUpdated(newProtocolFeeTo);
        IMevEthShareVault(mevEthShareVault).setProtocolFeeTo(newProtocolFeeTo);

        assertEq(IMevEthShareVault(mevEthShareVault).protocolFeeTo(), newProtocolFeeTo);
    }

    function testNegativeSetProtocolFeeTo(address newProtocolFeeTo) public {
        address mevEthShareVault = mevEth.mevEthShareVault();
        address currentProtocolFeeTo = IMevEthShareVault(mevEthShareVault).protocolFeeTo();

        vm.expectRevert(Auth.Unauthorized.selector);
        IMevEthShareVault(mevEthShareVault).setProtocolFeeTo(newProtocolFeeTo);

        assertEq(IMevEthShareVault(mevEthShareVault).protocolFeeTo(), currentProtocolFeeTo);
    }

    function testLogRewards(uint256 fees, uint256 rewards) public {
        uint256 sum;
        unchecked {
            sum = fees + rewards;
        }
        vm.assume(sum >= fees && sum >= rewards);

        uint256 amount = fees + rewards;

        vm.deal(address(this), amount);
        address mevEthShareVault = mevEth.mevEthShareVault();
        payable(mevEthShareVault).send(amount);

        vm.prank(Operator1);
        vm.expectEmit(true, false, false, false, address(mevEthShareVault));
        emit ProtocolFeeToUpdated(newProtocolFeeTo);
        IMevEthShareVault(mevEthShareVault).logRewards(fees);

        assertEq(IMevEthShareVault(mevEthShareVault).rewards(), fees);
        assertEq(IMevEthShareVault(mevEthShareVault).rewards(), amount);
    }

    function testNegativeLogRewards() public {
        uint256 sum;
        unchecked {
            sum = fees + rewards;
        }
        vm.assume(sum >= fees && sum >= rewards);

        uint256 amount = fees + rewards;

        vm.deal(address(this), amount);
        address mevEthShareVault = mevEth.mevEthShareVault();
        payable(mevEthShareVault).send(amount);

        vm.expectRevert(Auth.Unauthorized.selector);
        IMevEthShareVault(mevEthShareVault).logRewards(fees);

        vm.expectRevert(MevEthShareVault.FeesTooHigh.selector);
        IMevEthShareVault(mevEthShareVault).logRewards(amount + 1);

        assertEq(IMevEthShareVault(mevEthShareVault).rewards(), 0);
        assertEq(IMevEthShareVault(mevEthShareVault).rewards(), 0);
    }

    function recoverToken(uint128 amount) public {
        vm.assume(amount > 10_000);

        address mevEthShareVault = mevEth.mevEthShareVault();

        // Allocate weth to the mevEthSharevault
        vm.deal(address(this), amount);
        weth.deposit{ value: amount }();
        weth.transfer(mevEthShareVault, amount);
        assertEq(weth.balanceOf(mevEthShareVault), amount);

        // Recover the token funds
        vm.expectEmit(true, true, true, false, address(mevEthShareVault));
        emit TokenRecovered(SamBacha, address(weth), amount);
        vm.prank(SamBacha);
        IMevEthShareVault(mevEthShareVault).recoverToken(address(weth), SamBacha, amount);

        // Assert that the balance was removed from the share vault and added to the recipient address
        assertEq(weth.balanceOf(mevEthShareVault), 0);
        assertEq(weth.balanceOf(SamBacha), amount);
    }

    function testNegativeRecoverToken(uint256 amount) public {
        vm.assume(amount > 10_000);

        address mevEthShareVault = mevEth.mevEthShareVault();

        // Allocate weth to the mevEthSharevault
        vm.deal(address(this), amount);
        weth.deposit{ value: amount }();
        weth.transfer(mevEthShareVault, amount);
        assertEq(weth.balanceOf(mevEthShareVault), amount);

        // Expect a revert due to an unaurhtorized error
        vm.expectRevert(Auth.Unauthorized.selector);
        IMevEthShareVault(mevEthShareVault).recoverToken(address(weth), SamBacha, amount);

        // Assert that the balance is still in the mevEthShareVault and the recipient address is still zero
        assertEq(weth.balanceOf(mevEthShareVault), amount);
        assertEq(weth.balanceOf(SamBacha), 0);
    }

    function testReceive(uint256 amount) public {
        vm.deal(address(this), amount);
        address mevEthShareVault = mevEth.mevEthShareVault();
        vm.expectEmit(true, true, true, false, address(mevEthShareVault));
        emit RewardPayment(block.number, block.coinbase, amount);
        payable(mevEthShareVault).send(amount);
    }

    function _addToProtocolBalance(uint256 fees, uint256 rewards) {
        uint256 amount = fees + rewards;

        vm.deal(address(this), amount);
        address mevEthShareVault = mevEth.mevEthShareVault();
        payable(mevEthShareVault).send(amount);

        vm.prank(Operator1);
        IMevEthShareVault(mevEthShareVault).logRewards(fees);

        assertEq(IMevEthShareVault(mevEthShareVault).rewards(), fees);
        assertEq(IMevEthShareVault(mevEthShareVault).rewards(), amount);
    }
}
