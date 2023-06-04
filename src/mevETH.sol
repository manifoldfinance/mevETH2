// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

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
import {OperatorRegistry} from "./OperatorRegistry.sol";
import {Auth} from "./libraries/Auth.sol";
import {MevEthIndex} from "./MevEthIndex.sol";

/// Interface for the Beacon Chain Deposit Contract
interface IBeaconDepositContract {
    /// @notice Submit a Phase 0 DepositData object.
    /// @param pubkey A BLS12-381 public key.
    /// @param withdrawal_credentials Commitment to a public key for withdrawals.
    /// @param signature A BLS12-381 signature.
    /// @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.

    /// Used as a protection against malformed input.
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;
}

/// @title MevEth
/// @author Manifold Finance, Chef Copypasta
/// @dev Contract that allows deposit of ETH, for a Liquid Staking Reciept (LSR) in return.
/// @dev LSR is represented through an ERC4626 token and interface
contract MevEth is OperatorRegistry, MevEthIndex, Auth {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    struct AssetsRebase {
        uint256 elastic; // Represents total amount of staked ether, including rewards accrued / slashed
        uint256 base; // Represents claims to ownership of the staked ether
    }

    AssetsRebase public total_assets;

    constructor(address _authority, address depositContract) Auth(_authority) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        IBeaconDepositContract _BEACON_CHAIN_DEPOSIT_CONTRACT;
        if (chainId == 1) {
            _BEACON_CHAIN_DEPOSIT_CONTRACT = IBeaconDepositContract(0x00000000219ab540356cBB839Cbe05303d7705Fa);
        } else {
            _BEACON_CHAIN_DEPOSIT_CONTRACT = IBeaconDepositContract(depositContract);
        }

        BEACON_CHAIN_DEPOSIT_CONTRACT = _BEACON_CHAIN_DEPOSIT_CONTRACT;
    }

    /*//////////////////////////////////////////////////////////////
                            Configuration Variables
    //////////////////////////////////////////////////////////////*/

    /// The address of the Beacon Chain Deposit Contract
    IBeaconDepositContract immutable BEACON_CHAIN_DEPOSIT_CONTRACT;

    /// The amount of Ether required to mint a validator on the Beacon Chain
    uint256 constant VALIDATOR_DEPOSIT_SIZE = 32 ether;

    bool public stakingPaused;

    struct ValidatorsInfo {
        // current number of beacon validators
        uint128 beaconValidators;
        // total validators, includes pending + beacon validators
        uint128 totalValidators;
    }

    ValidatorsInfo public validatorsInfo;

    // max amount of validators we can register at once
    uint256 public maxValidatorRegistration;

    bytes32 public withdrawalCredentials;

    // Amount of Ether held current;y as a fraction of 32 eth awaiting a new validator
    uint256 public totalBufferedEther;

    // Balance of mev-eth contract on the Beacon Chain
    uint256 public totalBeaconBalance;

    // Reciever of Beacon Chain Validator Rewards
    address public rewardsReceiver;

    // Management fee
    uint256 public managementFee;

    // WETH
    IERC20 public WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /*//////////////////////////////////////////////////////////////
                            Registry For Validators
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice This function pauses staking for the contract.
     * @dev Only the owner of the contract can call this function.
     */
    function pauseStaking() external authorized {
        stakingPaused = true;

        emit StakingPaused();
    }

    /**
     * @notice This function unpauses staking
     * @dev This function is only callable by the owner and sets the stakingPaused variable to false. It also emits the StakingUnpaused event.
     */
    function unpauseStaking() external authorized {
        stakingPaused = false;

        emit StakingUnpaused();
    }

    // Helper function for registering new validators
    function createValidator(ValidatorData calldata validatorData) internal {
        if (validatorData.withdrawal_credentials != withdrawalCredentials) {
            revert InvalidWithdrawalCredentials();
        }

        validatorsInfo.totalValidators++;

        BEACON_CHAIN_DEPOSIT_CONTRACT.deposit{value: VALIDATOR_DEPOSIT_SIZE}(
            validatorData.pubkey,
            abi.encodePacked(validatorData.withdrawal_credentials),
            validatorData.signature,
            validatorData.deposit_data_root
        );

        registerValidator(validatorData);

        emit NewValidator(
            validatorData.operator,
            validatorData.pubkey,
            validatorData.withdrawal_credentials,
            validatorData.signature,
            validatorData.deposit_data_root
        );
    }

    // take 32 buffered eth and allocate 1 new validator
    function registerNewValidator(ValidatorData calldata validatorData) external {
        if (totalBufferedEther < VALIDATOR_DEPOSIT_SIZE) {
            revert InsufficientBufferedEth();
        }

        totalBufferedEther -= VALIDATOR_DEPOSIT_SIZE;

        uint256 targetBalance = address(this).balance - VALIDATOR_DEPOSIT_SIZE;

        if (address(this).balance != targetBalance) {
            revert BeaconDepositFailed();
        }

        emit NewValidator(
            validatorData.operator,
            validatorData.pubkey,
            validatorData.withdrawal_credentials,
            validatorData.signature,
            validatorData.deposit_data_root
        );
    }

    // allocate 32 ETH * X to X new validators
    // todo: can abstract this functionality in an internal function so above function uses same logic
    function registerNewValidators(ValidatorData[] calldata validatorData) external onlyKeeper {
        if (validatorData.length > maxValidatorRegistration) {
            revert TooManyValidatorRegistrations();
        }
        if (totalBufferedEther < uint256(validatorData.length * VALIDATOR_DEPOSIT_SIZE)) {
            revert InsufficientBufferedEth();
        }

        totalBufferedEther -= validatorData.length * VALIDATOR_DEPOSIT_SIZE;
        validatorsInfo.totalValidators += uint128(validatorData.length);

        uint256 targetBalance = address(this).balance - validatorData.length * VALIDATOR_DEPOSIT_SIZE;

        for (uint256 i = 0; i < validatorData.length; ++i) {
            if (validatorData[i].withdrawal_credentials != withdrawalCredentials) revert InvalidWithdrawalCredentials();

            BEACON_CHAIN_DEPOSIT_CONTRACT.deposit{value: VALIDATOR_DEPOSIT_SIZE}(
                validatorData[i].pubkey,
                abi.encodePacked(validatorData[i].withdrawal_credentials),
                validatorData[i].signature,
                validatorData[i].deposit_data_root
            );

            registerValidator(validatorData[i]);

            emit NewValidator(
                validatorData[i].operator,
                validatorData[i].pubkey,
                validatorData[i].withdrawal_credentials,
                validatorData[i].signature,
                validatorData[i].deposit_data_root
            );
        }

        if (address(this).balance != targetBalance) {
            revert BeaconDepositFailed();
        }
    }

    // called by manifold to update the beacon balance + number of validators successfully validating
    function oracleUpdate(uint256 beaconBalance, uint128 beaconValidators) external onlyKeeper {
        uint256 oldBeaconBalance = totalBeaconBalance;
        uint256 oldBeaconValidators = validatorsInfo.beaconValidators;
        uint256 totalValidators = validatorsInfo.totalValidators;

        // reported validators must be strictly <= to totalValidators
        if (beaconValidators > totalValidators) {
            revert ReportedBeaconValidatorsGreaterThanTotalValidators();
        }

        uint256 appearedValidators = beaconValidators - oldBeaconValidators;

        // RewardBase is the amount of money that is not included in the reward calculation
        // Just appeared validators * 32 added to the previously reported beacon balance
        uint256 rewardBase = (appearedValidators * VALIDATOR_DEPOSIT_SIZE) + oldBeaconBalance;

        validatorsInfo.beaconValidators = beaconValidators;
        totalBeaconBalance = beaconBalance;

        // skim fee
        if (beaconBalance > rewardBase) {
            uint256 balanceDifference = beaconBalance - rewardBase;

            uint256 feesAccrued = balanceDifference.mulDivDown(managementFee, 1e18);

            //_deposit(feesAccrued, rewardsReceiver);

            emit RewardsMinted(rewardsReceiver, feesAccrued);
        }

        emit OracleUpdate(oldBeaconBalance, oldBeaconValidators, beaconBalance, beaconValidators);
    }

    /*//////////////////////////////////////////////////////////////
                            RecieveSupport
    //////////////////////////////////////////////////////////////*/
    receive() external payable {
        // Should allow rewards to be send here, and validator withdrawls
    }

    /*//////////////////////////////////////////////////////////////
                            ERC4626 Support
    //////////////////////////////////////////////////////////////*/
    function asset() external view returns (address assetTokenAddress) {
        assetTokenAddress = address(WETH);
    }

    function totalAssets() external view returns (uint256 totalManagedAssets) {
        // Should return the total amount of Ether managed by the contract
        //
        totalManagedAssets = total_assets.elastic;
    }

    function convertToShares(uint256 assets) public view returns (uint256 shares) {
        // So if there are no shares, then they will mint 1:1 with assets
        // Otherwise, shares will mint proportional to the amount of assets
        shares = total_assets.elastic == 0 ? assets : assets * total_assets.base / total_assets.elastic;
    }

    function convertToAssets(uint256 shares) public view returns (uint256 assets) {
        // So if there are no shares, then they will mint 1:1 with assets
        // Otherwise, shares will mint proportional to the amount of assets
        assets = total_assets.elastic == 0 ? shares : shares * total_assets.elastic / total_assets.base;
    }

    function maxDeposit(address receiver) external view returns (uint256 maxAssets) {
        // No practical limit on deposit for Ether
        return 2 ** 256 - 1;
    }

    function previewDeposit(uint256 assets) external view returns (uint256 shares) {}

    function deposit(uint256 assets, address receiver) external returns (uint256 shares) {}

    function maxMint(address receiver) external view returns (uint256 maxShares) {}

    function previewMint(uint256 shares) external view returns (uint256 assets) {}

    function mint(uint256 shares, address receiver) external returns (uint256 assets) {}

    function maxWithdraw(address owner) external view returns (uint256 maxAssets) {}

    function previewWithdraw(uint256 assets) external view returns (uint256 shares) {}

    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares) {}

    function maxRedeem(address owner) external view returns (uint256 maxShares) {}

    function previewRedeem(uint256 shares) external view returns (uint256 assets) {}
}
