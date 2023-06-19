/// SPDX: License-Identifier: GPL-3.0-only
pragma solidity 0.8.20;

import "../MevEthTest.sol";
import "src/libraries/Auth.sol";
import "../mocks/DepositContract.sol";
import { IStakingModule } from "../../src/interfaces/IStakingModule.sol";
import "../../src/interfaces/IMevEthShareVault.sol";

contract MevRewardsTest is MevEthTest {
    event Rewards(address sender, uint256 amount);

    function testGrantRewards(uint128 amount) public {
        vm.assume(amount > 10_000);

        address mevShare = mevEth.mevEthShareVault();

        vm.deal(address(this), amount);
        payable(mevShare).send(amount);

        vm.expectEmit();
        emit Rewards(mevShare, amount);
        IMevEthShareVault(mevShare).payRewards(amount);

        uint256 elastic = mevEth.totalAssets();
        uint256 base = mevEth.totalSupply();

        assertGt(elastic, base);
    }
}
