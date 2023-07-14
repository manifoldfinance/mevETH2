// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import { LayerZeroHelper } from "pigeon/layerzero/LayerZeroHelper.sol";
import "../MevEthTest.sol";
import "src/interfaces/Errors.sol";
import "src/interfaces/ICommonOFT.sol";

contract LayerZeroPigeonTest is MevEthTest {
    LayerZeroHelper lzHelper;
    OFTV2 public polyMevEth;
    OFTV2 public arbMevEth;

    string constant name = "Mev Liquid Staked Ether";
    string constant symbol = "mevETH";

    uint256 L1_FORK_ID;
    uint256 POLYGON_FORK_ID;
    uint256 ARBITRUM_FORK_ID;

    address constant mainnetDepositContract = 0x00000000219ab540356cBB839Cbe05303d7705Fa;
    address constant mainnetWeth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant L1_lzEndpoint = 0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675;
    address constant polygonEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address constant arbitrumEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;

    address[] public allDstTargets;
    address[] public allDstEndpoints;
    uint16[] public allDstChainIds;
    uint256[] public allDstForks;

    string RPC_ETH_MAINNET = vm.envString("ETH_MAINNET_RPC_URL");
    string RPC_POLYGON_MAINNET = vm.envString("POLYGON_MAINNET_RPC_URL");
    string RPC_ARBITRUM_MAINNET = vm.envString("ARBITRUM_MAINNET_RPC_URL");

    function setUp() public override {
        super.setUp();
        L1_FORK_ID = vm.createSelectFork(RPC_ETH_MAINNET);
        lzHelper = new LayerZeroHelper();

        // deploy mevEth (mainnet)
        mevEth = new MevEth(SamBacha, mainnetWeth, L1_lzEndpoint);

        ARBITRUM_FORK_ID = vm.createSelectFork(RPC_ARBITRUM_MAINNET);
        arbMevEth = new OFTV2(name, symbol, 18, 8, SamBacha, arbitrumEndpoint);

        // set trusted remotes
        vm.prank(SamBacha);
        arbMevEth.setTrustedRemote(ETH_ID, abi.encodePacked(address(mevEth), address(arbMevEth)));

        vm.selectFork(L1_FORK_ID);
        vm.prank(SamBacha);
        mevEth.setTrustedRemote(ARBITRUM_ID, abi.encodePacked(address(arbMevEth), address(mevEth)));
    }

    /// @notice test send mevEth token cross chain through mock lz endpoint
    function testSendFromPigeon() public {
        vm.selectFork(L1_FORK_ID);
        uint256 amount = 1 ether;
        vm.deal(User01, amount * 2);
        vm.deal(User02, amount * 2);
        vm.startPrank(User01);

        // Deposit 1 ETH into the mevETH contract
        mevEth.deposit{ value: amount }(amount, User01);

        // Check that the mevETH contract has 1 ETH
        assertEq(address(mevEth).balance, amount);

        // Check the user has 1 mevETH
        assertEq(mevEth.balanceOf(User01), amount);

        // setup call params
        ICommonOFT.LzCallParams memory callParams;
        callParams.refundAddress = payable(User01);
        callParams.zroPaymentAddress = address(0);
        callParams.adapterParams = "";
        // call estimate send fee
        (uint256 nativeFee,) = mevEth.estimateSendFee(ARBITRUM_ID, _addressToBytes32(User02), amount, false, "");

        vm.recordLogs();
        // send tokens from mainnet to simulated arbitrum
        mevEth.sendFrom{ value: nativeFee }(User01, ARBITRUM_ID, _addressToBytes32(User02), amount, callParams);
        vm.stopPrank();
        Vm.Log[] memory logs = vm.getRecordedLogs();
        lzHelper.help(arbitrumEndpoint, 100_000, ARBITRUM_FORK_ID, logs);

        vm.selectFork(ARBITRUM_FORK_ID);
        assertEq(arbMevEth.totalSupply(), amount);
        assertEq(arbMevEth.balanceOf(User02), amount);
    }

    function _addressToBytes32(address _address) internal pure virtual returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }
}
