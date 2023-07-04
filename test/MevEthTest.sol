pragma solidity 0.8.19;

// Test utils
import "forge-std/Test.sol";

// MevETH Contracts
import "src/MevEth.sol";

// Needed Periphery Contracts
import "./mocks/WETH9.sol";
import "./mocks/DepositContract.sol";
import "../src/MevEthShareVault.sol";

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

    uint256 constant FEE_REWARDS_PER_BLOCK = 0;

    DepositContract internal depositContract;

    MevEth internal mevEth;

    WETH9 internal weth;

    //Events
    event StakingPaused();
    event StakingUnpaused();
    event StakingModuleUpdateCommitted(address indexed oldModule, address indexed pendingModule, uint64 indexed eligibleForFinalization);
    event StakingModuleUpdateFinalized(address indexed oldModule, address indexed newModule);
    event StakingModuleUpdateCanceled(address indexed oldModule, address indexed pendingModule);
    event MevEthShareVaultUpdateCommitted(address indexed oldVault, address indexed pendingVault, uint64 indexed eligibleForFinalization);
    event MevEthShareVaultUpdateFinalized(address indexed oldVault, address indexed newVault);
    event MevEthShareVaultUpdateCanceled(address indexed oldVault, address indexed newVault);
    event NewValidator(address indexed operator, bytes pubkey, bytes32 withdrawalCredentials, bytes signature, bytes32 deposit_data_root);
    event MevEthInitialized(address indexed mevEthShareVault, address indexed stakingModule);
    event TokenRecovered(address indexed recipient, address indexed token, uint256 indexed amount);

    function setUp() public virtual {
        // Deploy the BeaconChainDepositContract
        // Can't etch because https://github.com/foundry-rs/foundry/issues/4707
        depositContract = new DepositContract();

        // Deploy the WETH9 contract
        weth = new WETH9();

        // Deploy the mevETH contract
        mevEth = new MevEth(SamBacha, address(weth));

        // Initialize the mevETH contract
        address initialShareVault = address(new MevEthShareVault(SamBacha, address(mevEth), FEE_REWARDS_PER_BLOCK));
        address initialStakingModule = address(IStakingModule(address(new WagyuStaker(SamBacha, address(depositContract), address(mevEth)))));
        vm.prank(SamBacha);
        mevEth.init(initialShareVault, initialStakingModule);

        // Add a new operator
        vm.prank(SamBacha);
        mevEth.addOperator(Operator01);
    }
}
