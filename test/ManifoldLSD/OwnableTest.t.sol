// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../../src/ManifoldLSD.sol";

contract OwnableTest is Test {
    using SafeTransferLib for ERC20;

    ManifoldLSD lsd;
    address owner;

    function setUp() public {
        address _beaconDepositAddress = 0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b;
        owner = address(this);
        lsd = new ManifoldLSD("Manifold LSD", "mLSD", 18, _beaconDepositAddress);
    }

    function test_TransferOwnership(address newOwner) public {
        vm.assume(newOwner != owner);
        vm.expectRevert();
        vm.prank(owner);
        lsd.transferOwnership(newOwner);
    }

    function test_RenounceOwnership() public {
        vm.expectRevert();
        vm.prank(owner);
        lsd.renounceOwnership();
    }

    function test_RequestOwnershipHandover(address pendingOwner) public {
        vm.assume(pendingOwner != owner);
        vm.prank(pendingOwner);
        lsd.requestOwnershipHandover();
    }

    function test_CompleteOwnershipHandover(address pendingOwner) public {
        vm.assume(pendingOwner != owner);
        vm.prank(pendingOwner);
        lsd.requestOwnershipHandover();
        vm.prank(owner);
        lsd.completeOwnershipHandover(pendingOwner);
        assert(lsd.owner() == pendingOwner);
    }

    function test_CancelOwnershipHandover(address pendingOwner) public {
        vm.assume(pendingOwner != owner);
        vm.prank(pendingOwner);
        lsd.requestOwnershipHandover();
        assert(lsd.ownershipHandoverExpiresAt(pendingOwner) > 0);
        vm.prank(pendingOwner);
        lsd.cancelOwnershipHandover();
        assert(lsd.ownershipHandoverExpiresAt(pendingOwner) == 0);
        assert(lsd.owner() == owner);
    }
}
