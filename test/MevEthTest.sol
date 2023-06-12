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

    // User account
    address constant User01 = address(0x01);
    address constant User02 = address(0x02);
    address constant User03 = address(0x03);
    address constant User04 = address(0x04);

    // Operator account
    address constant Operator01 = address(0x07);
    address constant Operator02 = address(0x08);
    address constant Operator03 = address(0x09);
    address constant Operator04 = address(0x10);

    DepositContract internal depositContract;

    MevEth internal mevEth;

    WETH9 internal weth;

    //Events 
    event StakingPaused();


    function setUp() public virtual {
        // Deploy the BeaconChainDepositContract
        // Can't etch because https://github.com/foundry-rs/foundry/issues/4707
        depositContract = new DepositContract();

        // Deploy the WETH9 contract
        weth = new WETH9();

        // Deploy the mevETH contract
        // mev_eth = new MevEth(SamBacha, address(depositContract), address(weth));
        mevEth = new MevEth(SamBacha, address(depositContract), address(weth));
    }




}
