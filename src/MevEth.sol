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
import { console } from "forge-std/console.sol";

/// @title MevEth
/// @author Manifold Finance
/// @dev Contract that allows deposit of ETH, for a Liquid Staking Reciept (LSR) in return.
/// @dev LSR is represented through an ERC4626 token and interface
contract MevEth is Auth, ERC20, IERC4626 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    // Central Rebase struct used for share accounting + math
    struct AssetsRebase {
        uint256 elastic; // Represents total amount of staked ether, including rewards accrued / slashed
        uint256 base; // Represents claims to ownership of the staked ether
    }

    AssetsRebase public assetRebase;


    /// @param _authority The address of the controlling admin authority
    /// @param initialStakingContract The address of the staking module to be used at first by mevEth
    /// @param _WETH The address of the WETH contract to use for deposits

    //TODO: add a @dev note mentioning that the pending staking module and the pending staking module committed timestamp will both be zero on deployment
    constructor(address _authority, address initialStakingContract, address _WETH) Auth(_authority) ERC20("MevEth", "METH", 18) {
        stakingModule = IStakingModule(initialStakingContract);
        WETH = IWETH(_WETH);
    }

    receive() external payable {
        // Should allow rewards to be send here, and validator withdrawls
        if (msg.sender == address(WETH)) {
            return;
        } else {
            revert MevEthErrors.InvalidSender();
        }
    }

    
    /*//////////////////////////////////////////////////////////////
                            Configuration Variables
    //////////////////////////////////////////////////////////////*/
    bool public stakingPaused;


    IStakingModule public stakingModule;
    IStakingModule public pendingStakingModule;
    uint64 public pendingStakingModuleCommittedTimestamp;

    uint64 public constant STAKING_MODULE_UPDATE_TIME_DELAY = 7 days;

    // WETH Implementation used by MevEth
    IWETH public immutable WETH;

    function calculateNeededEtherBuffer() public view returns (uint256) {
        return max((assetRebase.elastic * 2) / 100, 31 ether);
    }

    /*//////////////////////////////////////////////////////////////
                            Admin Control Panel
    //////////////////////////////////////////////////////////////*/

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


    /**
     //TODO:
     */
    function commitUpdateStakingModule(IStakingModule newModule) external onlyAdmin {
        address oldModule = address(stakingModule);
        pendingStakingModule = newModule;
        pendingStakingModuleCommittedTimestamp = uint64(block.timestamp);
        emit StakingModuleUpdateCommitted(oldModule, address(newModule), uint64(block.timestamp + STAKING_MODULE_UPDATE_TIME_DELAY));
    }

     /**
     //TODO:

     */
    function finalizeUpdateStakingModule() external onlyAdmin {
        if (pendingStakingModule == IStakingModule(address(0)) || pendingStakingModuleCommittedTimestamp == 0){
            revert MevEthErrors.InvalidPendingStakingModule();   
        } 
        
        if (uint64(block.timestamp) < pendingStakingModuleCommittedTimestamp + STAKING_MODULE_UPDATE_TIME_DELAY){
            revert  MevEthErrors.PrematureStakingModuleUpdateFinalization(pendingStakingModuleCommittedTimestamp + STAKING_MODULE_UPDATE_TIME_DELAY, uint64(block.timestamp));
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
         //TODO:

     */
    function cancelUpdateStakingModule() external onlyAdmin {

        if (pendingStakingModule == IStakingModule(address(0)) || pendingStakingModuleCommittedTimestamp == 0){
            revert MevEthErrors.InvalidPendingStakingModule();   
        } 

        address oldModule = address(stakingModule);
        address pendingModule = address(pendingStakingModule);

        //Set the pending staking module variables to zero
        pendingStakingModule = IStakingModule(address(0));
        pendingStakingModuleCommittedTimestamp = 0;

        emit StakingModuleUpdateCanceled(oldModule, address(pendingModule));
    }


    event StakingModuleUpdateCommitted(address indexed oldModule, address indexed pendingModule, uint64 indexed eligibleForFinalization);
    event StakingModuleUpdateFinalized(address indexed oldModule, address indexed newModule);
    event StakingModuleUpdateCanceled(address indexed oldModule, address indexed pendingModule);



    /*//////////////////////////////////////////////////////////////
                            Registry For Validators
    //////////////////////////////////////////////////////////////*/

    /// @notice This function passes through the needed Ether to the Staking module, and the assosiated credentials with it
    /// @param newData The data needed to create a new validator
    function createValidator(IStakingModule.ValidatorData calldata newData) public onlyOperator stakingUnpaused {
        if (address(this).balance < calculateNeededEtherBuffer()) {
            revert MevEthErrors.NotEnoughEth();
        }

        // Determine how big deposit is for the validator
        // *Note this will change if Rocketpool or similar modules are used
        uint256 depositSize = stakingModule.validatorDepositSize();

        // Deposit the Ether into the staking contract
        stakingModule.deposit{ value: depositSize }(newData);
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
        shares = assetRebase.elastic == 0 ? assets : assets * assetRebase.base / assetRebase.elastic;
    }

    /// @param shares The amount of shares to convert to assets
    /// @return assets The value of the given shares in assets
    function convertToAssets(uint256 shares) public view returns (uint256 assets) {
        // So if there are no shares, then they will mint 1:1 with assets
        // Otherwise, shares will mint proportional to the amount of assets
        assets = assetRebase.elastic == 0 ? shares : shares * assetRebase.elastic / assetRebase.base;
    }

    /// @param reciever The address in question of who would be depositing, doesn't matter in this case
    /// @return maxAssets The maximum amount of assets that can be deposited

    //TODO: should we prefix the reciever arg with _ ?
    function maxDeposit(address reciever) external view returns (uint256 maxAssets) {
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
    /// @param receiver The address user whom should recieve the mevEth out
    /// @return shares The amount of shares minted
    function deposit(uint256 assets, address receiver) external stakingUnpaused returns (uint256 shares) {
        WETH.transferFrom(msg.sender, address(this), assets);
        uint256 balance = address(this).balance;
        WETH.withdraw(assets);
        // Not really neccessary, but protects against malicious WETH implementations
        if (balance + assets != address(this).balance) {
            revert MevEthErrors.DepositFailed();
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

    /// @param reciever The address in question of who would be minting, doesn't matter in this case
    /// @return maxShares The maximum amount of shares that can be minted
    function maxMint(address reciever) external view returns (uint256 maxShares) {
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
    /// @param receiver The address user whom should recieve the mevEth out
    /// @return assets The amount of assets deposited
    function mint(uint256 shares, address receiver) external stakingUnpaused returns (uint256 assets) {
        // Pretty much deposit but in reverse
        if (assetRebase.elastic == 0 || assetRebase.base == 0) {
            assets = shares;
        } else {
            assets = (shares * assetRebase.base) / assetRebase.elastic;
        }

        WETH.transferFrom(msg.sender, address(this), assets);
        uint256 balance = address(this).balance;
        WETH.withdraw(assets);
        // Not really neccessary, but protects against malicious WETH implementations
        if (balance + assets != address(this).balance) {
            revert MevEthErrors.DepositFailed();
        }

        if (assetRebase.base + shares < 1000) {
            revert MevEthErrors.DepositTooSmall();
        }

        assetRebase.elastic += assets;
        assetRebase.base += shares;

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
        return convertToShares(assets);
    }

    /// @param assets The amount of assets that should be withdrawn
    /// @param receiver The address user whom should recieve the mevEth out
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

        _burn(owner, shares);

        assetRebase.elastic -= assets;
        assetRebase.base -= shares;

        WETH.deposit{ value: assets }();
        WETH.transfer(receiver, assets);

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
        return convertToAssets(shares);
    }

    /// @param shares The amount of shares that should be burned
    /// @param receiver The address user whom should recieve the wETH out
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

        _burn(owner, shares);

        assetRebase.elastic -= assets;
        assetRebase.base -= shares;

        WETH.deposit{ value: assets }();
        WETH.transfer(receiver, assets);

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
}
