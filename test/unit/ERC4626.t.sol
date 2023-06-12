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

    function testAsset() public {
        assertEq(mev_eth.asset(), address(weth));
    }

    function testMaxDeposit(address randomGuy) public {
        assertEq(mev_eth.maxDeposit(randomGuy), 2**256 -1);
    }

    function testFuzzMaxMint(address randomGuy) public {
        assertEq(mev_eth.maxMint(randomGuy), 2**256 -1);
    }

    /* 
        -------/  Tests for Deposit   /-------
        1. Test a simple deposit, of a fixed amount, for one user
        2. Test a simple deposit, of a random amount, for one user
        3. Test a small deposit below the minimum, and ensure it reverts
    */

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

    /* 
        -------/  Tests for Withdrawal   /-------
        1. Test a basic withdrawal, of 1 eth, for one user
        2. Attempt to withdraw without approval, and ensure it reverts
        3. Test that a user can withdraw, if they have been approved by the owner
        4. Test a basic withdrawal with a random amount of eth
    */

    function testBasicWithdrawal() public {
        vm.deal(User01, 1 ether);
        vm.startPrank(User01);
        _depositOnBehalfOf(1 ether, User01);

        assertEq(address(mev_eth).balance, 1 ether);

        // Withdraw 1 mevETH
        mev_eth.withdraw(1 ether, User01, User01);
        assertEq(mev_eth.balanceOf(User01), 0 ether);
        assertEq(weth.balanceOf(User01), 1 ether);
    }

    function testCannotWithdrawWithoutApproval() public {
        vm.deal(User01, 1 ether);
        vm.startPrank(User01);

        _depositOnBehalfOf(1 ether, User01);

        assertEq(mev_eth.balanceOf(User01), 1 ether);

        vm.stopPrank();
        vm.startPrank(User02);

        // Withdraw 1 mevETH
        vm.expectRevert(MevEthErrors.TransferExceedsAllowance.selector);
        mev_eth.withdraw(1 ether, User02, User01);

        assertEq(mev_eth.balanceOf(User01), 1 ether);
        assertEq(mev_eth.balanceOf(User02), 0 ether);
    } 

    function testCanWithdrawWithApproval() public {
        vm.deal(User01, 1 ether);
        vm.startPrank(User01);

        _depositOnBehalfOf(1 ether, User01);

        assertEq(mev_eth.balanceOf(User01), 1 ether);

        // Approve User02 to spend 1 mevETH
        mev_eth.approve(User02, 1 ether);
        vm.stopPrank();
        vm.startPrank(User02);

        // Withdraw 1 mevETH
        mev_eth.withdraw(1 ether, User02, User01);

        assertEq(mev_eth.balanceOf(User01), 0 ether);
        assertEq(weth.balanceOf(User02), 1 ether);

        assertEq(mev_eth.allowance(User01, User02), 0 ether);
    }

    function fuzzSimpleWithdrawal(uint256 amount) public {
        vm.assume(amount > 10000);
        vm.deal(User02, 10001);
        vm.startPrank(User02);
        _depositOnBehalfOf(10001, User02);

        vm.stopPrank();
        vm.deal(User01, amount);
        vm.startPrank(User01);
        _depositOnBehalfOf(amount, User01);

        assertEq(address(mev_eth).balance, amount);

        // Withdraw 1 mevETH
        mev_eth.withdraw(amount, User01, User01);
        assertEq(mev_eth.balanceOf(User01), 0 ether);
        assertEq(weth.balanceOf(User01), amount);
    }
}