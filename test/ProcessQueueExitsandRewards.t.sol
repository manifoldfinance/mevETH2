/// SPDX: License-Identifier: MIT
pragma solidity ^0.8.19;

// Test utils
import "forge-std/Test.sol";

import "script/ProcessQueueExitsandRewards.s.sol";

contract ProcessQueueExitsandRewardsTest is Test {
    string RPC_ETH_MAINNET = vm.envString("RPC_MAINNET");
    uint256 FORK_ID;
    ProcessQueueExitsandRewardsScript process;
    IMevEthQueue mevEth = IMevEthQueue(0x24Ae2dA0f361AA4BE46b48EB19C91e02c5e4f27E);

    function setUp() public virtual {
        FORK_ID = vm.createSelectFork(RPC_ETH_MAINNET, 18_977_178);
        process = new ProcessQueueExitsandRewardsScript();
    }

    function testProcessQueueExitsandRewards() public virtual {
        vm.selectFork(FORK_ID);
        vm.deal(0x617c8dE5BdE54ffbb8d92716CC947858cA38f582, 4 * 32 ether + 49 ether);
        vm.deal(address(mevEth), 0.51327282151044822 ether);
        process.run(5);
        assertEq(mevEth.requestsFinalisedUntil(), 150);
    }
}
