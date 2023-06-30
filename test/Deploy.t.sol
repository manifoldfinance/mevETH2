/// SPDX: License-Identifier: MIT
pragma solidity 0.8.20;

// Test utils
import "forge-std/Test.sol";

// Deploy script
import "script/Deploy.s.sol";

contract DeployTest is Test {
    string RPC_ETH_MAINNET = vm.envString("RPC_MAINNET");
    uint256 FORK_ID;
    DeployScript deploy;

    function setUp() public virtual {
        FORK_ID = vm.createSelectFork(RPC_ETH_MAINNET);
        deploy = new DeployScript();
    }

    function testDeploy() public virtual {
        vm.selectFork(FORK_ID);
        deploy.run();
    }
}
