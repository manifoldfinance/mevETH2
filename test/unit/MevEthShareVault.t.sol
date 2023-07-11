/// SPDX: License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../MevEthTest.sol";
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

    function testPayRewards() public { }

    function testNegativePayRewards() public { }

    function testSendFees() public { }

    function testNegativeSendFees() public { }

    function testSetProtocolFeeTo(address newProtocolFeeTo) public {
        address mevEthShareVault = mevEth.mevEthShareVault();

        // vm.expectEmit(true, false, false, false, address(mevEthShareVault));
        // emit EventHere(newProtocolFeeTo);
        vm.prank(SamBacha);
        IMevEthShareVault(mevEthShareVault).setProtocolFeeTo(newProtocolFeeTo);

        //TODO: assert effects
    }

    function testNegativeSetProtocolFeeTo(address newProtocolFeeTo) public {
        address mevEthShareVault = mevEth.mevEthShareVault();
        vm.expectRevert(Auth.Unauthorized.selector);
        IMevEthShareVault(mevEthShareVault).setProtocolFeeTo(newProtocolFeeTo);

        //TODO: assert effects
    }

    function testLogRewards() public { }

    function testNegativeLogRewards() public { }

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

    function testReceive() public { }

    function testNegativeReceive() public { }
}
