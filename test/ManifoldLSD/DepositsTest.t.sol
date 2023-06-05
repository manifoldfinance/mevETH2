// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../../src/ManifoldLSD.sol";
import "../../src/MevETH.sol";
import "../../src/OperatorRegistry.sol";

contract DepositTest is Test {
    using SafeTransferLib for ERC20;

    address private constant BEACON_DEPOSIT_ADDRESS = 0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b;
    address private constant LAYER_ZERO_CROSS_CHAIN_ENDPOINT = address(0);

    ManifoldLSD lsd;
    MevETH mevETH;
    OperatorRegistry op;

    function setUp() public {
        lsd = new ManifoldLSD("Manifold LSD", "mLSD", 18, BEACON_DEPOSIT_ADDRESS);
        mevETH = new MevETH("Mev Ethereum", "mevETH", 18, address(lsd), LAYER_ZERO_CROSS_CHAIN_ENDPOINT);
        lsd.setMevETH(address(mevETH));
        op = new OperatorRegistry(address(lsd));
    }

    function testFuzz_SuccessfulDeposit(uint256 amount) public {
        vm.assume(amount > 1 ether); // At least more than 1 eth
        vm.assume(amount < address(this).balance); // Less than the total of this address balance

        lsd.deposit{value: amount}(address(this));

        // Check balance of sender is higher than 0
        assertGt(ERC20(mevETH).balanceOf(address(this)), 0);

        // Assert lsd contains correct amount of buffered eth
        assertEq(lsd.totalBeaconBalance(), 0);
        assertEq(lsd.transientEth(), 0);
        assertGt(lsd.totalAssets(), 0);
        assertGt(lsd.totalBufferedEther(), 0);

        // TODO: Review behavior with totalSupply
        // assertGt(lsd.totalSupply(), 0);
    }

    function testFuzz_RevertWhen_DepositBelowMin(uint256 amount) public {
        vm.assume(amount < 1 ether); // Less than 1 eth
        vm.assume(amount >= 0); // 0 or higher

        vm.expectRevert(ManifoldLSD.DepositTooLow.selector);

        lsd.deposit{value: amount}(address(this));
    }
}
