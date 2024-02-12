/// SPDX: License-Identifier: MIT
pragma solidity ^0.8.19;

// Test utils
import "forge-std/Test.sol";

// Deploy script
import "script/DeployStaker.s.sol";

contract DeployStakerTest is Test {
    string RPC_ETH_MAINNET = vm.envString("RPC_MAINNET");
    uint256 FORK_ID;
    DeployStakerScript deploy;

    function setUp() public virtual {
        FORK_ID = vm.createSelectFork(RPC_ETH_MAINNET);
        deploy = new DeployStakerScript();
    }

    function testDeployStaker() public virtual {
        vm.selectFork(FORK_ID);
        deploy.run();
    }
}
