// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/console.sol";
import "../MevEthTest.sol";
import "src/interfaces/Errors.sol";
import "src/MevEthRateProvider.sol";
import "src/interfaces/IMevEth.sol";

contract MevEthRateProviderTest is MevEthTest {
    MevETHRateProvider provider;

    function setUp() public override {
        super.setUp();
        provider = new MevETHRateProvider(IMevEth(address(mevEth)));
    }

    function testRate() public {
        assertEq(provider.getRate(), 1 ether);
    }

    function testRateUpdate() public {
        vm.deal(address(this), 10 ether);
        mevEth.deposit{ value: 10 ether }(10 ether, address(this));
        address staker = address(mevEth.stakingModule());
        vm.deal(staker, 2 ether);
        vm.prank(SamBacha);
        IStakingModule(staker).payRewards();
        assertGt(provider.getRate(), 1 ether);
    }
}
