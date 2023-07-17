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
/// @dev LSR is represented through an ERC4626 token and interface
contract MevEth is OFTWithFee, IERC4626, ITinyMevEth {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /// @notice Central struct used for share accounting + math
    /// @param elastic Represents total amount of staked ether, including rewards accrued / slashed
    /// @param base Represents claims to ownership of the staked ether
    struct Fraction {
        uint128 elastic;
        uint128 base;
    }

    /*//////////////////////////////////////////////////////////////
                            Configuration Variables
    //////////////////////////////////////////////////////////////*/
    bool public stakingPaused;
    bool public initialized;
    /// @notice amount of eth to retain on contract for withdrawls as a percent numerator
    uint8 public bufferPercentNumerator;
    uint64 public pendingStakingModuleCommittedTimestamp;
    uint64 public pendingMevEthShareVaultCommittedTimestamp;
    uint64 public constant MODULE_UPDATE_TIME_DELAY = 7 days;
    uint128 public constant MAX_DEPOSIT = 2 ** 128 - 1;
    uint128 public constant MIN_DEPOSIT = 10_000_000_000_000_000; // 0.01 eth
    address public mevEthShareVault;
    address public pendingMevEthShareVault;
    IStakingModule public stakingModule;
    IStakingModule public pendingStakingModule;
    /// @notice WETH Implementation used by MevEth
    IWETH public immutable WETH;
    Fraction public fraction;

    /*//////////////////////////////////////////////////////////////
                                Setup
    //////////////////////////////////////////////////////////////*/

    /// @notice Construction creates mevETH token, sets authority and weth address
    /// @dev pending staking module and committed timestamp will both be zero on deployment
    /// @param authority The address of the controlling admin authority
    /// @param weth The address of the WETH contract to use for deposits
    /// @param layerZeroEndpoint chain specific endpoint
    constructor(
        address authority,
        address weth,
        address layerZeroEndpoint
    )
        OFTWithFee("Mev Liquid Staked Ether", "mevETH", 18, 8, authority, layerZeroEndpoint)
    {
        WETH = IWETH(weth);
        bufferPercentNumerator = 2; // set at 2 %
    }

    function calculateNeededEtherBuffer() public view returns (uint256) {
        unchecked {
            return max((uint256(fraction.elastic) * uint256(bufferPercentNumerator)) / 100, 31 ether);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            Admin Control Panel
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Emitted when contract is initialized
     */
    event MevEthInitialized(address indexed mevEthShareVault, address indexed stakingModule);

    /// @param initialShareVault The initial share vault to set when initializing the contract.
    /// @param initialStakingModule The initial staking module to set when initializing the contract.
    function init(address initialShareVault, address initialStakingModule) external onlyAdmin {
        if (initialShareVault == address(0)) {
            revert MevEthErrors.ZeroAddress();
        }

        if (initialStakingModule == address(0)) {
            revert MevEthErrors.ZeroAddress();
        }

        if (initialized) {
            revert MevEthErrors.AlreadyInitialized();
        }

        initialized = true;

        mevEthShareVault = initialShareVault;
        stakingModule = IStakingModule(initialStakingModule);

        emit MevEthInitialized(initialShareVault, initialStakingModule);
    }

    /// @notice Update bufferPercentNumerator
    /// @param newBufferPercentNumerator updated percent numerator
    function updateBufferPercentNumerator(uint8 newBufferPercentNumerator) external onlyAdmin {
        bufferPercentNumerator = newBufferPercentNumerator;
    }

    /// @notice Modifier that checks if staking is paused, and reverts if so
    modifier stakingUnpaused() {
        if (stakingPaused) {
            revert MevEthErrors.StakingPaused();
        }
        _;
    }

    /**
     * @dev Emitted when staking is paused
     */
    event StakingPaused();

    /**
     * @notice This function pauses staking for the contract.
     * @dev Only the owner of the contract can call this function.
     */
    function pauseStaking() external onlyAdmin {
        stakingPaused = true;

        emit StakingPaused();
    }

    /**
     * @dev Emitted when staking is unpaused
     */
    event StakingUnpaused();

    /**
     * @notice This function unpauses staking
     * @dev This function is only callable by the owner and sets the stakingPaused variable to false. It also emits the StakingUnpaused event.
     */
    function unpauseStaking() external onlyAdmin {
        stakingPaused = false;
        emit StakingUnpaused();
    }

    event StakingModuleUpdateCommitted(address indexed oldModule, address indexed pendingModule, uint64 indexed eligibleForFinalization);

    /**
     * @notice Starts the process to update the staking module. To finalize the update, the MODULE_UPDATE_TIME_DELAY must elapse and the
     * finalizeUpdateStakingModule function must be called
     * @param newModule The new staking module to replace the existing one
     */
    function commitUpdateStakingModule(IStakingModule newModule) external onlyAdmin {
        pendingStakingModule = newModule;
        pendingStakingModuleCommittedTimestamp = uint64(block.timestamp);
        emit StakingModuleUpdateCommitted(address(stakingModule), address(newModule), uint64(block.timestamp + MODULE_UPDATE_TIME_DELAY));
    }

    event StakingModuleUpdateFinalized(address indexed oldModule, address indexed newModule);

    /**
     * @notice Finalizes the staking module update after the timelock delay has elapsed.
     */
    function finalizeUpdateStakingModule() external onlyAdmin {
        uint64 committedTimestamp = pendingStakingModuleCommittedTimestamp;

        if (address(pendingStakingModule) == address(0) || _isZero(committedTimestamp)) {
            revert MevEthErrors.InvalidPendingStakingModule();
        }

        if (uint64(block.timestamp) < committedTimestamp + MODULE_UPDATE_TIME_DELAY) {
            revert MevEthErrors.PrematureStakingModuleUpdateFinalization();
        }

        emit StakingModuleUpdateFinalized(address(stakingModule), address(pendingStakingModule));

        //Update the staking module
        stakingModule = IStakingModule(address(pendingStakingModule));

        //Set the pending staking module variables to zero
        pendingStakingModule = IStakingModule(address(0));
        pendingStakingModuleCommittedTimestamp = 0;
    }

    event StakingModuleUpdateCanceled(address indexed oldModule, address indexed pendingModule);

    /**
     *  @notice Cancels a pending staking module update
     */
    function cancelUpdateStakingModule() external onlyAdmin {
        if (address(pendingStakingModule) == address(0) || _isZero(pendingStakingModuleCommittedTimestamp)) {
            revert MevEthErrors.InvalidPendingStakingModule();
        }

        emit StakingModuleUpdateCanceled(address(stakingModule), address(pendingStakingModule));

        //Set the pending staking module variables to zero
        pendingStakingModule = IStakingModule(address(0));
        pendingStakingModuleCommittedTimestamp = 0;
    }

    event MevEthShareVaultUpdateCommitted(address indexed oldVault, address indexed pendingVault, uint64 indexed eligibleForFinalization);

    /**
     * @notice Starts the process to update the mevEthShareVault. To finalize the update, the MODULE_UPDATE_TIME_DELAY must elapse and the
     * finalizeUpdateMevEthShareVault function must be called
     * @param newMevEthShareVault The new vault to replace the existing one
     */
    function commitUpdateMevEthShareVault(address newMevEthShareVault) external onlyAdmin {
        pendingMevEthShareVault = newMevEthShareVault;
        pendingMevEthShareVaultCommittedTimestamp = uint64(block.timestamp);
        emit MevEthShareVaultUpdateCommitted(mevEthShareVault, newMevEthShareVault, uint64(block.timestamp + MODULE_UPDATE_TIME_DELAY));
    }

    event MevEthShareVaultUpdateFinalized(address indexed oldVault, address indexed newVault);

    /**
     * @notice Finalizes the mevEthShareVault update after the timelock delay has elapsed.
     */
    function finalizeUpdateMevEthShareVault() external onlyAdmin {
        uint64 committedTimestamp = pendingMevEthShareVaultCommittedTimestamp;

        if (pendingMevEthShareVault == address(0) || _isZero(committedTimestamp)) {
            revert MevEthErrors.InvalidPendingMevEthShareVault();
        }

        if (uint64(block.timestamp) < committedTimestamp + MODULE_UPDATE_TIME_DELAY) {
            revert MevEthErrors.PrematureMevEthShareVaultUpdateFinalization();
        }

        /// @custom SAFETY: When finalizing the update to the MevEthShareVault, make sure to grant any remaining rewards from the existing share vault.

        emit MevEthShareVaultUpdateFinalized(mevEthShareVault, address(pendingMevEthShareVault));

        // Update the mev share vault
        mevEthShareVault = pendingMevEthShareVault;

        // Set the pending vault variables to zero
        pendingMevEthShareVault = address(0);
        pendingMevEthShareVaultCommittedTimestamp = 0;
    }

    event MevEthShareVaultUpdateCanceled(address indexed oldVault, address indexed newVault);

    /**
     *  @notice Cancels a pending mevEthShareVault.
     */
    function cancelUpdateMevEthShareVault() external onlyAdmin {
        if (pendingMevEthShareVault == address(0) || _isZero(pendingMevEthShareVaultCommittedTimestamp)) {
            revert MevEthErrors.InvalidPendingMevEthShareVault();
        }

        emit MevEthShareVaultUpdateCanceled(mevEthShareVault, pendingMevEthShareVault);

        //Set the pending vault variables to zero
        pendingMevEthShareVault = address(0);
        pendingMevEthShareVaultCommittedTimestamp = 0;
    }

    /*//////////////////////////////////////////////////////////////
                            Registry For Validators
    //////////////////////////////////////////////////////////////*/

    /// @notice This function passes through the needed Ether to the Staking module, and the assosiated credentials with it
    /// @param newData The data needed to create a new validator
    function createValidator(IStakingModule.ValidatorData calldata newData) external onlyOperator stakingUnpaused {
        // Determine how big deposit is for the validator
        // *Note this will change if Rocketpool or similar modules are used
        uint256 depositSize = stakingModule.VALIDATOR_DEPOSIT_SIZE();

        if (address(this).balance < depositSize + calculateNeededEtherBuffer()) {
            revert MevEthErrors.NotEnoughEth();
        }

        // Deposit the Ether into the staking contract
        stakingModule.deposit{ value: depositSize }(newData);
    }

    /**
     * @dev Emitted when rewards are received
     */
    event Rewards(address sender, uint256 amount);

    function grantRewards() external payable {
        processWithdrawalQueue();
        if (!(msg.sender == address(stakingModule) || msg.sender == mevEthShareVault)) revert MevEthErrors.InvalidSender();

        /// @dev Note that while a small possiblity, it is possible for the MevEthShareVault rewards + fraction.elastic to overflow a uint128
        /// @dev in this case, the grantRewards call will fail and the funds will be secured to the MevEthShareVault.beneficiary address.

        fraction.elastic += uint128(msg.value);
        emit Rewards(msg.sender, msg.value);
    }

    /**
     * @dev Emitted when validator withdraw funds are received
     */
    event ValidatorWithdraw(address sender, uint256 amount);

    function grantValidatorWithdraw() external payable {
        if (!(msg.sender == address(stakingModule) || msg.sender == mevEthShareVault)) revert MevEthErrors.InvalidSender();

        if (msg.value == 0) {
            revert MevEthErrors.ZeroValue();
        }
        processWithdrawalQueue();
        emit ValidatorWithdraw(msg.sender, msg.value);
        if (msg.value == 32 ether) {
            return;
        }

        if (msg.value < 32 ether) {
            /// @dev Elastic will always be at least equal to base. Base will always be at least equal to the MIN_DEPOSIT amount.
            // assume slashed value so reduce elastic balance accordingly
            fraction.elastic -= uint128(32 ether - msg.value);
        } else {
            // account for any unclaimed rewards
            fraction.elastic += uint128(msg.value - 32 ether);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            WITHDRAWAL QUEUE
    //////////////////////////////////////////////////////////////*/
    struct WithdrawalTicket {
        address receiver;
        uint256 amount;
    }

    event WithdrawalQueueOpened(address indexed receipient, uint256 indexed assets);

    uint256 queueLength;

    mapping(uint256 ticketNumber => WithdrawalTicket ticket) public withdrawalQueue;

    function processWithdrawalQueue() public {
        uint256 length = queueLength;
        while (length != 0) {
            WithdrawalTicket memory currentTicket = withdrawalQueue[length - 1];
            uint256 assetsOwed = currentTicket.amount;
            address receipient = currentTicket.receiver;
            if (address(this).balance >= assetsOwed) {
                WETH.deposit{ value: assetsOwed }();
                // SafeTransfer not needed because we know the impl
                ERC20(address(WETH)).safeTransfer(receipient, assetsOwed);
                // While not strictly neccessary persay, important for
                // added safety
                delete withdrawalQueue[length-1];
                length--;
            } else {
                queueLength = length;
                return;
            }
        }
        queueLength = 0;
    }

    /*//////////////////////////////////////////////////////////////
                            ERC4626 Support
    //////////////////////////////////////////////////////////////*/

    /// @return assetTokenAddress The address of the asset token
    function asset() external view returns (address assetTokenAddress) {
        assetTokenAddress = address(WETH);
    }

    /// @return totalManagedAssets The amount of eth controlled by the mevEth contract
    function totalAssets() external view returns (uint256 totalManagedAssets) {
        // Should return the total amount of Ether managed by the contract
        totalManagedAssets = uint256(fraction.elastic);
    }

    /// @param assets The amount of assets to convert to shares
    /// @return shares The value of the given assets in shares
    function convertToShares(uint256 assets) public view returns (uint256 shares) {
        // So if there are no shares, then they will mint 1:1 with assets
        // Otherwise, shares will mint proportional to the amount of assets
        if (_isZero(uint256(fraction.elastic)) || _isZero(uint256(fraction.base))) {
            shares = assets;
        } else {
            unchecked {
                shares = (assets * uint256(fraction.base)) / uint256(fraction.elastic);
            }
        }
    }

    /// @param shares The amount of shares to convert to assets
    /// @return assets The value of the given shares in assets
    function convertToAssets(uint256 shares) public view returns (uint256 assets) {
        // So if there are no shares, then they will mint 1:1 with assets
        // Otherwise, shares will mint proportional to the amount of assets
        if (_isZero(uint256(fraction.elastic)) || _isZero(uint256(fraction.base))) {
            assets = shares;
        } else {
            unchecked {
                assets = (shares * uint256(fraction.elastic)) / uint256(fraction.base);
            }
        }
    }

    /// @return maxAssets The maximum amount of assets that can be deposited
    function maxDeposit(address) external view returns (uint256 maxAssets) {
        if (stakingPaused) {
            return 0;
        }
        // No practical limit on deposit for Ether
        maxAssets = uint256(MAX_DEPOSIT);
    }

    /// @param assets The amount of assets that would be deposited
    /// @return shares The amount of shares that would be minted, *under ideal conditions* only
    function previewDeposit(uint256 assets) external view returns (uint256 shares) {
        return convertToShares(assets);
    }

    /// @dev internal deposit function to process Weth or Eth deposits
    function _deposit(uint256 assets) internal {
        if (_isZero(msg.value)) {
            ERC20(address(WETH)).safeTransferFrom(msg.sender, address(this), assets);
            WETH.withdraw(assets);
        } else {
            if (msg.value < assets) revert MevEthErrors.DepositTooSmall();
        }
    }

    /// @param assets The amount of WETH which should be deposited
    /// @param receiver The address user whom should receive the mevEth out
    /// @return shares The amount of shares minted
    function deposit(uint256 assets, address receiver) external payable stakingUnpaused returns (uint256 shares) {
        if (assets < MIN_DEPOSIT) revert MevEthErrors.DepositTooSmall();

        shares = convertToShares(assets);

        unchecked {
            fraction.elastic += uint128(assets);
            fraction.base += uint128(shares);
        }

        _deposit(assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @return maxShares The maximum amount of shares that can be minted
    function maxMint(address) external view returns (uint256 maxShares) {
        if (stakingPaused) {
            return 0;
        }
        // No practical limit on mint for Ether
        return MAX_DEPOSIT;
    }

    /// @param shares The amount of shares that would be minted
    /// @return assets The amount of assets that would be required, *under ideal conditions* only
    function previewMint(uint256 shares) external view returns (uint256 assets) {
        return convertToAssets(shares);
    }

    /// @param shares The amount of shares that should be minted
    /// @param receiver The address user whom should receive the mevEth out
    /// @return assets The amount of assets deposited
    function mint(uint256 shares, address receiver) external payable stakingUnpaused returns (uint256 assets) {
        if (shares < MIN_DEPOSIT) revert MevEthErrors.DepositTooSmall();

        assets = convertToAssets(shares);

        unchecked {
            fraction.elastic += uint128(assets);
            fraction.base += uint128(shares);
        }

        _deposit(assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @param owner The address in question of who would be withdrawing
    /// @return maxAssets The maximum amount of assets that can be withdrawn
    function maxWithdraw(address owner) public view returns (uint256 maxAssets) {
        // Withdrawal is either their maximum balance, or the internal buffer
        maxAssets = min(address(this).balance, convertToAssets(balanceOf[owner]));
    }

    /// @param assets The amount of assets that would be withdrawn
    /// @return shares The amount of shares that would be burned, *under ideal conditions* only
    function previewWithdraw(uint256 assets) external view returns (uint256 shares) {
        shares = convertToShares(assets);
    }

    /// @param assets The amount of assets that should be withdrawn
    /// @param receiver The address user whom should receive the mevEth out
    /// @param owner The address of the owner of the mevEth
    /// @return shares The amount of shares burned
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares) {
        shares = convertToShares(assets);

        if (owner != msg.sender) {
            if (allowance[owner][msg.sender] < shares) revert MevEthErrors.TransferExceedsAllowance();
            unchecked {
                allowance[owner][msg.sender] -= shares;
            }
        }

        unchecked {
            fraction.elastic -= uint128(assets);
            fraction.base -= uint128(shares);
        }

        if (fraction.base < MIN_DEPOSIT) {
            revert MevEthErrors.BelowMinimum();
        }

        _burn(owner, shares);

        emit Withdraw(msg.sender, owner, receiver, assets, shares);

        if (address(this).balance >= assets) {
            WETH.deposit{ value: assets }();
            ERC20(address(WETH)).safeTransfer(receiver, assets);
        } else {
            uint256 availableBalance = address(this).balance;
            uint256 amountOwed = assets - availableBalance;
            emit WithdrawalQueueOpened(receiver, amountOwed);
            withdrawalQueue[queueLength] = WithdrawalTicket({ receiver: receiver, amount: amountOwed });
            queueLength++;

            WETH.deposit{ value: availableBalance }();
            ERC20(address(WETH)).safeTransfer(receiver, availableBalance);
        }
    }

    /// @param owner The address in question of who would be redeeming their shares
    /// @return maxShares The maximum amount of shares they could redeem
    function maxRedeem(address owner) external view returns (uint256 maxShares) {
        maxShares = min(convertToShares(address(this).balance), balanceOf[owner]);
    }

    /// @param shares The amount of shares that would be burned
    /// @return assets The amount of assets that would be withdrawn, *under ideal conditions* only
    function previewRedeem(uint256 shares) external view returns (uint256 assets) {
        assets = convertToAssets(shares);
    }

    /// @param shares The amount of shares that should be burned
    /// @param receiver The address user whom should receive the wETH out
    /// @param owner The address of the owner of the mevEth
    /// @return assets The amount of assets withdrawn
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets) {
        assets = convertToAssets(shares);

        if (owner != msg.sender) {
            if (allowance[owner][msg.sender] < shares) revert MevEthErrors.TransferExceedsAllowance();
            unchecked {
                allowance[owner][msg.sender] -= shares;
            }
        }

        unchecked {
            fraction.elastic -= uint128(assets);
            fraction.base -= uint128(shares);
        }

        if (fraction.base < MIN_DEPOSIT) {
            revert MevEthErrors.BelowMinimum();
        }

        _burn(owner, shares);

        emit Withdraw(msg.sender, owner, receiver, assets, shares);

        if (address(this).balance >= assets) {
            WETH.deposit{ value: assets }();
            ERC20(address(WETH)).safeTransfer(receiver, assets);
        } else {
            uint256 availableBalance = address(this).balance;
            uint256 amountOwed = assets - availableBalance;
            emit WithdrawalQueueOpened(receiver, amountOwed);
            withdrawalQueue[queueLength] = WithdrawalTicket({ receiver: receiver, amount: amountOwed });
            queueLength++;

            WETH.deposit{ value: availableBalance }();
            ERC20(address(WETH)).safeTransfer(receiver, availableBalance);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            Utility Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @dev gas efficient zero check
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

    /// @dev Only Weth withdraw is defined for the behaviour. Deposits should be directed to deposit / mint. Rewards via grantRewards and validator withdraws
    /// via grantValidatorWithdraw.
    fallback() external payable {
        if (msg.sender != address(WETH)) revert MevEthErrors.InvalidSender();
    }
}
