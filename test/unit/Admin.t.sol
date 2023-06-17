/// SPDX: License-Identifier: GPL-3.0-only
pragma solidity 0.8.20;

import "../MevEthTest.sol";
import "src/libraries/Auth.sol";
import "../mocks/DepositContract.sol";
import { IStakingModule } from "../../src/interfaces/IStakingModule.sol";
import "../../src/MevEthShareVault.sol";

contract MevAdminTest is MevEthTest {
    uint256 constant AMOUNT_TO_STAKE = 1 ether;
    uint256 constant ONE = 1;

    /**
     * Test pausing the staking functionality in the contract as an admin. Should only succeed when called by an account
     * with the onlyAdmin role. After calling this function, staking should not be possible.
     *
     * Should emit a StakingPaused event when invoked.
     */
    function testPauseStaking() public {
        vm.prank(SamBacha);
        vm.expectEmit(false, false, false, false, address(mevEth));
        emit StakingPaused();

        //Pause staking and assert that the stakingPaused variable is true
        mevEth.pauseStaking();
        assert(mevEth.stakingPaused());

        //Deposit Eth to get weth to stake
        vm.deal(address(this), AMOUNT_TO_STAKE);
        weth.deposit{ value: AMOUNT_TO_STAKE }();

        weth.approve(address(mevEth), AMOUNT_TO_STAKE);
        //When stakingPaused is true, staking should fail
        vm.expectRevert(MevEthErrors.StakingPaused.selector);
        mevEth.deposit(AMOUNT_TO_STAKE / 2, address(this));

        vm.expectRevert(MevEthErrors.StakingPaused.selector);
        mevEth.mint(ONE, address(this));
    }

    /**
     * Test pausing the staking functionality in the contract without admin role.
     * After calling this function without admin privledges, staking should continue
     */
    function testNegativePauseStaking() public {
        vm.expectRevert(Auth.Unauthorized.selector);
        mevEth.pauseStaking();
        assert(!mevEth.stakingPaused());

        //When stakingPaused is false, staking should succeed
        vm.deal(address(this), AMOUNT_TO_STAKE);
        weth.deposit{ value: AMOUNT_TO_STAKE }();

        weth.approve(address(mevEth), AMOUNT_TO_STAKE);
        mevEth.deposit(AMOUNT_TO_STAKE / 2, address(this));
        mevEth.mint(ONE, address(this));
    }

    /**
     * Test unpausing the staking functionality in the contract as an admin. Should only succeed when called by an account
     * with the onlyAdmin role. After calling this function, staking should be possible.
     *
     * Should emit a StakingUnpaused event when invoked.
     */
    function testUnpauseStaking() public {
        vm.prank(SamBacha);
        vm.expectEmit(false, false, false, false, address(mevEth));
        emit StakingUnpaused();

        //Unpause staking and assert that the stakingPaused variable is false
        mevEth.unpauseStaking();
        assert(!mevEth.stakingPaused());

        //Staking should succeed
        vm.deal(address(this), AMOUNT_TO_STAKE);
        weth.deposit{ value: AMOUNT_TO_STAKE }();

        weth.approve(address(mevEth), AMOUNT_TO_STAKE);
        mevEth.deposit(AMOUNT_TO_STAKE / 2, address(this));
        mevEth.mint(ONE, address(this));
    }

    /**
     * Test unpausing the staking functionality in the contract without admin role.
     * After calling this function without admin privledges, staking should still be paused
     */

    function testNegativeUnpauseStaking() public {
        // First pause staking with auth role
        vm.prank(SamBacha);
        mevEth.pauseStaking();

        vm.expectRevert(Auth.Unauthorized.selector);
        mevEth.unpauseStaking();
        assert(mevEth.stakingPaused());

        // Deposit Eth to get weth to stake
        vm.deal(address(this), AMOUNT_TO_STAKE);
        weth.deposit{ value: AMOUNT_TO_STAKE }();

        // When stakingPaused is true, staking should fail
        vm.expectRevert(MevEthErrors.StakingPaused.selector);
        mevEth.deposit(AMOUNT_TO_STAKE, address(this));

        vm.expectRevert(MevEthErrors.StakingPaused.selector);
        mevEth.mint(ONE, address(this));
    }

    /**
     * Test commit an updated staking module. When called by an authorized account, the function should emit a StakingModuleUpdateCommitted event with the
     * existing
     * staking module address, the new module address and the timestamp at which the new module can be finalized.
     * The pending staking module should be updated to the new module, the pending staking module commited timestamp should be the timestamp at which the
     * function was called. The current staking module should remain as the existing staking module before the function call.
     */

    function testCommitUpdateStakingModule() public {
        // Create a new staking module and cache the current staking module
        DepositContract newModule = new DepositContract();
        address existingStakingModule = address(mevEth.stakingModule());

        // Commit an update to the staking module and check the effects
        vm.expectEmit(true, true, true, false, address(mevEth));
        uint64 finalizationTimestamp = uint64(block.timestamp + mevEth.MODULE_UPDATE_TIME_DELAY());
        emit StakingModuleUpdateCommitted(existingStakingModule, address(newModule), finalizationTimestamp);

        vm.prank(SamBacha);
        mevEth.commitUpdateStakingModule(IStakingModule(address(newModule)));

        assertEq(address(mevEth.pendingStakingModule()), address(newModule));
        assertEq(mevEth.pendingStakingModuleCommittedTimestamp(), block.timestamp);
        assertEq(address(mevEth.stakingModule()), existingStakingModule);
    }

    /**
     * Test commit a new staking module when unauthorized. This should revert with an Auth.Unauthorized error and no effects should occur.
     */

    function testNegativeCommitUpdateStakingModule() public {
        // Create a new staking module and cache the current staking module
        DepositContract newModule = new DepositContract();
        address existingStakingModule = address(mevEth.stakingModule());

        // Expect a reversion if unauthorized and check that no effects have occured
        vm.expectRevert(Auth.Unauthorized.selector);
        mevEth.commitUpdateStakingModule(IStakingModule(address(newModule)));

        assertEq(address(mevEth.pendingStakingModule()), address(0));
        assertEq(address(mevEth.stakingModule()), existingStakingModule);
    }

    /**
     * Test finalize a pending staking module. When called by an authorized account, and after the staking module update time delay has elapsed
     * the function should emit a StakingModuleUpdateFinalized event with the previous staking module and the new staking module.
     * The pending staking module should be updated to the zero address, the pending staking module committed timestamp should be updated to 0
     * and the staking module should be updated to the value that was the pending staking module.
     */

    function testFinalizeUpdateStakingModule() public {
        // Create a new staking module and cache the current staking module
        DepositContract newModule = new DepositContract();
        address existingStakingModule = address(mevEth.stakingModule());

        // Commit an update to the staking module
        uint64 finalizationTimestamp = uint64(block.timestamp + mevEth.MODULE_UPDATE_TIME_DELAY());

        vm.prank(SamBacha);
        mevEth.commitUpdateStakingModule(IStakingModule(address(newModule)));

        // Finalize the staking module update and check effects
        vm.warp(finalizationTimestamp);
        vm.expectEmit(true, true, false, false, address(mevEth));
        emit StakingModuleUpdateFinalized(existingStakingModule, address(newModule));

        vm.prank(SamBacha);
        mevEth.finalizeUpdateStakingModule();

        assertEq(address(mevEth.pendingStakingModule()), address(0));
        assertEq(mevEth.pendingStakingModuleCommittedTimestamp(), 0);

        assertEq(address(mevEth.stakingModule()), address(newModule));
    }

    /**
     * Test finalize a pending staking module. When the caller is authorized and there is no pending staking module, the function should revert with an invalid
     * pending module error.
     * When the caller is authorized, but the time delay has not elapsed, the function should return a premature finalization error.
     * When the time delay has elapsed and there is a pending staking module, but the caller is unauthorized, the function should revert with an unauthorized
     * error.
     */

    function testNegativeFinalizeCommitUpdateStakingModule() public {
        // Expect a revert when there is no pending staking module
        vm.expectRevert(MevEthErrors.InvalidPendingStakingModule.selector);
        vm.prank(SamBacha);
        mevEth.finalizeUpdateStakingModule();

        // Commit a new staking module
        DepositContract newModule = new DepositContract();
        address existingStakingModule = address(mevEth.stakingModule());
        uint64 finalizationTimestamp = uint64(block.timestamp + mevEth.MODULE_UPDATE_TIME_DELAY());
        uint64 committedTimestamp = uint64(block.timestamp);
        vm.prank(SamBacha);
        mevEth.commitUpdateStakingModule(IStakingModule(address(newModule)));

        vm.expectRevert(MevEthErrors.PrematureStakingModuleUpdateFinalization.selector);
        vm.prank(SamBacha);
        mevEth.finalizeUpdateStakingModule();

        // Warp to the finalization timestamp, expect a reversion when unauthorized
        vm.warp(finalizationTimestamp);
        vm.expectRevert(Auth.Unauthorized.selector);
        mevEth.finalizeUpdateStakingModule();

        // Check that there are no effects from finalization
        assertEq(address(mevEth.pendingStakingModule()), address(newModule));
        assertEq(mevEth.pendingStakingModuleCommittedTimestamp(), committedTimestamp);
        assertEq(address(mevEth.stakingModule()), existingStakingModule);
    }

    /**
     * Test cancel a pending staking module. When there is a pending staking module and the caller is authorized, the function should emit a cancellation event
     * and set
     * the pending staking module and pending staking module committed timestamp to zero values. The existing staking module should remain unchanged.
     */

    function testCancelUpdateStakingModule() public {
        // Commit a new staking module
        DepositContract newModule = new DepositContract();
        address existingStakingModule = address(mevEth.stakingModule());
        vm.prank(SamBacha);
        mevEth.commitUpdateStakingModule(IStakingModule(address(newModule)));

        // Cancel the update and check the effects
        vm.prank(SamBacha);
        vm.expectEmit(true, true, false, false, address(mevEth));
        emit StakingModuleUpdateCanceled(existingStakingModule, address(newModule));

        mevEth.cancelUpdateStakingModule();

        assertEq(address(mevEth.pendingStakingModule()), address(0));
        assertEq(mevEth.pendingStakingModuleCommittedTimestamp(), 0);
        assertEq(address(mevEth.stakingModule()), existingStakingModule);
    }

    /**
     * Test cancel a pending staking module with failure conditions. When there is no pending staking module, an invalid pending staking module error
     * shouldoccur.
     * If there is a valid pending staking module, the cancellation function should revert when an called by an unauthorized account. The pending staking
     * module,
     * pending staking module committed timestamp and existing staking module should be unchanged.
     */

    function testNegativeCancelCommitUpdateStakingModule() public {
        // Expect a revert when there is no pending staking module
        vm.expectRevert(MevEthErrors.InvalidPendingStakingModule.selector);
        vm.prank(SamBacha);
        mevEth.cancelUpdateStakingModule();

        // Commit a new staking module
        DepositContract newModule = new DepositContract();
        address existingStakingModule = address(mevEth.stakingModule());
        vm.prank(SamBacha);
        mevEth.commitUpdateStakingModule(IStakingModule(address(newModule)));

        // Expect a reversion if unauthorized
        vm.expectRevert(Auth.Unauthorized.selector);
        mevEth.cancelUpdateStakingModule();

        // Check that there are no effects
        assertEq(address(mevEth.pendingStakingModule()), address(newModule));
        assertEq(mevEth.pendingStakingModuleCommittedTimestamp(), block.timestamp);
        assertEq(address(mevEth.stakingModule()), existingStakingModule);
    }

    /**
     * Test commit an updated mevEthShareVault. When called by an authorized account, the function should emit a MevEthShareVaultUpdateCommitted event with the
     * existing vault address, the new vault address and the timestamp at which the new vault can be finalized.
     * The pending vault should be updated to the newly specified vault, the pending vault commited timestamp should be the timestamp at which the
     * function was called. The current vault should remain as the existing staking module before the function call.
     */

    function testCommitUpdateMevEthShareVault() public {
        // Create a new vault and cache the current vault
        address newVault = address(new MevEthShareVault(address(mevEth), FEE_REWARDS_PER_BLOCK));
        address existingVault = address(mevEth.mevEthShareVault());

        // Commit an update to the staking module and check the effects
        vm.expectEmit(true, true, true, false, address(mevEth));
        uint64 finalizationTimestamp = uint64(block.timestamp + mevEth.MODULE_UPDATE_TIME_DELAY());
        emit MevEthShareVaultUpdateCommitted(existingVault, newVault, finalizationTimestamp);

        vm.prank(SamBacha);
        mevEth.commitUpdateMevEthShareVault(newVault);

        assertEq(address(mevEth.pendingMevEthShareVault()), newVault);
        assertEq(mevEth.pendingMevEthShareVaultCommittedTimestamp(), block.timestamp);
        assertEq(address(mevEth.mevEthShareVault()), existingVault);
    }

    /**
     * Test commit a new vault update when unauthorized. This should revert with an Auth.Unauthorized error and no effects should occur.
     */

    function testNegativeCommitUpdateMevEthShareVault() public {
        // Create a new vault and cache the current vault
        address newVault = address(new MevEthShareVault(address(mevEth), FEE_REWARDS_PER_BLOCK));
        address existingVault = address(mevEth.mevEthShareVault());

        // Expect a reversion if unauthorized and check that no effects have occured
        vm.expectRevert(Auth.Unauthorized.selector);
        mevEth.commitUpdateMevEthShareVault(newVault);

        assertEq(address(mevEth.pendingMevEthShareVault()), address(0));
        assertEq(address(mevEth.mevEthShareVault()), existingVault);
    }

    /**
     * Test finalize a pending vault update. When called by an authorized account, and after the module update time delay has elapsed
     * the function should emit a MevEthShareVaultUpdateFinalized event with the previous vault and the new vault.
     * The pending vault should be updated to the zero address, the pending vault committed timestamp should be updated to 0.
     * The current vault should be updated to the value that was the pending vault.
     */

    function testFinalizeUpdateMevEthShareVault() public {
        // Create a new vault and cache the current vault
        address newVault = address(new MevEthShareVault(address(mevEth), FEE_REWARDS_PER_BLOCK));
        address existingVault = address(mevEth.mevEthShareVault());

        // Commit an update to the mev share vault
        uint64 finalizationTimestamp = uint64(block.timestamp + mevEth.MODULE_UPDATE_TIME_DELAY());

        vm.prank(SamBacha);
        mevEth.commitUpdateMevEthShareVault(newVault);

        // Finalize the staking module update and check effects
        vm.warp(finalizationTimestamp);
        vm.expectEmit(true, true, false, false, address(mevEth));
        emit MevEthShareVaultUpdateFinalized(existingVault, newVault);

        vm.prank(SamBacha);
        mevEth.finalizeUpdateMevEthShareVault();

        assertEq(address(mevEth.pendingMevEthShareVault()), address(0));
        assertEq(mevEth.pendingMevEthShareVaultCommittedTimestamp(), 0);
        assertEq(address(mevEth.mevEthShareVault()), newVault);
    }

    /**
     * Test finalize a vault update. When the caller is authorized and there is no pending staking module, the function should revert with an invalid
     * pending vault error.
     * When the caller is authorized, but the time delay has not elapsed, the function should return a premature finalization error.
     * When the time delay has elapsed and there is a pending vault, but the caller is unauthorized, the function should revert with an unauthorized
     * error.
     */

    function testNegativeFinalizeCommitUpdateMevEthShareVault() public {
        // Expect a revert when there is no pending mev share vault
        vm.expectRevert(MevEthErrors.InvalidPendingMevEthShareVault.selector);
        vm.prank(SamBacha);
        mevEth.finalizeUpdateMevEthShareVault();

        // Create a new vault and cache the current vault
        address newVault = address(new MevEthShareVault(address(mevEth), FEE_REWARDS_PER_BLOCK));
        address existingVault = address(mevEth.mevEthShareVault());

        // Commit an update to the mev share vault
        uint64 finalizationTimestamp = uint64(block.timestamp + mevEth.MODULE_UPDATE_TIME_DELAY());
        uint256 committedTimestamp = block.timestamp;
        vm.prank(SamBacha);
        mevEth.commitUpdateMevEthShareVault(newVault);

        // Expect a reversion if the time delay has not elapsed
        vm.expectRevert(MevEthErrors.PrematureMevEthShareVaultUpdateFinalization.selector);
        vm.prank(SamBacha);
        mevEth.finalizeUpdateMevEthShareVault();

        // Warp to the finalization timestamp, expect a reversion when unauthorized
        vm.warp(finalizationTimestamp);
        vm.expectRevert(Auth.Unauthorized.selector);
        mevEth.finalizeUpdateMevEthShareVault();

        // Check that there are no effects from finalization
        assertEq(address(mevEth.pendingMevEthShareVault()), newVault);
        assertEq(mevEth.pendingMevEthShareVaultCommittedTimestamp(), committedTimestamp);
        assertEq(address(mevEth.mevEthShareVault()), existingVault);
    }

    /**
     * Test cancel a pending vault update. When there is a pending staking module and the caller is authorized, the function should emit a cancellation event
     * and set
     * the pending staking module and pending staking module committed timestamp to zero values. The existing staking module should remain unchanged.
     */
    function testCancelUpdateMevEthShareVault() public {
        // Create a new vault and cache the current vault
        address newVault = address(new MevEthShareVault(address(mevEth), FEE_REWARDS_PER_BLOCK));
        address existingVault = address(mevEth.mevEthShareVault());

        // Commit an update to the mev share vault
        vm.prank(SamBacha);
        mevEth.commitUpdateMevEthShareVault(newVault);

        // Cancel the update and check the effects
        vm.prank(SamBacha);
        vm.expectEmit(true, true, false, false, address(mevEth));
        emit MevEthShareVaultUpdateCanceled(existingVault, newVault);

        mevEth.cancelUpdateMevEthShareVault();

        assertEq(address(mevEth.pendingMevEthShareVault()), address(0));
        assertEq(mevEth.pendingMevEthShareVaultCommittedTimestamp(), 0);
        assertEq(address(mevEth.mevEthShareVault()), existingVault);
    }

    /**
     * Test cancel a pending vault update with failure conditions. When there is no pending vault, an invalid pending vault error should occur.
     * If there is a valid pending vault, the cancellation function should revert when an called by an unauthorized account. The pending vault,     pending
     * vault module committed timestamp and existing vault should be unchanged.
     */

    function testNegativeCancelCommitUpdateMevEthShareVault() public {
        // Expect a revert when there is no pending vault
        vm.expectRevert(MevEthErrors.InvalidPendingMevEthShareVault.selector);
        vm.prank(SamBacha);
        mevEth.cancelUpdateMevEthShareVault();

        // Create a new vault and cache the current vault
        address newVault = address(new MevEthShareVault(address(mevEth), FEE_REWARDS_PER_BLOCK));
        address existingVault = address(mevEth.mevEthShareVault());
        vm.prank(SamBacha);
        uint256 committedTimestamp = block.timestamp;
        mevEth.commitUpdateMevEthShareVault(newVault);

        // Expect a reversion if unauthorized
        vm.expectRevert(Auth.Unauthorized.selector);
        mevEth.cancelUpdateMevEthShareVault();

        // Check that there are no effects from finalization
        assertEq(address(mevEth.pendingMevEthShareVault()), newVault);
        assertEq(mevEth.pendingMevEthShareVaultCommittedTimestamp(), committedTimestamp);
        assertEq(address(mevEth.mevEthShareVault()), existingVault);
    }

    /**
     */

    function testCreateValidator() public {
        uint256 stakingModuleDepositSize = mevEth.stakingModule().VALIDATOR_DEPOSIT_SIZE();
        uint256 balanceBefore = mevEth.balance();

        IStakingModule.ValidatorData memory validatorData = IStakingModule.ValidatorData({
            operator: address(this),
            pubkey: bytes("pubkey"),
            withdrawal_credentials: bytes32(0),
            signature: bytes("signature"),
            deposit_data_root: bytes32(0)
        });

        vm.prank(SamBacha);
        mevEth.createValidator(validatorData);

        uint256 balanceAfter = mevEth.balance();

        assertEq(stakingModuleDepositSize, balanceBefore - balanceAfter);
    }

    /**
     */

    function testNegativeCreateValidator() public {
        uint256 balanceBefore = mevEth.balance();

        IStakingModule.ValidatorData memory validatorData = IStakingModule.ValidatorData({
            operator: address(this),
            pubkey: bytes("pubkey"),
            withdrawal_credentials: bytes32(0),
            signature: bytes("signature"),
            deposit_data_root: bytes32(0)
        });

        vm.expectRevert(Auth.Unauthorized.selector);
        mevEth.createValidator(validatorData);

        vm.expectRevert(MevEthErrors.NotEnoughEth.selector);
        mevEth.createValidator(validatorData);

        uint256 balanceAfter = mevEth.balance();

        assertEq(balanceBefore, balanceAfter);
    }
}
