// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

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
import { Auth } from "./libraries/Auth.sol";
import { IWETH } from "./interfaces/IWETH.sol";
import { MevEthErrors } from "./interfaces/Errors.sol";
import { IStakingModule } from "./interfaces/IStakingModule.sol";
import { MevEthShareVault } from "./MevEthShareVault.sol";
import { ITinyMevEth } from "./interfaces/ITinyMevEth.sol";
import { WagyuStaker } from "./WagyuStaker.sol";

/// @title MevEth
/// @author Manifold Finance
/// @dev Contract that allows deposit of ETH, for a Liquid Staking Receipt (LSR) in return.
/// @dev LSR is represented through an ERC4626 token and interface
contract MevEth is Auth, ERC20, IERC4626, ITinyMevEth {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /// @notice Central Rebase struct used for share accounting + math
    /// @param elastic Represents total amount of staked ether, including rewards accrued / slashed
    /// @param base Represents claims to ownership of the staked ether
    struct AssetsRebase {
        uint256 elastic;
        uint256 base;
    }

    /*//////////////////////////////////////////////////////////////
                            Configuration Variables
    //////////////////////////////////////////////////////////////*/
    bool public stakingPaused;
    /// @notice amount of eth to retain on contract for withdrawls as a percent numerator
    uint8 public bufferPercentNumerator;
    uint64 public pendingStakingModuleCommittedTimestamp;
    uint64 public pendingMevEthShareVaultCommittedTimestamp;
    uint64 public constant MODULE_UPDATE_TIME_DELAY = 7 days;
    address public mevEthShareVault;
    address public pendingMevEthShareVault;
    IStakingModule public stakingModule;
    IStakingModule public pendingStakingModule;
    // WETH Implementation used by MevEth
    IWETH public immutable WETH;
    AssetsRebase public assetRebase;

    /*//////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Emitted when rewards are received
     */
    event Rewards(address sender, uint256 amount);

    /**
     * @dev Emitted when validator withdraw funds are received
     */
    event ValidatorWithdraw(address sender, uint256 amount);

    /**
     * @dev Emitted when staking is paused
     */
    event StakingPaused();

    /**
     * @dev Emitted when staking is unpaused
     */
    event StakingUnpaused();

    event StakingModuleUpdateCommitted(address indexed oldModule, address indexed pendingModule, uint64 indexed eligibleForFinalization);
    event StakingModuleUpdateFinalized(address indexed oldModule, address indexed newModule);
    event StakingModuleUpdateCanceled(address indexed oldModule, address indexed pendingModule);
    event MevEthShareVaultUpdateCommitted(address indexed oldVault, address indexed pendingVault, uint64 indexed eligibleForFinalization);
    event MevEthShareVaultUpdateFinalized(address indexed oldVault, address indexed newVault);
    event MevEthShareVaultUpdateCanceled(address indexed oldVault, address indexed newVault);

    /*//////////////////////////////////////////////////////////////
                                Setup
    //////////////////////////////////////////////////////////////*/

    /// @notice Construction creates mevETH token, sets authority, staking contract and weth address
    /// @dev pending staking module and committed timestamp will both be zero on deployment
    /// @param authority The address of the controlling admin authority
    /// @param depositContract Beaconchain deposit contract address
    /// @param initialFeeRewardsPerBlock TODO: describe this variable
    /// @param weth The address of the WETH contract to use for deposits
    /// @dev When the contract is deployed, the pendingStakingModule, pendingStakingModuleCommitedTimestamp, pendingMevEthShareVault and
    /// pendingMevEthShareVaultCommitedTimestamp are all zero initialized
    constructor(
        address authority,
        address depositContract,
        uint256 initialFeeRewardsPerBlock,
        address weth
    )
        Auth(authority)
        ERC20("Mev Liquid Staked Ether", "mevETH", 18)
    {
        mevEthShareVault = address(new MevEthShareVault(address(this), initialFeeRewardsPerBlock));
        WagyuStaker staker = new WagyuStaker(depositContract, address(this));
        stakingModule = IStakingModule(address(staker));
        WETH = IWETH(weth);
        bufferPercentNumerator = 2; // set at 2 %
    }

    /*//////////////////////////////////////////////////////////////
                            Admin Control Panel
    //////////////////////////////////////////////////////////////*/

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
     * @notice This function pauses staking for the contract.
     * @dev Only the owner of the contract can call this function.
     */
    function pauseStaking() external onlyAdmin {
        stakingPaused = true;

        emit StakingPaused();
    }

    /**
     * @notice This function unpauses staking
     * @dev This function is only callable by the owner and sets the stakingPaused variable to false. It also emits the StakingUnpaused event.
     */
    function unpauseStaking() external onlyAdmin {
        stakingPaused = false;
        emit StakingUnpaused();
    }

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

    /**
     * @notice Finalizes the staking module update after the timelock delay has elapsed.
     */
    function finalizeUpdateStakingModule() external onlyAdmin {
        uint64 committedTimestamp = pendingStakingModuleCommittedTimestamp;

        if (pendingStakingModule == IStakingModule(address(0)) || committedTimestamp == 0) {
            revert MevEthErrors.InvalidPendingStakingModule();
        }

        if (uint64(block.timestamp) < committedTimestamp + MODULE_UPDATE_TIME_DELAY) {
            revert MevEthErrors.PrematureStakingModuleUpdateFinalization();
        }

        address oldModule = address(stakingModule);
        address newModule = address(pendingStakingModule);

        //Update the staking module
        stakingModule = IStakingModule(newModule);

        //Set the pending staking module variables to zero
        pendingStakingModule = IStakingModule(address(0));
        pendingStakingModuleCommittedTimestamp = 0;

        emit StakingModuleUpdateFinalized(oldModule, address(newModule));
    }

    /**
     *  @notice Cancels a pending staking module update
     */
    function cancelUpdateStakingModule() external onlyAdmin {
        if (pendingStakingModule == IStakingModule(address(0)) || pendingStakingModuleCommittedTimestamp == 0) {
            revert MevEthErrors.InvalidPendingStakingModule();
        }

        address oldModule = address(stakingModule);
        address pendingModule = address(pendingStakingModule);

        //Set the pending staking module variables to zero
        pendingStakingModule = IStakingModule(address(0));
        pendingStakingModuleCommittedTimestamp = 0;

        emit StakingModuleUpdateCanceled(oldModule, address(pendingModule));
    }

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

    /**
     * @notice Finalizes the mevEthShareVault update after the timelock delay has elapsed.
     */
    function finalizeUpdateMevEthShareVault() external onlyAdmin {
        uint64 committedTimestamp = pendingMevEthShareVaultCommittedTimestamp;

        if (pendingMevEthShareVault == address(0) || committedTimestamp == 0) {
            revert MevEthErrors.InvalidPendingMevEthShareVault();
        }

        if (uint64(block.timestamp) < committedTimestamp + MODULE_UPDATE_TIME_DELAY) {
            revert MevEthErrors.PrematureMevEthShareVaultUpdateFinalization();
        }

        address oldModule = mevEthShareVault;
        address newModule = pendingMevEthShareVault;

        //Update the mev share vault
        mevEthShareVault = newModule;

        //Set the pending vault variables to zero
        pendingMevEthShareVault = address(0);
        pendingMevEthShareVaultCommittedTimestamp = 0;

        emit MevEthShareVaultUpdateFinalized(oldModule, address(newModule));
    }

    /**
     *  @notice Cancels a pending mevEthShareVault.
     */
    function cancelUpdateMevEthShareVault() external onlyAdmin {
        if (pendingMevEthShareVault == address(0) || pendingMevEthShareVaultCommittedTimestamp == 0) {
            revert MevEthErrors.InvalidPendingMevEthShareVault();
        }

        address pendingVault = pendingMevEthShareVault;

        //Set the pending vault variables to zero
        pendingMevEthShareVault = address(0);
        pendingMevEthShareVaultCommittedTimestamp = 0;

        emit MevEthShareVaultUpdateCanceled(mevEthShareVault, pendingVault);
    }

    /*//////////////////////////////////////////////////////////////
                            Registry For Validators
    //////////////////////////////////////////////////////////////*/

    /// @notice This function passes through the needed Ether to the Staking module, and the assosiated credentials with it
    /// @param newData The data needed to create a new validator
    function createValidator(IStakingModule.ValidatorData calldata newData) external onlyOperator stakingUnpaused {
        if (address(this).balance < calculateNeededEtherBuffer()) {
            revert MevEthErrors.NotEnoughEth();
        }

        // Determine how big deposit is for the validator
        // *Note this will change if Rocketpool or similar modules are used
        uint256 depositSize = stakingModule.VALIDATOR_DEPOSIT_SIZE();

        // Deposit the Ether into the staking contract
        stakingModule.deposit{ value: depositSize }(newData);
    }

    function grantRewards() external payable {
        if (msg.sender != mevEthShareVault) revert MevEthErrors.InvalidSender();
        assetRebase.elastic += msg.value;
        emit Rewards(msg.sender, msg.value);
    }

    function grantValidatorWithdraw() external payable {
        if (msg.sender != address(stakingModule)) revert MevEthErrors.InvalidSender();
        if (msg.value == 0) {
            revert MevEthErrors.ZeroValue();
        }
        emit ValidatorWithdraw(msg.sender, msg.value);
        if (msg.value == 32 ether) {
            return;
        }
        if (msg.value < 32 ether) {
            // assume slashed value so reduce elastic balance accordingly
            assetRebase.elastic -= (32 ether - msg.value);
        } else {
            // account for any unclaimed rewards
            assetRebase.elastic += (msg.value - 32 ether);
        }
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
        totalManagedAssets = assetRebase.elastic;
    }

    /// @param assets The amount of assets to convert to shares
    /// @return shares The value of the given assets in shares
    function convertToShares(uint256 assets) public view returns (uint256 shares) {
        // So if there are no shares, then they will mint 1:1 with assets
        // Otherwise, shares will mint proportional to the amount of assets
        unchecked {
            shares = assetRebase.elastic == 0 ? assets : (assets * assetRebase.base) / assetRebase.elastic;
        }
    }

    /// @param shares The amount of shares to convert to assets
    /// @return assets The value of the given shares in assets
    function convertToAssets(uint256 shares) public view returns (uint256 assets) {
        // So if there are no shares, then they will mint 1:1 with assets
        // Otherwise, shares will mint proportional to the amount of assets
        unchecked {
            assets = assetRebase.elastic == 0 ? shares : (shares * assetRebase.elastic) / assetRebase.base;
        }
    }

    /// @param receiver The address in question of who would be depositing, doesn't matter in this case
    /// @return maxAssets The maximum amount of assets that can be deposited

    //TODO: should we prefix the receiver arg with _ ?
    function maxDeposit(address receiver) external view returns (uint256 maxAssets) {
        if (stakingPaused) {
            return 0;
        }
        // No practical limit on deposit for Ether
        maxAssets = 2 ** 256 - 1;
    }

    /// @param assets The amount of assets that would be deposited
    /// @return shares The amount of shares that would be minted, *under ideal conditions* only
    function previewDeposit(uint256 assets) external view returns (uint256 shares) {
        return convertToShares(assets);
    }

    /// @param assets The amount of WETH which should be deposited
    /// @param receiver The address user whom should receive the mevEth out
    /// @return shares The amount of shares minted
    function deposit(uint256 assets, address receiver) external payable stakingUnpaused returns (uint256 shares) {
        if (msg.value != 0) {
            if (msg.value != assets && assets != 0) {
                revert MevEthErrors.DepositFailed();
            }
            assets = msg.value;
        } else {
            uint256 balance = address(this).balance;

            ERC20(address(WETH)).safeTransferFrom(msg.sender, address(this), assets);
            WETH.withdraw(assets);

            // Not really neccessary, but protects against malicious WETH implementations
            if (balance + assets != address(this).balance) {
                revert MevEthErrors.DepositFailed();
            }
        }
        if (assetRebase.elastic == 0 || assetRebase.base == 0) {
            shares = assets;
        } else {
            shares = (assets * assetRebase.elastic) / assetRebase.base;
        }

        if (assetRebase.base + shares < 1000) {
            revert MevEthErrors.DepositTooSmall();
        }

        assetRebase.elastic += assets;
        assetRebase.base += shares;

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @param receiver The address in question of who would be minting, doesn't matter in this case
    /// @return maxShares The maximum amount of shares that can be minted
    function maxMint(address receiver) external view returns (uint256 maxShares) {
        if (stakingPaused) {
            return 0;
        }
        // No practical limit on mint for Ether
        return 2 ** 256 - 1;
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
        // Pretty much deposit but in reverse
        if (assetRebase.elastic == 0 || assetRebase.base == 0) {
            assets = shares;
        } else {
            assets = (shares * assetRebase.base) / assetRebase.elastic;
        }

        uint256 balance = address(this).balance;

        if (assetRebase.base + shares < 1000) {
            revert MevEthErrors.DepositTooSmall();
        }

        assetRebase.elastic += assets;
        assetRebase.base += shares;

        if (msg.value > 0) {
            if (msg.value != assets) {
                revert MevEthErrors.DepositFailed();
            }
        } else {
            ERC20(address(WETH)).safeTransferFrom(msg.sender, address(this), assets);
            WETH.withdraw(assets);
        }
        // Not really neccessary, but protects against malicious WETH implementations
        if (balance + assets != address(this).balance) {
            revert MevEthErrors.DepositFailed();
        }

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
            if (!(allowance[owner][msg.sender] >= shares)) {
                revert MevEthErrors.TransferExceedsAllowance();
            }
            allowance[owner][msg.sender] -= shares;
        }

        assetRebase.elastic -= assets;
        assetRebase.base -= shares;

        WETH.deposit{ value: assets }();
        ERC20(address(WETH)).safeTransfer(receiver, assets);

        _burn(owner, shares);

        emit Withdraw(msg.sender, owner, receiver, assets, shares);

        return assets;
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
            if (allowance[owner][msg.sender] < shares) {
                revert MevEthErrors.TransferExceedsAllowance();
            }
            allowance[owner][msg.sender] -= shares;
        }

        assetRebase.elastic -= assets;
        assetRebase.base -= shares;

        WETH.deposit{ value: assets }();
        ERC20(address(WETH)).safeTransfer(receiver, assets);

        _burn(owner, shares);

        emit Withdraw(msg.sender, owner, receiver, assets, shares);

        return assets;
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

    function calculateNeededEtherBuffer() public view returns (uint256) {
        return max((uint256(assetRebase.elastic) * uint256(bufferPercentNumerator)) / 100, 31 ether);
    }

    /// @dev Only Weth withdraw is defined for the behaviour. Deposits should be directed to deposit / mint. Rewards via grantRewards and validator withdraws
    /// via grantValidatorWithdraw.
    receive() external payable {
        if (msg.sender == address(WETH)) {
            return;
        } else {
            revert MevEthErrors.InvalidSender();
        }
    }

    /// @dev Only Weth withdraw is defined for the behaviour. Deposits should be directed to deposit / mint. Rewards via grantRewards and validator withdraws
    /// via grantValidatorWithdraw.
    fallback() external payable {
        if (msg.sender == address(WETH)) {
            return;
        } else {
            revert MevEthErrors.InvalidSender();
        }
    }
}
