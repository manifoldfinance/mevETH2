pragma solidity 0.8.20;

// Test utils
import "forge-std/Test.sol";


// MevETH Contracts
import "src/MevEth.sol";

// Needed Periphery Contracts
import "./mocks/WETH9.sol";
import "./mocks/DepositContract.sol";


contract MevEthTest is Test {
    // Admin account
    address constant SamBacha = address(0x06);

    // Operator account
    address constant Operator01 = address(0x07);
    address constant Operator02 = address(0x08);
    address constant Operator03 = address(0x09);
    address constant Operator04 = address(0x10);

    DepositContract internal depositContract;

    MevEth internal mev_eth;


    function setup() public virtual {
        // Deploy the BeaconChainDepositContract 
        depositContract = new DepositContract();

        // Deploy the mevETH contract
        mev_eth = new MevEth(SamBacha, address(depositContract));
    }
}