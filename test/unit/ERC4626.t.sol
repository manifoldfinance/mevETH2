pragma solidity 0.8.20;

import "forge-std/console.sol";
import "../MevEthTest.sol";
import "src/libraries/Errors.sol";

contract ERC4626Test is MevEthTest {
    struct AssetsRebase {
        uint256 elastic; // Represents total amount of staked ether, including rewards accrued / slashed
        uint256 base; // Represents claims to ownership of the staked ether
    }

    function setUp() override  public {
        super.setUp();
    }

    function testSimpleDeposit() public {  
        vm.deal(User01, 1 ether);
        vm.startPrank(User01);

        // Deposit 1 ETH
        weth.deposit{value: 1 ether}();
        // Approve the mevETH contract to spend 1 ETH
        weth.approve(address(mev_eth), 1 ether);

        // Deposit 1 ETH into the mevETH contract
        mev_eth.deposit(1 ether, User01);

        // Check that the mevETH contract has 1 ETH
        assertEq(address(mev_eth).balance, 1 ether);

        // Check the user has 1 mevETH
        assertEq(mev_eth.balanceOf(User01), 1 ether);

        // Check the user has 0 ETH
        assertEq(address(User01).balance, 0 ether);

        // Check the Rebase has updated correctly
        (uint256 elastic, uint256 base) = mev_eth.assetRebase();
        assertEq(elastic , 1 ether);
        assertEq(base , 1 ether);
    }

    function testFuzzSimpleDeposit(uint256 amount) public {
        vm.assume(amount > 10000);
        vm.deal(User01, amount);
        vm.startPrank(User01);

        // Deposit 1 ETH
        weth.deposit{value: amount}();
        // Approve the mevETH contract to spend 1 ETH
        weth.approve(address(mev_eth), amount);

        // Deposit 1 ETH into the mevETH contract
        mev_eth.deposit(amount, User01);

        // Check that the mevETH contract has 1 ETH
        assertEq(address(mev_eth).balance, amount);

        // Check the user has 1 mevETH
        assertEq(mev_eth.balanceOf(User01), amount);

        // Check the user has 0 ETH
        assertEq(address(User01).balance, 0 ether);

        // Check the Rebase has updated correctly
        (uint256 elastic, uint256 base) = mev_eth.assetRebase();
        assertEq(elastic , amount);
        assertEq(base , amount);
    }

    function testDepositFailsBelowMinimum(uint64 amount) public {
        vm.assume(amount < 1000);
        vm.deal(User01, amount);
        vm.startPrank(User01);

        // Deposit 1 ETH
        weth.deposit{value: amount}();
        weth.approve(address(mev_eth), amount);

        // Deposit 1 ETH into the mevETH contract
        vm.expectRevert(MevEthErrors.DepositTooSmall.selector);
        mev_eth.deposit(amount, User01);

        // Check that the mevETH contract has 1 ETH
        assertEq(address(mev_eth).balance, 0);

        // Check the user has 1 mevETH
        assertEq(mev_eth.balanceOf(User01), 0);

        // Check the user has 0 ETH
        assertEq(address(User01).balance, 0);

        // Check the Rebase has updated correctly
        (uint256 elastic, uint256 base) = mev_eth.assetRebase();
        assertEq(elastic , 0);
        assertEq(base , 0);
    }

    // Helper function to deposit into mevETH
    function _depositOnBehalfOf(uint256 amount, address user) internal {
        vm.stopPrank();
        vm.startPrank(user);

        // Deposit amount in eth
        weth.deposit{value: amount}();
        weth.approve(address(mev_eth), amount);

        // Deposit amount in mevETH
        mev_eth.deposit(amount, user);
    }


}