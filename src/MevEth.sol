// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

/*///////////// Manifold Mev Ether /////////////                                        
                                        -|-_
                                        | _

                                        <|/\
                                        | |,

                                        |-|-o
                                        |<|.

                        _,..._,m,      |,
                    ,/'      '"";     | |,
                    /             ".
                ,'mmmMMMMmm.      \  -|-_"
                _/-"^^^^^"""%#%mm,   ;  | _ o
        ,m,_,'              "###)  ;,
        (###%                 \#/  ;##mm.
        ^#/  __        ___    ;  (######)
            ;  //.\\     //.\\   ;   \####/
        _; (#\"//     \\"/#)  ;  ,/
        @##\ \##/   =   `"=" ,;mm/
        `\##>.____,...,____,<####@
                                ""'
/////////////////////////////////////////////*/

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {Auth} from "./libraries/Auth.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {MevEthIndex} from "./MevEthIndex.sol";
import {MevEthErrors} from "./libraries/Errors.sol";
import { IStakingModule } from "./interfaces/IStakingModule.sol";
import {console} from "forge-std/console.sol";

/// @title MevEth
/// @author Manifold Finance
/// @dev Contract that allows deposit of ETH, for a Liquid Staking Reciept (LSR) in return.
/// @dev LSR is represented through an ERC4626 token and interface
contract MevEth is MevEthIndex, Auth, ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    struct AssetsRebase {
        uint256 elastic; // Represents total amount of staked ether, including rewards accrued / slashed
        uint256 base; // Represents claims to ownership of the staked ether
    }

    AssetsRebase public assetRebase;

    constructor(address _authority, address initialStakingContract, address _WETH) Auth(_authority) ERC20("MevEth", "METH", 18) {
        stakingModule = IStakingModule(initialStakingContract);
        WETH = IWETH(_WETH);
    }

    /*//////////////////////////////////////////////////////////////
                            Configuration Variables
    //////////////////////////////////////////////////////////////*/
    bool public stakingPaused;

    struct ValidatorsInfo {
        // current number of beacon validators
        uint128 beaconValidators;
        // total validators, includes pending + beacon validators
        uint128 totalValidators;
    }

    IStakingModule public stakingModule;

    // Amount of Ether held current;y as a fraction of 32 eth awaiting a new validator
    uint256 public totalBufferedEther;

    // WETH
    IWETH public immutable WETH;

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function calculateNeededEtherBuffer() public view returns (uint256) {
        return min((assetRebase.elastic * 2) / 100, 31 ether);
    }

    /*//////////////////////////////////////////////////////////////
                            Registry For Validators
    //////////////////////////////////////////////////////////////*/
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

    function createValidator(IStakingModule.ValidatorData calldata newData) public onlyOperator {
        if (stakingPaused) {
            revert MevEthErrors.StakingPaused();
        }

        if (address(this).balance < calculateNeededEtherBuffer()) {
            revert MevEthErrors.NotEnoughEth();
        }

        // Determine how big deposit is for the validator
        // *Note this will change if Rocketpool or similar modules are used
        uint256 depositSize = stakingModule.validatorDepositSize();

        // Deposit the Ether into the staking contract
        stakingModule.deposit{value: depositSize}(newData);
    }


    /*//////////////////////////////////////////////////////////////
                            RecieveSupport
    //////////////////////////////////////////////////////////////*/
    receive() external payable {
        // Should allow rewards to be send here, and validator withdrawls
        if (msg.sender == address(WETH)) {
            return;
        }
        if (msg.sender == block.coinbase) {
            assetRebase.elastic += msg.value;
        } else {
            revert MevEthErrors.InvalidSender();
        }
    }


    /*//////////////////////////////////////////////////////////////
                            ERC4626 Support
    //////////////////////////////////////////////////////////////*/
    function asset() external view returns (address assetTokenAddress) {
        assetTokenAddress = address(WETH);
    }

    function totalAssets() external view returns (uint256 totalManagedAssets) {
        // Should return the total amount of Ether managed by the contract
        totalManagedAssets = assetRebase.elastic;
    }

    function convertToShares(uint256 assets) public view returns (uint256 shares) {
        // So if there are no shares, then they will mint 1:1 with assets
        // Otherwise, shares will mint proportional to the amount of assets
        shares = assetRebase.elastic == 0 ? assets : assets * assetRebase.base / assetRebase.elastic;
    }

    function convertToAssets(uint256 shares) public view returns (uint256 assets) {
        // So if there are no shares, then they will mint 1:1 with assets
        // Otherwise, shares will mint proportional to the amount of assets
        assets = assetRebase.elastic == 0 ? shares : shares * assetRebase.elastic / assetRebase.base;
    }

    function maxDeposit(address) external view returns (uint256 maxAssets) {
        // No practical limit on deposit for Ether
        maxAssets = 2 ** 256 - 1;
    }

    function previewDeposit(uint256 assets) external view returns (uint256 shares) {
        return convertToShares(assets);
    }

    function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
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

    function maxMint(address) external view returns (uint256 maxShares) {
        // No practical limit on mint for Ether
        return 2 ** 256 - 1;
    }

    function previewMint(uint256 shares) external view returns (uint256 assets) {
        return convertToAssets(shares);
    }

    function mint(uint256 shares, address receiver) external returns (uint256 assets) {
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

    function maxWithdraw(address owner) public view returns (uint256 maxAssets) {
        // Withdrawal is either their maximum balance, or the internal buffer
        maxAssets = min(address(this).balance, convertToAssets(balanceOf[owner]));
    }

    function previewWithdraw(uint256 assets) external view returns (uint256 shares) {
        return convertToShares(assets);
    }

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

        WETH.deposit{value: assets}();
        WETH.transfer(receiver, assets);

        emit Withdraw(msg.sender, owner, receiver, assets, shares);

        return assets;
    }

    function maxRedeem(address owner) external view returns (uint256 maxShares) {
        maxShares = min(convertToShares(address(this).balance), balanceOf[owner]);
    }

    function previewRedeem(uint256 shares) external view returns (uint256 assets) {
        return convertToAssets(shares);
    }

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets) {
        assets = convertToAssets(shares);

        if (owner != msg.sender) {
            require(allowance[owner][msg.sender] >= shares, "ERC20: transfer amount exceeds allowance");
            allowance[owner][msg.sender] -= shares;
        }

        _burn(owner, shares);

        assetRebase.elastic -= assets;
        assetRebase.base -= shares;

        WETH.deposit{value: assets}();
        WETH.transfer(receiver, assets);

        emit Withdraw(msg.sender, owner, receiver, assets, shares);

        return assets;
    }
}
