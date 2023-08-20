pragma solidity 0.8.20;

import "forge-std/console.sol";
import "../MevEthTest.sol";
import "src/interfaces/Errors.sol";

contract ERC4626Test is MevEthTest {
    struct AssetsFraction {
        uint256 elastic; // Represents total amount of staked ether, including rewards accrued / slashed
        uint256 base; // Represents claims to ownership of the staked ether
    }

    function setUp() public override {
        super.setUp();
    }

    function testAsset() public {
        assertEq(mevEth.asset(), address(weth));
    }

    function testMaxDeposit(address randomGuy) public {
        assertEq(mevEth.maxDeposit(randomGuy), 2 ** 128 - 1);
    }

    function testFuzzMaxMint(address randomGuy) public {
        assertEq(mevEth.maxMint(randomGuy), 2 ** 128 - 1);
    }

    function testPreviewDeposit(uint256 amount) public {
        assertEq(mevEth.previewDeposit(amount), amount);
    }

    function testPreviewMint(uint256 amount) public {
        assertEq(mevEth.previewMint(amount), amount);
    }

    function testPreviewWithdraw(uint128 amount) public {
        vm.assume(amount > mevEth.MIN_DEPOSIT());
        vm.assume(amount < type(uint128).max - type(uint128).max / 10_000);
        vm.deal(User01, amount);
        vm.startPrank(User01);
        mevEth.deposit{ value: amount }(amount, User01);
        assertEq(mevEth.previewWithdraw(amount), uint256(amount) * 10_001 / 10_000);
    }

    function testPreviewRedeem(uint128 amount) public {
        vm.assume(amount > mevEth.MIN_DEPOSIT());
        vm.deal(User01, amount);
        vm.startPrank(User01);
        mevEth.deposit{ value: amount }(amount, User01);
        assertGe(mevEth.previewRedeem(amount), uint256(amount) * 9999 / 10_000);
    }

    function testMaxWithdraw(uint128 amount) public {
        vm.assume(amount > mevEth.MIN_DEPOSIT());
        vm.deal(User01, amount);
        vm.startPrank(User01);
        mevEth.deposit{ value: amount }(amount, User01);
        assertEq(mevEth.maxWithdraw(User01), amount);
    }

    function testMaxRedeem(uint128 amount) public {
        vm.assume(amount > mevEth.MIN_DEPOSIT());
        vm.deal(User01, amount);
        vm.startPrank(User01);
        mevEth.deposit{ value: amount }(amount, User01);
        assertEq(mevEth.maxRedeem(User01), amount);
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
        weth.deposit{ value: 1 ether }();
        // Approve the mevETH contract to spend 1 ETH
        weth.approve(address(mevEth), 1 ether);

        // Deposit 1 ETH into the mevETH contract
        mevEth.deposit(1 ether, User01);

        // Check that the mevETH contract has 1 ETH
        assertEq(address(mevEth).balance, 1 ether);

        // Check the user has 1 mevETH
        assertEq(mevEth.balanceOf(User01), 1 ether);

        // Check the user has 0 ETH
        assertEq(address(User01).balance, 0 ether);

        // Check the fraction has updated correctly
        (uint256 elastic, uint256 base) = mevEth.fraction();
        assertEq(elastic, 1 ether);
        assertEq(base, 1 ether);
    }

    function testExcessDeposit() public {
        vm.deal(User01, 1.1 ether);
        vm.startPrank(User01);

        vm.expectRevert(MevEthErrors.WrongDepositAmount.selector);
        // Deposit 1 ETH into the mevETH contract with an excess payment
        mevEth.deposit{ value: 1.1 ether }(1 ether, User01);
    }

    function testFuzzSimpleDeposit(uint256 amount) public {
        vm.assume(amount > mevEth.MIN_DEPOSIT());
        vm.assume(amount < 2 ** 128 - 1);
        vm.deal(User01, amount);
        vm.startPrank(User01);

        // Deposit 1 ETH
        weth.deposit{ value: amount }();
        // Approve the mevETH contract to spend 1 ETH
        weth.approve(address(mevEth), amount);

        // Deposit 1 ETH into the mevETH contract
        mevEth.deposit(amount, User01);

        // Check that the mevETH contract has 1 ETH
        assertEq(address(mevEth).balance, amount);

        // Check the user has 1 mevETH
        assertEq(mevEth.balanceOf(User01), amount);

        // Check the user has 0 ETH
        assertEq(address(User01).balance, 0 ether);

        // Check the fraction has updated correctly
        (uint256 elastic, uint256 base) = mevEth.fraction();
        assertEq(elastic, amount);
        assertEq(base, amount);
    }

    function testDepositFailsBelowMinimum(uint64 amount) public {
        vm.assume(amount < 1000 && amount > 0);
        vm.deal(User01, amount);
        vm.startPrank(User01);

        // Deposit 1 ETH
        weth.deposit{ value: amount }();
        weth.approve(address(mevEth), amount);

        // Deposit 1 ETH into the mevETH contract
        vm.expectRevert(MevEthErrors.DepositTooSmall.selector);
        mevEth.deposit(amount, User01);

        // Check that the mevETH contract has 1 ETH
        assertEq(address(mevEth).balance, 0);

        // Check the user has 1 mevETH
        assertEq(mevEth.balanceOf(User01), 0);

        // Check the user has 0 ETH
        assertEq(address(User01).balance, 0);

        // Check the fraction has updated correctly
        (uint256 elastic, uint256 base) = mevEth.fraction();
        assertEq(elastic, 0);
        assertEq(base, 0);
    }

    // Helper function to deposit into mevETH
    function _depositOnBehalfOf(uint256 amount, address user) internal {
        vm.assume(amount < 2 ** 128 - 1);
        vm.stopPrank();
        vm.startPrank(user);

        // Deposit amount in mevETH
        mevEth.deposit{ value: amount }(amount, user);
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

        assertEq(address(mevEth).balance, 1 ether);
        // Withdraw 1 mevETH
        uint256 shares = mevEth.withdraw(0.75 ether, User01, User01);
        assertEq(mevEth.balanceOf(User01), 1 ether - shares);
        assertEq(weth.balanceOf(User01), 0.75 ether);
    }

    function testCannotWithdrawWithoutApproval() public {
        vm.deal(User01, 1 ether);
        vm.startPrank(User01);

        _depositOnBehalfOf(1 ether, User01);

        assertEq(mevEth.balanceOf(User01), 1 ether);

        vm.stopPrank();
        vm.startPrank(User02);

        // Withdraw 1 mevETH
        vm.expectRevert(MevEthErrors.TransferExceedsAllowance.selector);
        mevEth.withdraw(1 ether, User02, User01);

        assertEq(mevEth.balanceOf(User01), 1 ether);
        assertEq(mevEth.balanceOf(User02), 0 ether);
    }

    function testCanWithdrawWithApproval() public {
        vm.deal(User01, 1 ether);
        vm.startPrank(User01);

        _depositOnBehalfOf(1 ether, User01);

        assertEq(mevEth.balanceOf(User01), 1 ether);

        // Approve User02 to spend 1 mevETH
        mevEth.approve(User02, 1 ether);
        vm.stopPrank();
        vm.startPrank(User02);

        // Withdraw 1 mevETH
        uint256 shares = mevEth.withdraw(0.75 ether, User02, User01);

        assertEq(mevEth.balanceOf(User01), 1 ether - shares);
        assertEq(weth.balanceOf(User02), 0.75 ether);

        assertEq(mevEth.allowance(User01, User02), 1 ether - shares);
    }

    function fuzzSimpleWithdrawal(uint256 amount) public {
        vm.assume(amount > mevEth.MIN_DEPOSIT());
        vm.assume(amount < 2 ** 128 - 1);
        vm.deal(User02, 10_001);
        vm.startPrank(User02);
        _depositOnBehalfOf(10_001, User02);

        vm.stopPrank();
        vm.deal(User01, amount);
        vm.startPrank(User01);
        _depositOnBehalfOf(amount, User01);

        assertEq(address(mevEth).balance, amount);

        // Withdraw 1 mevETH
        mevEth.withdraw(amount, User01, User01);

        assertEq(mevEth.balanceOf(User01), 0 ether);
        assertEq(weth.balanceOf(User01), amount);
    }

    /* 
        -------/  Tests for Mint   /-------
        1. Test a simple mint, of a fixed amount, for one user
        2. Test a simple mint, of a random amount, for one user
        3. Test a small mint below the minimum, and ensure it reverts
    */

    function testSimpleMint() public {
        vm.deal(User01, 1 ether);
        vm.startPrank(User01);

        uint256 sharesOut = mevEth.convertToShares(1 ether);

        weth.deposit{ value: 1 ether }();
        weth.approve(address(mevEth), 1 ether);

        // Mint 1 mevETH
        uint256 actualSharesOut = mevEth.mint(sharesOut, User01);
        assertEq(mevEth.balanceOf(User01), sharesOut);
        assertEq(actualSharesOut, sharesOut);

        assertEq(address(mevEth).balance, 1 ether);
        assertEq(mevEth.totalSupply(), actualSharesOut);
        assertEq(weth.balanceOf(address(User01)), 0 ether);
    }

    function testFuzzMint(uint256 amount) public {
        vm.assume(amount > mevEth.MIN_DEPOSIT());
        vm.assume(amount < 2 ** 128 - 1);
        vm.deal(User01, amount);
        vm.startPrank(User01);

        uint256 sharesOut = mevEth.convertToShares(amount);

        weth.deposit{ value: amount }();
        weth.approve(address(mevEth), amount);

        // Mint 1 mevETH
        uint256 actualSharesOut = mevEth.mint(sharesOut, User01);
        assertEq(mevEth.balanceOf(User01), sharesOut);
        assertEq(actualSharesOut, sharesOut);

        assertEq(address(mevEth).balance, amount);
        assertEq(mevEth.totalSupply(), actualSharesOut);
        assertEq(weth.balanceOf(address(User01)), 0 ether);
    }

    function testNegativeMintBelowMinimum(uint64 amount) public {
        vm.assume(amount < 1000);
        vm.deal(User01, amount);
        vm.startPrank(User01);

        // Deposit 1 ETH
        weth.deposit{ value: amount }();
        weth.approve(address(mevEth), amount);

        uint256 shares = mevEth.convertToShares(amount);

        // Deposit 1 ETH into the mevETH contract
        vm.expectRevert(MevEthErrors.DepositTooSmall.selector);
        mevEth.mint(shares, User01);

        // Check that the mevETH contract has 1 ETH
        assertEq(address(mevEth).balance, 0);

        // Check the user has 1 mevETH
        assertEq(mevEth.balanceOf(User01), 0);

        // Check the user has 0 ETH
        assertEq(address(User01).balance, 0);

        // Check the fraction has updated correctly
        (uint256 elastic, uint256 base) = mevEth.fraction();
        assertEq(elastic, 0);
        assertEq(base, 0);
    }

    /* 
        -------/  Tests for Redemption   /-------
        1. Test a basic redemption, of 1 eth, for one user
        2. Attempt to redemption without approval, and ensure it reverts
        3. Test that a user can redemption, if they have been approved by the owner
        4. Test a basic redemption with a random amount of eth
    */

    function testBasicRedemption() public {
        vm.deal(User01, 1 ether);
        vm.startPrank(User01);

        _depositOnBehalfOf(1 ether, User01);

        assertEq(address(mevEth).balance, 1 ether);

        // Redeem 1 mevETH
        uint256 assets = mevEth.redeem(0.75 ether, User01, User01);

        assertEq(mevEth.balanceOf(User01), 0.25 ether);
        assertEq(weth.balanceOf(User01), assets);
    }

    function testNegativeRedeemStealWithoutApproval() public {
        vm.deal(User01, 10 ether);
        vm.startPrank(User01);

        _depositOnBehalfOf(10 ether, User01);

        assertEq(mevEth.balanceOf(User01), 10 ether);

        vm.stopPrank();
        vm.startPrank(User02);

        uint256 userBalance = mevEth.balanceOf(User01);

        // Withdraw 1 mevETH
        vm.expectRevert(MevEthErrors.TransferExceedsAllowance.selector);
        mevEth.redeem(userBalance, User02, User01);

        assertEq(mevEth.balanceOf(User01), 10 ether);
        assertEq(mevEth.balanceOf(User02), 0 ether);
    }

    function testCanRedeemWithApproval() public {
        vm.deal(User01, 1 ether);
        vm.startPrank(User01);

        _depositOnBehalfOf(1 ether, User01);

        assertEq(mevEth.balanceOf(User01), 1 ether);

        // Approve User02 to spend 1 mevETH
        mevEth.approve(User02, 1 ether);
        vm.stopPrank();
        vm.startPrank(User02);

        // Withdraw 0.75 mevETH
        uint256 assets = mevEth.redeem(0.75 ether, User02, User01);

        assertEq(mevEth.balanceOf(User01), 0.25 ether);
        assertEq(weth.balanceOf(User02), assets);

        assertEq(mevEth.allowance(User01, User02), 0.25 ether);
    }

    function testFuzzRedeem(uint128 amount) public {
        vm.assume(amount > mevEth.MIN_DEPOSIT() * 4);
        vm.deal(User01, amount);
        vm.startPrank(User01);

        _depositOnBehalfOf(amount, User01);

        assertEq(address(mevEth).balance, amount);

        uint256 amountToRedeem = (amount / 100) * 75;
        uint256 amountLeftOver = amount - amountToRedeem;

        // Redeem 1 mevETH
        uint256 assets = mevEth.redeem(amountToRedeem, User01, User01);

        assertEq(mevEth.balanceOf(User01), amountLeftOver);
        assertEq(weth.balanceOf(User01), assets);
    }
}
