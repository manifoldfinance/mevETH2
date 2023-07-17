/// SPDX: License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../MevEthTest.sol";
import { IStakingModule } from "../../src/interfaces/IStakingModule.sol";

contract MevValidatorRefundTest is MevEthTest {
    function testGrantValidatorWithdraw() public {
        uint256 amount = 32 ether;
        address staker = address(mevEth.stakingModule());

        vm.deal(address(this), amount);
        payable(staker).transfer(amount);

        uint256 elastic = mevEth.totalAssets();
        uint256 base = mevEth.totalSupply();

        vm.expectEmit();
        emit ValidatorWithdraw(staker, amount);
        vm.prank(SamBacha);
        IStakingModule(staker).payValidatorWithdraw(amount);

        assertEq(elastic, mevEth.totalAssets());
        assertEq(base, mevEth.totalSupply());
    }
}
