// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {IERC4626} from "./interfaces/IERC4626.sol";
import {ERC20} from "solmate/token/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {TwoStepOwnable} from "./auth/TwoStepOwnable.sol";

import {IMevETH} from "./interfaces/IMevETH.sol";
import {IBeaconDepositContract} from "./interfaces/IBeaconDepositContract.sol";
import {IOperatorRegistry} from "./interfaces/IOperatorRegistry.sol";

// todo: init pool with shares minted to 0 address to prevent donation attacks

// todo: have an auth registry that has all the roles

// todo: update recieve() to add to buffered eth

/// @title ManifoldLSD
/// @author Manifold Finance
/// @dev Manager that takes care of minting proper shares of mevETH and staking
contract ManifoldLSD is IERC4626, TwoStepOwnable {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    error InsufficientBufferedEth();
    error TooManyValidatorRegistrations();
    error ExceedsStakingAllowance();
    error StakingIsPaused();
    error DepositTooLow();
    error ZeroShares();
    error ReportedBeaconValidatorsGreaterThanTotalValidators();
    error ReportedBeaconValidatorsDecreased();
    error BeaconDepositFailed();
    error InvalidWithdrawalCredentials();

    modifier stakingNotPaused() {
        if (stakingPaused) revert StakingIsPaused();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );

    event OracleUpdate(uint256 indexed prevBalance, uint256 prevValidators, uint256 newBalance, uint256 newValidators);

    event NewValidator(
        address indexed operator,
        bytes pubkey,
        bytes32 withdrawalCredentials,
        bytes signature,
        bytes32 deposit_data_root
    );

    event RewardsMinted(address indexed rewardsReceiver, uint256 feesAccrued);
    event StakingPaused();
    event StakingUnpaused();
    event FeeSet(uint256 indexed newFee);
    event FeeReceiverSet(address indexed newFeeReciever);
    event MevEthSet(address indexed mevEthAddress);
    event OperatorRegistrySet(address indexed operatorRegistry);


    /*//////////////////////////////////////////////////////////////
                            STORAGE VARIABLES
    //////////////////////////////////////////////////////////////*/

    struct ValidatorsInfo {
        // current number of beacon validators
        uint128 beaconValidators;
        // total validators, includes pending + beacon validators
        uint128 totalValidators;
    }

    // total staked ether on beacon
    uint256 public totalBeaconBalance;

    // current staked ether in this contract (deposits)
    uint256 public totalBufferedEther;

    // LSD fee
    uint256 public managementFee;

    // rewards from fees will be sent to an external address/contract
    address public rewardsReceiver;

    // erc20 address
    address public mevETH;

    // validator withdrawal credentials.
    bytes32 public withdrawalCredentials;

    // beacon deposit contract
    IBeaconDepositContract public immutable BEACON_DEPOSIT_CONTRACT;

    // operator registry
    IOperatorRegistry public operatorRegistry;

    // used to calculate transient ETH and rewards
    ValidatorsInfo public validatorsInfo;

    // used for pausing staking and setting max limits
    bool public stakingPaused;

    // max amount of validators we can register at once
    uint256 public maxValidatorRegistration;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    uint256 public constant MIN_DEPOSIT = 1 ether;
    uint256 public constant VALIDATOR_DEPOSIT_SIZE = 32 ether;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _beaconDepositAddress)
        ERC20(_name, _symbol, _decimals)
    {
        _initializeOwner(msg.sender);
        BEACON_DEPOSIT_CONTRACT = IBeaconDepositContract(_beaconDepositAddress);
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    // called by manifold to update the beacon balance + number of validators successfully validating
    function oracleUpdate(uint256 beaconBalance, uint128 beaconValidators) external onlyOwner {
        uint256 oldBeaconBalance = totalBeaconBalance;
        uint256 oldBeaconValidators = validatorsInfo.beaconValidators;
        uint256 totalValidators = validatorsInfo.totalValidators;

        // reported validators must be strictly <= to totalValidatosr
        if (beaconValidators > totalValidators) {
            revert ReportedBeaconValidatorsGreaterThanTotalValidators();
        }

        // validators must be strictly increasing before withdrawals come live
        if (beaconValidators < oldBeaconValidators) {
            revert ReportedBeaconValidatorsDecreased();
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

            _deposit(feesAccrued, rewardsReceiver);

            emit RewardsMinted(rewardsReceiver, feesAccrued);
        }

        emit OracleUpdate(oldBeaconBalance, oldBeaconValidators, beaconBalance, beaconValidators);
    }

    // amount of ETH that has been staked to a validator but has yet to be accruing rewards
    function transientEth() public view returns (uint256) {
        return (validatorsInfo.totalValidators - validatorsInfo.beaconValidators) * VALIDATOR_DEPOSIT_SIZE;
    }

    // take 32 buffered eth and allocate 1 new validator
    function registerNewValidator(IOperatorRegistry.ValidatorData calldata validatorData) external onlyOwner {
        if (totalBufferedEther < VALIDATOR_DEPOSIT_SIZE) {
            revert InsufficientBufferedEth();
        }

        if (validatorData.withdrawal_credentials != withdrawalCredentials) {
            revert InvalidWithdrawalCredentials();
        }

        validatorsInfo.totalValidators++;
        totalBufferedEther -= VALIDATOR_DEPOSIT_SIZE;

        uint256 targetBalance = address(this).balance - VALIDATOR_DEPOSIT_SIZE;

        BEACON_DEPOSIT_CONTRACT.deposit{value: VALIDATOR_DEPOSIT_SIZE}(
            validatorData.pubkey,
            abi.encodePacked(validatorData.withdrawal_credentials),
            validatorData.signature,
            validatorData.deposit_data_root
        );

        operatorRegistry.registerValidator(validatorData);

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
    function registerNewValidators(IOperatorRegistry.ValidatorData[] calldata validatorData) external onlyOwner {
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

            BEACON_DEPOSIT_CONTRACT.deposit{value: VALIDATOR_DEPOSIT_SIZE}(
                validatorData[i].pubkey,
                abi.encodePacked(validatorData[i].withdrawal_credentials),
                validatorData[i].signature,
                validatorData[i].deposit_data_root
            );

            operatorRegistry.registerValidator(validatorData[i]);
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

    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/

    function setMevETH(address _mevETH) external onlyOwner {
        mevETH = _mevETH;

        emit MevEthSet(_mevETH);
    }

    /**
     * @notice Sets the maximum number of validator registrations allowed
     * @dev This function should only be called by the owner of the contract
     * @param max The maximum number of validator registrations allowed
     */
    function setMaxValidatorRegistration(uint256 max) external onlyOwner {
        maxValidatorRegistration = max;
    }

    /**
     * @notice This function pauses staking for the contract.
     * @dev Only the owner of the contract can call this function.
     */
    function pauseStaking() external onlyOwner {
        stakingPaused = true;

        emit StakingPaused();
    }

    /**
     * @notice This function unpauses staking
     * @dev This function is only callable by the owner and sets the stakingPaused variable to false. It also emits the StakingUnpaused event.
     */
    function unpauseStaking() external onlyOwner {
        stakingPaused = false;

        emit StakingUnpaused();
    }

    /**
     * @notice Sets the management fee for the contract.
     * @dev This function sets the management fee for the contract. It can only be called by the contract owner.
     * @param fee The fee to be set.
     */
    function setFee(uint64 fee) external onlyOwner {
        managementFee = fee;

        emit FeeSet(fee);
    }

    /**
     * @notice Sets the rewards receiver address.
     * @dev This function sets the rewards receiver address. It can only be called by the owner.
     * @param receiver The address of the rewards receiver.
     */
    function setRewardsReceiver(address receiver) external onlyOwner {
        rewardsReceiver = receiver;

        emit FeeReceiverSet(receiver);
    }

    function setOperatorRegistry(address _operatorRegistry) external onlyOwner {
        operatorRegistry = IOperatorRegistry(_operatorRegistry);

        emit OperatorRegistrySet(_operatorRegistry);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC4626 LOGIC
    //////////////////////////////////////////////////////////////*/


    /**
     * @notice This function allows users to deposit funds to the contract.
     * @dev The function requires a minimum deposit amount and will revert if the deposit is too low.
     */
    function deposit(address receiver) public payable stakingNotPaused returns (uint256) {
        if (msg.value < MIN_DEPOSIT) revert DepositTooLow();

        return _deposit(msg.value, receiver);
    }

    function _deposit(uint256 value, address receiver) internal returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        if ((shares = previewDeposit(value)) == 0) revert ZeroShares();

        totalBufferedEther += value;

        IMevETH(mevETH).mint(receiver, shares);

        emit Deposit(msg.sender, receiver, value, shares);
    }


    /**
     * @notice This function returns the total assets of the contract.
     * @dev The total assets are calculated by adding the total beacon balance, total buffered ether, and transient ether.
     */
    function totalAssets() public view virtual returns (uint256) {
        return totalBeaconBalance + totalBufferedEther + transientEth();
    }

    /**
     * @notice convertToShares() function is used to convert a given amount of assets to the corresponding amount of shares.
     * @dev The function takes in a uint256 representing the amount of assets and returns a uint256 representing the amount of shares. The totalSupply and totalAssets() are used to calculate the conversion rate.
     */
    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    /**
     * @notice This function allows users to preview the amount of shares they will receive when they deposit a certain amount of assets.
     * @dev This function takes in an amount of assets and returns the amount of shares that will be received when the deposit is made.
     */
    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    /**
     * @notice This function is used to preview the amount of tokens that will be minted when the mint function is called.
     * @dev The function takes in the amount of shares that will be minted and returns the amount of tokens that will be minted. It does this by calculating the total supply of tokens and the total assets and then multiplying the two together.
     */
    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    /**
     * @notice This function allows users to preview the amount of tokens they will receive when withdrawing assets.
     * @dev This function takes in the amount of assets to be withdrawn and returns the amount of tokens that will be received. It first checks if the total supply is 0, and if it is, it returns the amount of assets that were passed in. Otherwise, it calculates the amount of tokens to be received by multiplying the amount of assets by the total supply and dividing it by the total assets.
     */
    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    /**
     * @notice This function allows a user to preview the amount of assets they will receive when redeeming a certain amount of shares.
     * @dev This function takes in a uint256 representing the amount of shares to be redeemed and returns a uint256 representing the amount of assets that will be received.
     */
    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @notice This function returns the maximum value of a uint256 type.
     * @dev This function takes in an address as an argument and returns the maximum value of a uint256 type.
     */
    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @notice This function allows the owner to withdraw the maximum amount of assets from their account.
     * @dev The function converts the balance of the owner to assets and returns the amount.
     */
    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    /**
     * @notice This function allows the owner to redeem the maximum amount of tokens from their balance.
     * @dev This function returns the balance of the owner.
     */
    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}

    receive() external payable {
        totalBufferedEther += msg.value;
    }

    // ======== withdraw logic TBD ==========

    // function withdraw(
    //     uint256 assets,
    //     address receiver,
    //     address owner
    // ) public virtual returns (uint256 shares) {
    //     shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

    //     if (msg.sender != owner) {
    //         uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

    //         if (allowed != type(uint256).max)
    //             allowance[owner][msg.sender] = allowed - shares;
    //     }

    //     beforeWithdraw(assets, shares);

    //     _burn(owner, shares);

    //     emit Withdraw(msg.sender, receiver, owner, assets, shares);

    //     asset.safeTransfer(receiver, assets);
    // }

    // function redeem(
    //     uint256 shares,
    //     address receiver,
    //     address owner
    // ) public virtual returns (uint256 assets) {
    //     if (msg.sender != owner) {
    //         uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

    //         if (allowed != type(uint256).max)
    //             allowance[owner][msg.sender] = allowed - shares;
    //     }

    //     // Check for rounding error since we round down in previewRedeem.
    //     require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

    //     beforeWithdraw(assets, shares);

    //     _burn(owner, shares);

    //     emit Withdraw(msg.sender, receiver, owner, assets, shares);

    //     asset.safeTransfer(receiver, assets);
    // }
}
