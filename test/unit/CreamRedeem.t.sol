// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../MevEthTest.sol";
import "src/interfaces/Errors.sol";

contract CreamRedeemTest is MevEthTest {
    uint256 MAINNET_FORK_ID;

    address constant mainnetDepositContract = 0x00000000219ab540356cBB839Cbe05303d7705Fa;
    address constant mainnetWeth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant L1_lzEndpoint = 0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675;

    string RPC_ETH_MAINNET = vm.envString("ETH_MAINNET_RPC_URL");

    address constant CRETH2_HOLDER = 0x36cc7B13029B5DEe4034745FB4F24034f3F2ffc6;

    function setUp() public override {
        MAINNET_FORK_ID = vm.createSelectFork(RPC_ETH_MAINNET);

        vm.selectFork(MAINNET_FORK_ID);
        // deploy mevEth (mainnet)
        mevEth = new MevEth(SamBacha, mainnetWeth, L1_lzEndpoint);
    }

    function testRedeemCream() public {
        vm.selectFork(MAINNET_FORK_ID);
        uint256 amount = 2500 ether;
        uint256 bal = ERC20(mevEth.creamToken()).balanceOf(CRETH2_HOLDER);
        vm.startPrank(CRETH2_HOLDER);
        ERC20(mevEth.creamToken()).approve(address(mevEth), amount);
        mevEth.redeemCream(amount);
        vm.stopPrank();

        assertEq(mevEth.balanceOf(CRETH2_HOLDER), amount * mevEth.CREAM_TO_MEV_ETH_PERCENT() / 1000);

        assertEq(ERC20(mevEth.creamToken()).balanceOf(CRETH2_HOLDER), bal - amount);
    }

    function testNegativeRedeemCream() public {
        vm.selectFork(MAINNET_FORK_ID);
        uint256 amount = 2500 ether;
        // revert because no cream balance or approve
        vm.expectRevert();
        mevEth.redeemCream(amount);
        vm.startPrank(CRETH2_HOLDER);

        // revert because no approve
        vm.expectRevert();
        mevEth.redeemCream(amount);

        // revert because amount too small
        amount = mevEth.MIN_DEPOSIT() / 2;
        ERC20(mevEth.creamToken()).approve(address(mevEth), amount);
        vm.expectRevert();
        mevEth.redeemCream(amount);
        vm.stopPrank();

        vm.prank(SamBacha);
        mevEth.pauseStaking();

        vm.startPrank(CRETH2_HOLDER);
        // revert because staking paused
        ERC20(mevEth.creamToken()).approve(address(mevEth), amount);
        vm.expectRevert(MevEthErrors.StakingPaused.selector);
        mevEth.redeemCream(amount);
        vm.stopPrank();
    }
}
