/// SPDX: License-Identifier: MIT
pragma solidity 0.8.19;

// Test utils
import "forge-std/Test.sol";

// Deploy script
import "script/DeployOFT.s.sol";

contract DeployOFTTest is Test {
    string POLYGON_MAINNET_RPC_URL = vm.envString("POLYGON_MAINNET_RPC_URL");
    string ARBITRUM_MAINNET_RPC_URL = vm.envString("ARBITRUM_MAINNET_RPC_URL");
    string BSC_MAINNET_RPC_URL = vm.envString("BSC_MAINNET_RPC_URL");
    string AVALANCHE_RPC_URL = vm.envString("AVALANCHE_RPC_URL");
    string OPTIMISM_RPC_URL = vm.envString("OPTIMISM_RPC_URL");
    uint256 POLY;
    uint256 BSC;
    uint256 ARB;
    uint256 AVA;
    uint256 OPT;
    DeployScript deploy;

    function setUp() public virtual {
        POLY = vm.createSelectFork(POLYGON_MAINNET_RPC_URL);
        ARB = vm.createSelectFork(ARBITRUM_MAINNET_RPC_URL);
        BSC = vm.createSelectFork(BSC_MAINNET_RPC_URL);
        AVA = vm.createSelectFork(AVALANCHE_RPC_URL);
        OPT = vm.createSelectFork(OPTIMISM_RPC_URL);
    }

    function _deploy(uint256 forkId) internal {
        vm.selectFork(forkId);
        deploy = new DeployScript();
        deploy.run();
    }

    function testDeployArbitrum() public virtual {
        _deploy(ARB);
    }

    function testDeployOptimism() public virtual {
        _deploy(OPT);
    }

    function testDeployAvalanche() public virtual {
        _deploy(AVA);
    }

    function testDeployBsc() public virtual {
        _deploy(BSC);
    }

    function testDeployPolygon() public virtual {
        _deploy(POLY);
    }
}
