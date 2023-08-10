// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/*///////////// Manifold Mev Ether /////////////                   
                ,,,         ,,,
            ;"   ^;     ;'   ",
            ;    s$$$$$$$s     ;
            ,  ss$$$$$$$$$$s  ,'
            ;s$$$$$$$$$$$$$$$
            $$$$$$$$$$$$$$$$$$
            $$$$P""Y$$$Y""W$$$$$
            $$$$  p"$$$"q  $$$$$
            $$$$  .$$$$$.  $$$$
            $$DcaU$$$$$$$$$$
                "Y$$$"*"$$$Y"    
                "$b.$$"     
/////////////////////////////////////////////*/

import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "solmate/utils/FixedPointMathLib.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { IERC4626 } from "./interfaces/IERC4626.sol";
import { IWETH } from "./interfaces/IWETH.sol";
import { MevEthErrors } from "./interfaces/Errors.sol";
import { IStakingModule } from "./interfaces/IStakingModule.sol";
import { MevEthShareVault } from "./MevEthShareVault.sol";
import { ITinyMevEth } from "./interfaces/ITinyMevEth.sol";
import { WagyuStaker } from "./WagyuStaker.sol";
import { OFTWithFee } from "./layerZero/oft/OFTWithFee.sol";

/// @title MevEth
/// @author Manifold Finance
/// @dev Contract that allows deposit of ETH, for a Liquid Staking Receipt (LSR) in return.
/// @dev LSR is represented through an ERC4626 token and interface.
contract MevEth is OFTWithFee, IERC4626, ITinyMevEth {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                            Configuration Variables
    //////////////////////////////////////////////////////////////*/

    /// @notice Inidicates if staking is paused.
    bool public stakingPaused;
    /// @notice Indicates if contract is initialized.
    bool public initialized;
    /// @notice Timestamp when pending staking module update can be finalized.
    uint64 public pendingStakingModuleCommittedTimestamp;
    /// @notice Timestamp when pending mevEthShareVault update can be finalized.
    uint64 public pendingMevEthShareVaultCommittedTimestamp;
    /// @notice Time delay before staking module or share vault can be finalized.
    uint64 internal constant MODULE_UPDATE_TIME_DELAY = 7 days;
    /// @notice Max amount of ETH that can be deposited.
    uint128 internal constant MAX_DEPOSIT = type(uint128).max;
    /// @notice Min amount of ETH that can be deposited.
    uint128 public constant MIN_DEPOSIT = 0.01 ether; // 0.01 eth
    /// @notice The address of the MevEthShareVault.
    address public mevEthShareVault;
    /// @notice The address of the pending MevEthShareVault when a new vault has been comitted but not finalized.
    address public pendingMevEthShareVault;
    /// @notice The staking module used to stake Ether.
    IStakingModule public stakingModule;
    /// @notice The pending staking module when a new module has been comitted but not finalized.
    IStakingModule public pendingStakingModule;
    /// @notice WETH Implementation used by MevEth.
    IWETH public immutable WETH;
    /// @notice Struct used to accounting the ETH staked within MevEth.
    Fraction public fraction;
    /// @notice Sandwich protection mapping of last user deposits by block number
    mapping(address => uint256) lastDeposit;

    /// @notice Central struct used for share accounting + math.
    /// @custom:field elastic   Represents total amount of staked ether, including rewards accrued / slashed.
    /// @custom:field base      Represents claims to ownership of the staked ether.
    struct Fraction {
        uint128 elastic;
        uint128 base;
    }

    /*//////////////////////////////////////////////////////////////
                                Setup
    //////////////////////////////////////////////////////////////*/

    /// @notice Construction creates mevETH token, sets authority and weth address.
    /// @dev Pending staking module and committed timestamp will both be zero on deployment.
    /// @param authority Address of the controlling admin authority.
    /// @param weth Address of the WETH contract to use for deposits.
    /// @param layerZeroEndpoint Chain specific endpoint for LayerZero.
    constructor(
        address authority,
        address weth,
        address layerZeroEndpoint
    )
        OFTWithFee("Mev Liquid Staked Ether", "mevETH", 18, 8, authority, layerZeroEndpoint)
    {
        WETH = IWETH(weth);
    }

    /// @notice Calculate the needed Ether buffer required when creating a new validator.
    /// @return uint256 The required Ether buffer.
    function calculateNeededEtherBuffer() public view returns (uint256) {
        unchecked {
            return max(withdrawalAmountQueued, (stakingModule.VALIDATOR_DEPOSIT_SIZE() / 100) * 90);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            Admin Control Panel
    //////////////////////////////////////////////////////////////*/

    /// @notice Event emitted when the MevEth is successfully initialized.
    event MevEthInitialized(address indexed mevEthShareVault, address indexed stakingModule);

    /// @notice Initializes the MevEth contract, setting the staking module and share vault addresses.
    /// @param initialShareVault The initial share vault set during initialization.
    /// @param initialStakingModule The initial staking module set during initialization.
    /// @dev This function can only be called once and is protected by the onlyAdmin modifier.
    function init(address initialShareVault, address initialStakingModule) external onlyAdmin {
        // Revert if the initial share vault or staking module is the zero address.
        if (initialShareVault == address(0)) {
            revert MevEthErrors.ZeroAddress();
        }

        if (initialStakingModule == address(0)) {
            revert MevEthErrors.ZeroAddress();
        }

        // Revert if the contract has already been initialized.
        if (initialized) {
            revert MevEthErrors.AlreadyInitialized();
        }

        // Update state variables and emit event to notify offchain listeners that the contract has been initialized.
        initialized = true;
        mevEthShareVault = initialShareVault;
        stakingModule = IStakingModule(initialStakingModule);
        emit MevEthInitialized(initialShareVault, initialStakingModule);
    }

    /// @notice Emitted when staking is paused.
    event StakingPaused();
    /// @notice Emitted when staking is unpaused.
    event StakingUnpaused();

    /// @notice Ensures that staking is not paused when invoking a specific function.
    /// @dev This check is used on the createValidator, deposit and mint functions.
    function _stakingUnpaused() internal view {
        if (stakingPaused) revert MevEthErrors.StakingPaused();
    }

    /// @notice Pauses staking on the MevEth contract.
    /// @dev This function is only callable by addresses with the admin role.
    function pauseStaking() external onlyAdmin {
        stakingPaused = true;
        emit StakingPaused();
    }

    /// @notice Unauses staking on the MevEth contract.
    /// @dev This function is only callable by addresses with the admin role.
    function unpauseStaking() external onlyAdmin {
        stakingPaused = false;
        emit StakingUnpaused();
    }

    /// @notice Event emitted when a new staking module is committed. The MODULE_UPDATE_TIME_DELAY must elapse before the staking module update can be
    /// finalized.
    event StakingModuleUpdateCommitted(address indexed oldModule, address indexed pendingModule, uint64 indexed eligibleForFinalization);
    /// @notice Event emitted when a new staking module is finalized.
    event StakingModuleUpdateFinalized(address indexed oldModule, address indexed newModule);
    /// @notice Event emitted when a new pending module update is canceled.
    event StakingModuleUpdateCanceled(address indexed oldModule, address indexed pendingModule);

    /// @notice Starts the process to update the staking module. To finalize the update, the MODULE_UPDATE_TIME_DELAY must elapse and the
    ///         finalizeUpdateStakingModule function must be called.
    /// @param newModule The new staking module.
    /// @dev This function is only callable by addresses with the admin role.
    function commitUpdateStakingModule(IStakingModule newModule) external onlyAdmin {
        pendingStakingModule = newModule;
        pendingStakingModuleCommittedTimestamp = uint64(block.timestamp);
        emit StakingModuleUpdateCommitted(address(stakingModule), address(newModule), uint64(block.timestamp + MODULE_UPDATE_TIME_DELAY));
    }

    /// @notice Finalizes the staking module update if a pending staking module exists.
    /// @dev This function is only callable by addresses with the admin role.
    function finalizeUpdateStakingModule() external onlyAdmin {
        // Revert if there is no pending staking module or if the the staking module finalization is premature.
        uint64 committedTimestamp = pendingStakingModuleCommittedTimestamp;
        if (address(pendingStakingModule) == address(0) || _isZero(committedTimestamp)) {
            revert MevEthErrors.InvalidPendingStakingModule();
        }

        if (uint64(block.timestamp) < committedTimestamp + MODULE_UPDATE_TIME_DELAY) {
            revert MevEthErrors.PrematureStakingModuleUpdateFinalization();
        }

        // Emit an event to notify offchain listeners that the staking module has been finalized.
        emit StakingModuleUpdateFinalized(address(stakingModule), address(pendingStakingModule));

        // Update the staking module
        stakingModule = IStakingModule(address(pendingStakingModule));

        // Set the pending staking module variables to zero.
        pendingStakingModule = IStakingModule(address(0));
        pendingStakingModuleCommittedTimestamp = 0;
    }

    /// @notice Cancels a pending staking module update.
    /// @dev This function is only callable by addresses with the admin role.
    function cancelUpdateStakingModule() external onlyAdmin {
        // Revert if there is no pending staking module.
        if (address(pendingStakingModule) == address(0) || _isZero(pendingStakingModuleCommittedTimestamp)) {
            revert MevEthErrors.InvalidPendingStakingModule();
        }

        // Emit an event to notify offchain listeners that the staking module has been canceled.
        emit StakingModuleUpdateCanceled(address(stakingModule), address(pendingStakingModule));

        // Set the pending staking module variables to zero.
        pendingStakingModule = IStakingModule(address(0));
        pendingStakingModuleCommittedTimestamp = 0;
    }

    /// @notice Event emitted when a new share vault is committed. To finalize the update, the MODULE_UPDATE_TIME_DELAY must elapse and the
    ///         finalizeUpdateMevEthShareVault function must be called.
    event MevEthShareVaultUpdateCommitted(address indexed oldVault, address indexed pendingVault, uint64 indexed eligibleForFinalization);
    /// @notice Event emitted when a new share vault is finalized.
    event MevEthShareVaultUpdateFinalized(address indexed oldVault, address indexed newVault);
    /// @notice Event emitted when a new pending share vault update is canceled.
    event MevEthShareVaultUpdateCanceled(address indexed oldVault, address indexed newVault);

    /// @notice Starts the process to update the share vault. To finalize the update, the MODULE_UPDATE_TIME_DELAY must elapse and the
    ///         finalizeUpdateStakingModule function must be called.
    /// @param newMevEthShareVault The new share vault
    /// @dev This function is only callable by addresses with the admin role
    function commitUpdateMevEthShareVault(address newMevEthShareVault) external onlyAdmin {
        pendingMevEthShareVault = newMevEthShareVault;
        pendingMevEthShareVaultCommittedTimestamp = uint64(block.timestamp);
        emit MevEthShareVaultUpdateCommitted(mevEthShareVault, newMevEthShareVault, uint64(block.timestamp + MODULE_UPDATE_TIME_DELAY));
    }

    /// @notice Finalizes the share vault update if a pending share vault exists.
    /// @dev This function is only callable by addresses with the admin role.
    function finalizeUpdateMevEthShareVault() external onlyAdmin {
        // Revert if there is no pending share vault or if the the share vault finalization is premature.
        uint64 committedTimestamp = pendingMevEthShareVaultCommittedTimestamp;
        if (pendingMevEthShareVault == address(0) || _isZero(committedTimestamp)) {
            revert MevEthErrors.InvalidPendingMevEthShareVault();
        }

        if (uint64(block.timestamp) < committedTimestamp + MODULE_UPDATE_TIME_DELAY) {
            revert MevEthErrors.PrematureMevEthShareVaultUpdateFinalization();
        }
        //TODO: we need to do this for both the staking module and the mev share vault
        /// @custom:: When finalizing the update to the MevEthShareVault, make sure to grant any remaining rewards from the existing share vault.
        // Emit an event to notify offchain listeners that the share vault has been finalized.
        emit MevEthShareVaultUpdateFinalized(mevEthShareVault, address(pendingMevEthShareVault));

        // Update the mev share vault
        mevEthShareVault = pendingMevEthShareVault;

        // Set the pending vault variables to zero
        pendingMevEthShareVault = address(0);
        pendingMevEthShareVaultCommittedTimestamp = 0;
    }

    /// @notice Cancels a pending share vault update.
    /// @dev This function is only callable by addresses with the admin role.
    function cancelUpdateMevEthShareVault() external onlyAdmin {
        // Revert if there is no pending share vault.
        if (pendingMevEthShareVault == address(0) || _isZero(pendingMevEthShareVaultCommittedTimestamp)) {
            revert MevEthErrors.InvalidPendingMevEthShareVault();
        }
        // Emit an event to notify offchain listeners that the share vault has been canceled.
        emit MevEthShareVaultUpdateCanceled(mevEthShareVault, pendingMevEthShareVault);

        //Set the pending vault variables to zero
        pendingMevEthShareVault = address(0);
        pendingMevEthShareVaultCommittedTimestamp = 0;
    }

    /*//////////////////////////////////////////////////////////////
                            Registry For Validators
    //////////////////////////////////////////////////////////////*/

    /// @notice Event emitted when a new validator is created
    event ValidatorCreated(address indexed stakingModule, IStakingModule.ValidatorData newValidator);

    /// @notice This function passes through the needed Ether to the Staking module, and the assosiated credentials with it
    /// @param newData The data needed to create a new validator
    /// @dev This function is only callable by addresses with the operator role and if staking is unpaused
    function createValidator(IStakingModule.ValidatorData calldata newData, bytes32 latestDepositRoot) external onlyOperator {
        _stakingUnpaused();
        IStakingModule _stakingModule = stakingModule;
        // Determine how big deposit is for the validator
        // *Note this will change if Rocketpool or similar modules are used
        uint256 depositSize = _stakingModule.VALIDATOR_DEPOSIT_SIZE();

        if (address(this).balance < depositSize + calculateNeededEtherBuffer()) {
            revert MevEthErrors.NotEnoughEth();
        }

        // Deposit the Ether into the staking contract
        _stakingModule.deposit{ value: depositSize }(newData, latestDepositRoot);

        emit ValidatorCreated(address(_stakingModule), newData);
    }

    /// @notice Event emitted when rewards are granted.
    event Rewards(address sender, uint256 amount);

    /// @notice Grants rewards from the MevEthShareVault, updating the fraction.elastic.
    /// @dev Before updating the fraction, the withdraw queue is processed, which pays out any pending withdrawals.
    /// @dev This function is only callable by the MevEthShareVault.
    function grantRewards() external payable {
        if (!(msg.sender == address(stakingModule) || msg.sender == mevEthShareVault)) revert MevEthErrors.InvalidSender();

        /// @dev Note that while a small possiblity, it is possible for the MevEthShareVault rewards + fraction.elastic to overflow a uint128.
        /// @dev in this case, the grantRewards call will fail and the funds will be secured to the MevEthShareVault.beneficiary address.
        fraction.elastic += uint128(msg.value);
        emit Rewards(msg.sender, msg.value);
    }

    /// @notice  Emitted when validator withdraw funds are received.
    event ValidatorWithdraw(address sender, uint256 amount);

    /// @notice Allows the MevEthShareVault or the staking module to withdraw validator funds from the contract.
    /// @dev Before updating the fraction, the withdrawal queue is processed, which pays out any pending withdrawals.
    /// @dev This function is only callable by the MevEthShareVault or the staking module.
    function grantValidatorWithdraw() external payable {
        // Check that the sender is the staking module or the MevEthShareVault.
        if (!(msg.sender == address(stakingModule) || msg.sender == mevEthShareVault)) revert MevEthErrors.InvalidSender();

        // Check that the value is not zero
        if (msg.value == 0) {
            revert MevEthErrors.ZeroValue();
        }

        // Emit an event to notify offchain listeners that a validator has withdrawn funds.
        emit ValidatorWithdraw(msg.sender, msg.value);

        // If the msg.value is 32 ether, the elastic should not be updated.
        if (msg.value == 32 ether) {
            return;
        }

        // If the msg.value is less than 32 ether, the elastic should be reduced.
        if (msg.value < 32 ether) {
            /// @dev Elastic will always be at least equal to base. Base will always be at least equal to the MIN_DEPOSIT amount.
            // assume slashed value so reduce elastic balance accordingly
            fraction.elastic -= uint128(32 ether - msg.value);
        } else {
            // If the msg.value is greater than 32 ether, the elastic should be increased.
            // account for any unclaimed rewards
            fraction.elastic += uint128(msg.value - 32 ether);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            WITHDRAWAL QUEUE
    //////////////////////////////////////////////////////////////*/

    /// @notice Struct representing a withdrawal ticket which is added to the withdrawal queue.
    /// @custom:field claimed               True if this receiver has received ticket funds.
    /// @custom:field receiver              The receiever of the ETH specified in the WithdrawalTicket.
    /// @custom:field amount                The amount of ETH to send to the receiver when the ticket is processed.
    /// @custom:field accumulatedAmount     Keep a running sum of all requested ETH
    struct WithdrawalTicket {
        bool claimed;
        address receiver;
        uint128 amount;
        uint128 accumulatedAmount;
    }

    /// @notice Event emitted when a withdrawal ticket is added to the queue.
    event WithdrawalQueueOpened(address indexed recipient, uint256 indexed withdrawalId, uint256 assets);
    event WithdrawalQueueClosed(address indexed recipient, uint256 indexed withdrawalId, uint256 assets);

    /// @notice The length of the withdrawal queue.
    uint256 public queueLength;

    /// @notice  mark the latest withdrawal request that was finalised
    uint256 public requestsFinalisedUntil;

    /// @notice Withdrawal amount queued
    uint256 public withdrawalAmountQueued;

    /// @notice The mapping representing the withdrawal queue.
    /// @dev The index in the queue is the key, and the value is the WithdrawalTicket.
    mapping(uint256 ticketNumber => WithdrawalTicket ticket) public withdrawalQueue;

    /// @notice Claim Finalised Withdrawal Ticket
    /// @param withdrawalId Unique ID of the withdrawal ticket
    function claim(uint256 withdrawalId) external {
        if (withdrawalId > requestsFinalisedUntil) revert MevEthErrors.NotFinalised();
        WithdrawalTicket storage ticket = withdrawalQueue[withdrawalId];
        if (ticket.claimed) revert MevEthErrors.AlreadyClaimed();
        withdrawalQueue[withdrawalId].claimed = true;
        withdrawalAmountQueued -= uint256(ticket.amount);
        emit WithdrawalQueueClosed(ticket.receiver, withdrawalId, uint256(ticket.amount));
        WETH.deposit{ value: uint256(ticket.amount) }();
        ERC20(address(WETH)).safeTransfer(ticket.receiver, uint256(ticket.amount));
    }

    /// @notice Processes the withdrawal queue, reserving any pending withdrawals with the contract's available balance.
    function processWithdrawalQueue(uint256 newRequestsFinalisedUntil) external onlyOperator {
        if (newRequestsFinalisedUntil > queueLength) revert MevEthErrors.IndexExceedsQueueLength();
        uint256 balance = address(this).balance;
        if (withdrawalAmountQueued >= balance) revert MevEthErrors.NotEnoughEth();
        uint256 available = balance - withdrawalAmountQueued;

        uint256 finalised = requestsFinalisedUntil;
        if (newRequestsFinalisedUntil < finalised) revert MevEthErrors.AlreadyFinalised();

        uint256 delta = uint256(withdrawalQueue[newRequestsFinalisedUntil].accumulatedAmount - withdrawalQueue[finalised].accumulatedAmount);
        if (available < delta) revert MevEthErrors.NotEnoughEth();

        requestsFinalisedUntil = newRequestsFinalisedUntil;
        withdrawalAmountQueued += delta;
    }

    /*//////////////////////////////////////////////////////////////
                            ERC4626 Support
    //////////////////////////////////////////////////////////////*/
    /// @notice The underlying asset of the mevEth contract
    /// @return assetTokenAddress The address of the asset token
    function asset() external view returns (address assetTokenAddress) {
        assetTokenAddress = address(WETH);
    }

    /// @notice The total amount of assets controlled by the mevEth contract
    /// @return totalManagedAssets The amount of eth controlled by the mevEth contract
    function totalAssets() external view returns (uint256 totalManagedAssets) {
        // Should return the total amount of Ether managed by the contract
        totalManagedAssets = uint256(fraction.elastic);
    }

    /// @notice Function to convert a specified amount of assets to shares based on the elastic and base.
    /// @param assets The amount of assets to convert to shares
    /// @return shares The value of the given assets in shares
    function convertToShares(uint256 assets) public view returns (uint256 shares) {
        // So if there are no shares, then they will mint 1:1 with assets
        // Otherwise, shares will mint proportional to the amount of assets
        if (_isZero(uint256(fraction.elastic)) || _isZero(uint256(fraction.base))) {
            shares = assets;
        } else {
            shares = (assets * uint256(fraction.base)) / uint256(fraction.elastic);
        }
    }

    /// @notice Function to convert a specified amount of shares to assets based on the elastic and base.
    /// @param shares The amount of shares to convert to assets
    /// @return assets The value of the given shares in assets
    function convertToAssets(uint256 shares) public view returns (uint256 assets) {
        // So if there are no shares, then they will mint 1:1 with assets
        // Otherwise, shares will mint proportional to the amount of assets
        if (_isZero(uint256(fraction.elastic)) || _isZero(uint256(fraction.base))) {
            assets = shares;
        } else {
            assets = (shares * uint256(fraction.elastic)) / uint256(fraction.base);
        }
    }

    /// @notice Function to indicate the maximum deposit possible.
    /// @return maxAssets The maximum amount of assets that can be deposited.
    function maxDeposit(address) external view returns (uint256 maxAssets) {
        // If staking is paused, then no deposits can be made
        if (stakingPaused) {
            return 0;
        }
        // No practical limit on deposit for Ether
        maxAssets = uint256(MAX_DEPOSIT);
    }

    /// @notice Function to simulate the amount of shares that would be minted for a given deposit at the current ratio.
    /// @param assets The amount of assets that would be deposited
    /// @return shares The amount of shares that would be minted, *under ideal conditions* only
    function previewDeposit(uint256 assets) external view returns (uint256 shares) {
        return convertToShares(assets);
    }

    /// @notice internal deposit function to process Weth or Eth deposits
    /// @param assets The amount of assets to deposit
    function _deposit(uint256 assets) internal {
        if (_isZero(msg.value)) {
            ERC20(address(WETH)).safeTransferFrom(msg.sender, address(this), assets);
            WETH.withdraw(assets);
        } else {
            if (msg.value != assets) revert MevEthErrors.WrongDepositAmount();
        }
    }

    /// @notice Function to deposit assets into the mevEth contract
    /// @param assets The amount of WETH which should be deposited
    /// @param receiver The address user whom should receive the mevEth out
    /// @return shares The amount of shares minted
    function deposit(uint256 assets, address receiver) external payable returns (uint256 shares) {
        _stakingUnpaused();
        // If the deposit is less than the minimum deposit, revert
        if (assets < MIN_DEPOSIT) revert MevEthErrors.DepositTooSmall();

        // Convert the assets to shares and update the fraction elastic and base
        shares = convertToShares(assets);

        fraction.elastic += uint128(assets);
        fraction.base += uint128(shares);

        // Update last deposit block for the user recorded for sandwich protection
        lastDeposit[msg.sender] = block.number;

        // Deposit the assets
        _deposit(assets);

        // Mint MevEth shares to the receiver
        _mint(receiver, shares);

        // Emit the deposit event to notify offchain listeners that a deposit has occured
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @notice Function to indicate the maximum amount of shares that can be minted at the current ratio.
    /// @return maxShares The maximum amount of shares that can be minted
    function maxMint(address) external view returns (uint256 maxShares) {
        // If staking is paused, no shares can be minted
        if (stakingPaused) {
            return 0;
        }
        // No practical limit on mint for Ether
        return MAX_DEPOSIT;
    }

    /// @notice Function to simulate the amount of assets that would be required to mint a given amount of shares at the current ratio.
    /// @param shares The amount of shares that would be minted
    /// @return assets The amount of assets that would be required, *under ideal conditions* only
    function previewMint(uint256 shares) external view returns (uint256 assets) {
        return convertToAssets(shares);
    }

    /// @notice Function to mint shares of the mevEth contract
    /// @param shares The amount of shares that should be minted
    /// @param receiver The address user whom should receive the mevEth out
    /// @return assets The amount of assets deposited
    function mint(uint256 shares, address receiver) external payable returns (uint256 assets) {
        _stakingUnpaused();

        // Convert the shares to assets and update the fraction elastic and base
        assets = convertToAssets(shares);

        // If the deposit is less than the minimum deposit, revert
        if (assets < MIN_DEPOSIT) revert MevEthErrors.DepositTooSmall();

        fraction.elastic += uint128(assets);
        fraction.base += uint128(shares);

        // Update last deposit block for the user recorded for sandwich protection
        lastDeposit[msg.sender] = block.number;

        // Deposit the assets
        _deposit(assets);
        // Mint MevEth shares to the receiver
        _mint(receiver, shares);

        // Emit the deposit event to notify offchain listeners that a deposit has occured
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @notice Function to indicate the maximum amount of assets that can be withdrawn at the current state.
    /// @param owner The address in question of who would be withdrawing
    /// @return maxAssets The maximum amount of assets that can be withdrawn
    function maxWithdraw(address owner) public view returns (uint256 maxAssets) {
        // Withdrawal is either their maximum balance, or the internal buffer
        maxAssets = min(address(this).balance, convertToAssets(balanceOf[owner]));
    }

    /// @notice Function to simulate the amount of shares that would be allocated for a specified amount of assets.
    /// @param assets The amount of assets that would be withdrawn
    /// @return shares The amount of shares that would be burned, *under ideal conditions* only
    function previewWithdraw(uint256 assets) external view returns (uint256 shares) {
        shares = convertToShares(assets);
    }

    ///@notice Function to withdraw assets from the mevEth contract
    /// @param useQueue Flag whether to use the withdrawal queue
    /// @param receiver The address user whom should receive the mevEth out
    /// @param owner The address of the owner of the mevEth
    /// @param assets The amount of assets that should be withdrawn
    function _withdraw(bool useQueue, address receiver, address owner, uint256 assets) internal {
        uint256 availableBalance = address(this).balance - withdrawalAmountQueued; // available balance will be adjusted

        if (availableBalance < assets) {
            if (!useQueue) revert MevEthErrors.NotEnoughEth();
            uint128 amountOwed = uint128(assets - availableBalance);
            ++queueLength;
            withdrawalQueue[queueLength] = WithdrawalTicket({
                claimed: false,
                receiver: receiver,
                amount: amountOwed,
                accumulatedAmount: withdrawalQueue[queueLength - 1].accumulatedAmount + amountOwed
            });
            emit WithdrawalQueueOpened(receiver, queueLength, uint256(amountOwed));
            assets = availableBalance;
        }
        if (!_isZero(assets)) {
            emit Withdraw(msg.sender, owner, receiver, assets, convertToShares(assets));
            WETH.deposit{ value: assets }();
            ERC20(address(WETH)).safeTransfer(receiver, assets);
        }
    }

    /// @dev internal function to update allowance for withdraws if necessary
    /// @param owner owner of tokens
    /// @param shares amount of shares to update
    function _updateAllowance(address owner, uint256 shares) internal {
        if (owner != msg.sender) {
            if (allowance[owner][msg.sender] < shares) revert MevEthErrors.TransferExceedsAllowance();
            unchecked {
                allowance[owner][msg.sender] -= shares;
            }
        }
    }

    /// @notice Withdraw assets if balance is available
    /// @param assets The amount of assets that should be withdrawn
    /// @param receiver The address user whom should receive the mevEth out
    /// @param owner The address of the owner of the mevEth
    /// @return shares The amount of shares burned
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares) {
        // If withdraw is less than the minimum deposit / withdraw amount, revert
        if (assets < MIN_DEPOSIT) revert MevEthErrors.WithdrawTooSmall();
        if (lastDeposit[msg.sender] == block.number) revert MevEthErrors.CannotDepositAndWithdrawInSameBlock();

        // Convert the assets to shares and check if the owner has the allowance to withdraw the shares.
        shares = convertToShares(assets);

        _updateAllowance(owner, shares);

        // Update the elastic and base
        fraction.elastic -= uint128(assets);
        fraction.base -= uint128(shares);

        // Burn the shares and emit a withdraw event for offchain listeners to know that a withdraw has occured
        _burn(owner, shares);

        // Withdraw the assets from the Mevth contract
        _withdraw(false, receiver, owner, assets);
    }

    /// @notice Withdraw assets or open queue ticket for claim depending on balance available
    /// @param assets The amount of assets that should be withdrawn
    /// @param receiver The address user whom should receive the mevEth out
    /// @param owner The address of the owner of the mevEth
    /// @return shares The amount of shares burned
    function withdrawQueue(uint256 assets, address receiver, address owner) external returns (uint256 shares) {
        // If withdraw is less than the minimum deposit / withdraw amount, revert
        if (assets < MIN_DEPOSIT) revert MevEthErrors.WithdrawTooSmall();
        if (lastDeposit[msg.sender] == block.number) revert MevEthErrors.CannotDepositAndWithdrawInSameBlock();

        // Convert the assets to shares and check if the owner has the allowance to withdraw the shares.
        shares = convertToShares(assets);

        _updateAllowance(owner, shares);

        // Update the elastic and base
        fraction.elastic -= uint128(assets);
        fraction.base -= uint128(shares);

        // Burn the shares and emit a withdraw event for offchain listeners to know that a withdraw has occured
        _burn(owner, shares);

        // Withdraw the assets from the Mevth contract
        _withdraw(true, receiver, owner, assets);
    }

    ///@notice Function to simulate the maximum amount of shares that can be redeemed by the owner.
    /// @param owner The address in question of who would be redeeming their shares
    /// @return maxShares The maximum amount of shares they could redeem
    function maxRedeem(address owner) external view returns (uint256 maxShares) {
        maxShares = min(convertToShares(address(this).balance), balanceOf[owner]);
    }

    /// @notice Function to simulate the amount of assets that would be withdrawn for a specified amount of shares.
    /// @param shares The amount of shares that would be burned
    /// @return assets The amount of assets that would be withdrawn, *under ideal conditions* only
    function previewRedeem(uint256 shares) external view returns (uint256 assets) {
        assets = convertToAssets(shares);
    }

    /// @notice Function to redeem shares from the mevEth contract
    /// @param shares The amount of shares that should be burned
    /// @param receiver The address user whom should receive the wETH out
    /// @param owner The address of the owner of the mevEth
    /// @return assets The amount of assets withdrawn
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets) {
        // Convert the shares to assets and check if the owner has the allowance to withdraw the shares.
        assets = convertToAssets(shares);

        // If withdraw is less than the minimum deposit / withdraw amount, revert
        if (assets < MIN_DEPOSIT) revert MevEthErrors.WithdrawTooSmall();
        if (lastDeposit[msg.sender] == block.number) revert MevEthErrors.CannotDepositAndWithdrawInSameBlock();

        // Convert the assets to shares and check if the owner has the allowance to withdraw the shares.
        shares = convertToShares(assets);

        _updateAllowance(owner, shares);

        // Update the elastic and base
        fraction.elastic -= uint128(assets);
        fraction.base -= uint128(shares);

        // Burn the shares and emit a withdraw event for offchain listeners to know that a withdraw has occured
        _burn(owner, shares);

        // Withdraw the assets from the Mevth contract
        _withdraw(false, receiver, owner, assets);
    }

    /*//////////////////////////////////////////////////////////////
                            Utility Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the largest of two numbers.
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /// @dev Returns the smallest of two numbers.

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @dev Gas efficient zero check
    function _isZero(uint256 value) internal pure returns (bool boolValue) {
        // Stack Only Safety
        assembly ("memory-safe") {
            boolValue := iszero(value)
        }
    }

    /// @dev Only Weth withdraw is defined for the behaviour. Deposits should be directed to deposit / mint. Rewards via grantRewards and validator withdraws
    /// via grantValidatorWithdraw.
    receive() external payable {
        if (msg.sender != address(WETH)) revert MevEthErrors.InvalidSender();
    }
}
