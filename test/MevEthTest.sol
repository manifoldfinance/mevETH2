pragma solidity 0.8.19;

// Test utils
import "forge-std/Test.sol";

// MevETH Contracts
import "src/MevEth.sol";

// Needed Periphery Contracts
import "./mocks/WETH9.sol";
import "./mocks/DepositContract.sol";
import "./mocks/LZEndpointMock.sol";
import "../src/MevEthShareVault.sol";
import { SafeInstance, SafeTestTools } from "../lib/safe-tools/src/SafeTestTools.sol";

contract MevEthTest is Test {
    // LayerZero Ids
    uint16 constant ETH_ID = 101;
    uint16 constant GOERLI_ID = 10_121;
    uint16 constant POLYGON_ID = 109;
    uint16 constant ARBITRUM_ID = 110;

    // Admin account

    uint256 constant SAM_BACHA_PRIVATE_KEY = 0x01;
    address immutable SamBacha = vm.addr(SAM_BACHA_PRIVATE_KEY);

    uint256 constant SAFE_OWNER_1_PRIVATE_KEY = 0x02;
    address immutable SafeOwner1 = vm.addr(SAFE_OWNER_1_PRIVATE_KEY);

    uint256 constant SAFE_OWNER_2_PRIVATE_KEY = 0x03;
    address immutable SafeOwner2 = vm.addr(SAFE_OWNER_2_PRIVATE_KEY);

    uint256 constant SAFE_OWNER_3_PRIVATE_KEY = 0x04;
    address immutable SafeOwner3 = vm.addr(SAFE_OWNER_3_PRIVATE_KEY);

    uint256 constant SAFE_OWNER_4_PRIVATE_KEY = 0x05;
    address immutable SafeOwner4 = vm.addr(SAFE_OWNER_4_PRIVATE_KEY);

    uint256 constant SAFE_OWNER_5_PRIVATE_KEY = 0x06;
    address immutable SafeOwner5 = vm.addr(SAFE_OWNER_5_PRIVATE_KEY);

    uint256 constant SAFE_OWNER_6_PRIVATE_KEY = 0x07;
    address immutable SafeOwner6 = vm.addr(SAFE_OWNER_6_PRIVATE_KEY);

    SafeInstance internal multisigSafeInstance;

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
    uint128 constant BASE_MEDIAN_MEV_PAYMENT = 0.1 ether;
    uint128 constant BASE_MEDIAN_VALIDATOR_PAYMENT = 0.1 ether;
    uint16 constant SHARE_VAULT_FEE_PERCENT = 10_000; // In bips

    DepositContract internal depositContract;

    MevEth internal mevEth;

    WETH9 internal weth;

    LZEndpointMock internal layerZeroEndpoint;

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
    event Rewards(address sender, uint256 amount);
    event AdminAdded(address indexed newAdmin);
    event AdminDeleted(address indexed oldAdmin);
    event OperatorAdded(address indexed newOperator);
    event OperatorDeleted(address indexed oldOperator);

    // MevEthShareVault Events
    event RewardPayment(uint256 indexed blockNumber, address indexed coinbase, uint256 indexed amount);
    event ProtocolFeeToUpdated(address indexed newProtocolFeeTo);
    event BeneficiaryUpdated(address indexed beneficiary);
    event RewardsCollected(uint256 indexed protocolFeesOwed, uint256 indexed rewardsOwed);
    event FeesSent(uint256 indexed feesSent);
    event RewardsPaid(uint256 indexed rewards);

    function setUp() public virtual {
        // Deploy the BeaconChainDepositContract
        // Can't etch because https://github.com/foundry-rs/foundry/issues/4707
        depositContract = new DepositContract();

        // Deploy the WETH9 contract
        weth = new WETH9();

        layerZeroEndpoint = new LZEndpointMock(ETH_ID);

        // Deploy the mevETH contract
        mevEth = new MevEth(SamBacha, address(weth), address(layerZeroEndpoint));

        // Initialize initial share vault as a multisig

        // Create an array with a length of 7
        uint256[] memory ownerPKs = new uint256[](7);

        ownerPKs[0] = SAM_BACHA_PRIVATE_KEY;
        ownerPKs[1] = SAFE_OWNER_1_PRIVATE_KEY;
        ownerPKs[2] = SAFE_OWNER_2_PRIVATE_KEY;
        ownerPKs[3] = SAFE_OWNER_3_PRIVATE_KEY;
        ownerPKs[4] = SAFE_OWNER_4_PRIVATE_KEY;
        ownerPKs[5] = SAFE_OWNER_5_PRIVATE_KEY;
        ownerPKs[6] = SAFE_OWNER_6_PRIVATE_KEY;

        SafeTestTools safeTestTools = new SafeTestTools();
        SafeInstance memory safeInstance = safeTestTools._setupSafe(ownerPKs, 5);
        multisigSafeInstance = safeInstance;

        address initialShareVault = address(safeInstance.safe);

        address initialStakingModule = address(IStakingModule(address(new WagyuStaker(SamBacha, address(depositContract), address(mevEth)))));
        vm.prank(SamBacha);
        mevEth.init(initialShareVault, initialStakingModule);

        // Add a new operator
        vm.prank(SamBacha);
        mevEth.addOperator(Operator01);
    }

    // Helper function to update the staking module for testing
    function _updateStakingModule(IStakingModule newStakingModule) internal {
        // Commit update to the staking module
        uint64 finalizationTimestamp = uint64(block.timestamp + mevEth.MODULE_UPDATE_TIME_DELAY());

        vm.prank(SamBacha);
        mevEth.commitUpdateStakingModule(newStakingModule);

        // Warp to the finalization timestamp, finalize the update
        vm.warp(finalizationTimestamp);
        vm.prank(SamBacha);
        mevEth.finalizeUpdateStakingModule();

        assertEq(address(mevEth.pendingStakingModule()), address(0));
        assertEq(mevEth.pendingStakingModuleCommittedTimestamp(), 0);
        assertEq(address(mevEth.stakingModule()), address(newStakingModule));
    }

    // Helper function to update the share vault for testing
    function _updateShareVault(address newShareVault) internal {
        // Commit update to the staking module
        uint64 finalizationTimestamp = uint64(block.timestamp + mevEth.MODULE_UPDATE_TIME_DELAY());

        vm.prank(SamBacha);
        mevEth.commitUpdateMevEthShareVault(newShareVault);

        // Warp to the finalization timestamp, finalize the update
        vm.warp(finalizationTimestamp);
        vm.prank(SamBacha);
        mevEth.finalizeUpdateMevEthShareVault();

        assertEq(address(mevEth.pendingMevEthShareVault()), address(0));
        assertEq(mevEth.pendingMevEthShareVaultCommittedTimestamp(), 0);
        assertEq(address(mevEth.mevEthShareVault()), address(newShareVault));
    }
}
