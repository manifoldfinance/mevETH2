// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/ManifoldLSD.sol";
import "../src/MevETH.sol";
import "../src/OperatorRegistery.sol";

contract DepositTest is Test {
    using SafeTransferLib for ERC20;

    ManifoldLSD lsd;
    MevETH mevETH;
    OperatorRegistery op;

    function setUp() public {
        address _beaconDepositAddress = 0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b;
        address crossChainEndpoint = address(0);
        lsd = new ManifoldLSD("Manifold LSD", "mLSD", 18, _beaconDepositAddress);
        mevETH = new MevETH("Mev staked Ethereum", "mevETH", 18, address(lsd), crossChainEndpoint);
        lsd.setMevETH(address(mevETH));
        op = new OperatorRegistery(address(lsd));
    }

    function testDeposit(uint256 amount) public {
        vm.assume(amount > 1000000000000000000); // 1 eth min limit
        vm.assume(amount < address(this).balance);
        lsd.deposit{value: amount}(address(this));
        assertGt(ERC20(mevETH).balanceOf(address(this)), 0);
    }

    /// @notice Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /// @notice Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
