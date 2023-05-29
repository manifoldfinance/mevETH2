pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../../src/ManifoldLSD.sol";
import "../../src/MevETH.sol";

contract MockDepositContract {
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable {}
}

contract StakingTest is Test {
    bytes32 internal nextUser = keccak256(abi.encodePacked("user address"));

    ManifoldLSD internal lsd;
    MevETH internal mevEth;
    MockDepositContract internal deposit;

    function getNextUserAddress() external returns (address payable) {
        address payable user = payable(address(uint160(uint256(nextUser))));
        nextUser = keccak256(abi.encodePacked(nextUser));
        return user;
    }

    address payable internal owner;
    address payable internal staker;

    function setUp() public {
        owner = this.getNextUserAddress();
        vm.deal(owner, 1 ether);

        staker = this.getNextUserAddress();
        vm.deal(staker, 1.1 ether);

        vm.prank(owner);
        deposit = new MockDepositContract();
        lsd = new ManifoldLSD("Manifold LSD", "MFLSD", 18, address(deposit));
        mevEth = new MevETH(
            "Mev Eth",
            "MevETH",
            18,
            address(lsd),
            address(0x0)
        );
        lsd.setMevETH(address(mevEth));
    }

    function test_Staking() public {
        vm.prank(staker);
        lsd.deposit{value: 1.1 ether}(address(staker));
    }
}
