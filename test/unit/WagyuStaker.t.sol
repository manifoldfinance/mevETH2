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
    }
}
