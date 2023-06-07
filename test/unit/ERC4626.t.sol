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

    function testFuzzDepositWithAccrual(uint256 amount) public {
        vm.assume(amount > 1 ether);
        vm.assume(amount < type(uint168).max);
        // Base deposit
        vm.deal(User01, 10 ether);
        vm.startPrank(User01);

        // Deposit 10 ETH
        weth.deposit{value: 10 ether}();
        weth.approve(address(mev_eth), 10 ether);

        // Deposit 10 ETH into the mevETH contract
        mev_eth.deposit(10 ether, User01);

        // Accrue Interest
        vm.stopPrank();
        vm.startPrank(User02);
        vm.deal(User02, 15 ether);
        vm.coinbase(User02);
        (bool success, ) = address(mev_eth).call{value: 15 ether}("");
        assert(success);
        (uint256 elastic, uint256 base) = mev_eth.assetRebase();
        assert(elastic == 25 ether);
        assert(base == 10e18);

        // Deposit Amount
        vm.stopPrank();
        vm.startPrank(User03);

        vm.deal(User03, amount);

        // Deposit ETH
        weth.deposit{value: amount}();
        weth.approve(address(mev_eth), amount);

        // Deposit ETH into the mevETH contract
        uint256 sharesOut = mev_eth.deposit(amount, User03);


        assertEq(mev_eth.balanceOf(User03), sharesOut);
        //assert(sharesOut < amount);

        (elastic, base) = mev_eth.assetRebase();

        console.log(5);
        console.log(elastic);
        console.log(base);

        // Check the Rebase has updated correctly
        assert(elastic > base);


    }

}