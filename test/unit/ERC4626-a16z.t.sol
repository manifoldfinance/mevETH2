pragma solidity 0.8.19;

import "forge-std/console.sol";
import "../MevEthTest.sol";
import "src/interfaces/Errors.sol";
import { ERC4626Test as a16z } from "../a16z/erc4626-tests/ERC4626.test.sol";

contract ERC4626StdTest is a16z, MevEthTest {
    function setUp() public override(a16z, MevEthTest) {
        super.setUp();
        _underlying_ = address(weth);
        _vault_ = address(mevEth);
        _delta_ = 10_000;
        _vaultMayBeEmpty = true;
        _unlimitedAmount = false;
        vm.deal(address(weth), 100_000_000_000_000 ether);
    }
}
