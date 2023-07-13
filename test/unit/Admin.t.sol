/// SPDX: License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import { IStakingModule } from "../../src/interfaces/IStakingModule.sol";
import { IMevEthShareVault } from "../../src/interfaces/IMevEthShareVault.sol";
import "../MevEthTest.sol";
import "../../src/MevEth.sol";
import "src/libraries/Auth.sol";
import "src/mocks/DepositContract.sol";
import "../../src/MevEthShareVault.sol";

contract MevAdminTest is MevEthTest {
    uint256 constant AMOUNT_TO_STAKE = 1 ether;

    /**
     * Tests adding new admin and effects. When an authorized caller invokes this function, it should emit an AdminAdded event
     * and a new admin should be added to the admins mapping.
     */
    function testAddAdmin(address newAdmin) public {
        vm.assume(newAdmin != 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        vm.assume(newAdmin != address(0));
        vm.expectEmit(true, false, false, false, address(mevEth));
        emit AdminAdded(newAdmin);
        vm.prank(SamBacha);
        mevEth.addAdmin(newAdmin);

        assert(mevEth.admins(newAdmin));
    }

    /**
     * Tests failure when new admin and effects. When an unauthorized caller invokes this function, it should revert with Auth.Unauthorized
     * The admins mapping should not contain the newAdmin unless already added prior.
     */
    function testNegativeAddAdmin(address newAdmin) public {
        vm.assume(newAdmin != 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        vm.assume(newAdmin != Operator01);
        vm.assume(newAdmin != address(0));
        vm.expectRevert(Auth.Unauthorized.selector);
        mevEth.addAdmin(newAdmin);
        assertFalse(mevEth.admins(newAdmin));
    }
    /**
     * Tests deleting an admin and effects. When an authorized caller invokes this function, it should emit an AdminDeleted event
     * and the value corresponding with the admin address in the admins mapping should be false.
     */

    function testDeleteAdmin(address newAdmin) public {
        vm.assume(newAdmin != 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        vm.assume(newAdmin != address(0));
        vm.prank(SamBacha);
        mevEth.addAdmin(newAdmin);

        vm.expectEmit(true, false, false, false, address(mevEth));
        emit AdminDeleted(newAdmin);
        vm.prank(SamBacha);
        mevEth.deleteAdmin(newAdmin);

        assertFalse(mevEth.admins(newAdmin));
    }
    /**
     * Tests failure when deleting an admin and effects. When an unauthorized caller invokes this function, revert with an Auth.Unauthorized error.
     * If an admin had previously existed in the admins mapping, value corresponding with the admin address should still be true.
     */

    function testNegativeDeleteAdmin(address newAdmin) public {
        vm.assume(newAdmin != 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        vm.assume(newAdmin != address(0));
        vm.prank(SamBacha);
        mevEth.addAdmin(newAdmin);

        vm.expectRevert(Auth.Unauthorized.selector);
        mevEth.deleteAdmin(newAdmin);

        assert(mevEth.admins(newAdmin));
    }

    /**
     * Tests adding new operator and effects. When an authorized caller invokes this function, it should emit an OperatorAdded event
     * and a new operator should be added to the operators mapping.
     */
    function testAddOperator(address newOperator) public {
        vm.assume(newOperator != 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        vm.assume(newOperator != address(0));
        vm.expectEmit(true, false, false, false, address(mevEth));
        emit OperatorAdded(newOperator);
        vm.prank(SamBacha);
        mevEth.addOperator(newOperator);

        assert(mevEth.operators(newOperator));
    }
    /**
     * Tests failure when new operator and effects. When an unauthorized caller invokes this function, it should revert with Auth.Unauthorized
     * The operators mapping should not contain the operator unless already added prior.
     */

    function testNegativeAddOperator(address newOperator) public {
        vm.assume(newOperator != 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        vm.assume(newOperator != address(0));
        vm.expectRevert(Auth.Unauthorized.selector);
        mevEth.addOperator(newOperator);
        assertFalse(mevEth.operators(newOperator));
    }
    /**
     * Tests deleting an operator and effects. When an authorized caller invokes this function, it should emit an OperatorDeleted event
     * and the value corresponding with the operator address in the operators mapping should be false.
     */

    function testDeleteOperator(address newOperator) public {
        vm.assume(newOperator != 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        vm.assume(newOperator != address(0));
        vm.prank(SamBacha);
        mevEth.addOperator(newOperator);

        vm.expectEmit(true, false, false, false, address(mevEth));
        emit OperatorDeleted(newOperator);
        vm.prank(SamBacha);
        mevEth.deleteOperator(newOperator);

        assertFalse(mevEth.operators(newOperator));
    }
    /**
     * Tests failure when deleting an operator and effects. When an unauthorized caller invokes this function, revert with an Auth.Unauthorized error.
     * If an operator had previously existed in the operators mapping, value corresponding with the operator address should still be true.
     */

    function testNegativeDeleteOperator(address newOperator) public {
        vm.assume(newOperator != 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        vm.assume(newOperator != address(0));
        vm.prank(SamBacha);
        mevEth.addOperator(newOperator);

        vm.expectRevert(Auth.Unauthorized.selector);
        mevEth.deleteOperator(newOperator);

        assert(mevEth.operators(newOperator));
    }
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
        mevEth.mint(AMOUNT_TO_STAKE / 2, address(this));
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
        mevEth.mint(AMOUNT_TO_STAKE / 2, address(this));
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
        mevEth.mint(AMOUNT_TO_STAKE / 2, address(this));
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
        mevEth.mint(AMOUNT_TO_STAKE / 2, address(this));
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
        assertEq(mevEth.pendingStakingModuleCommittedTimestamp(), 1);
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
        address newVault = address(new MevEthShareVault(SamBacha, address(mevEth), FEE_REWARDS_PER_BLOCK));
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
        address newVault = address(new MevEthShareVault(SamBacha, address(mevEth), FEE_REWARDS_PER_BLOCK));
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
        address newVault = address(new MevEthShareVault(SamBacha, address(mevEth), FEE_REWARDS_PER_BLOCK));
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
        address newVault = address(new MevEthShareVault(SamBacha, address(mevEth), FEE_REWARDS_PER_BLOCK));
        address existingVault = address(mevEth.mevEthShareVault());

        // Commit an update to the mev share vault
        uint64 finalizationTimestamp = uint64(block.timestamp + mevEth.MODULE_UPDATE_TIME_DELAY());
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
        assertEq(mevEth.pendingMevEthShareVaultCommittedTimestamp(), 1);
        assertEq(address(mevEth.mevEthShareVault()), existingVault);
    }

    /**
     * Test cancel a pending vault update. When there is a pending staking module and the caller is authorized, the function should emit a cancellation event
     * and set
     * the pending staking module and pending staking module committed timestamp to zero values. The existing staking module should remain unchanged.
     */
    function testCancelUpdateMevEthShareVault() public {
        // Create a new vault and cache the current vault
        address newVault = address(new MevEthShareVault(SamBacha, address(mevEth), FEE_REWARDS_PER_BLOCK));
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
        address newVault = address(new MevEthShareVault(SamBacha, address(mevEth), FEE_REWARDS_PER_BLOCK));
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
     * Test MevEth init function, check for event emission and state changes.
     * When an authorized caller invokes this function, it should emit a MevEthInitialized event, the initialized variable should be set to true,
     * additionally, the staking module should be set to the specified staking module and the mevEthShareVault should be set to the specified mevEthShareVault.
     */
    function testInitMevEth() public {
        // Deploy the mevETH contract
        MevEth mevEth = new MevEth(SamBacha, address(weth), address(0));

        // Create new share vault and staking module
        address initialShareVault = address(new MevEthShareVault(SamBacha, address(mevEth), FEE_REWARDS_PER_BLOCK));
        address initialStakingModule = address(IStakingModule(address(new WagyuStaker(SamBacha, address(depositContract), address(mevEth)))));
        assert(!mevEth.initialized());

        // Initialize the MevEth contract
        vm.expectEmit(true, true, false, false, address(mevEth));
        emit MevEthInitialized(initialShareVault, initialStakingModule);
        vm.prank(SamBacha);
        mevEth.init(initialShareVault, initialStakingModule);

        // Assert the state changes
        assert(mevEth.initialized());
        assertEq(address(mevEth.stakingModule()), address(initialStakingModule));
        assertEq(mevEth.mevEthShareVault(), address(initialShareVault));
    }

    /**
     * Test failure conditions for MevEth init function. Should fail when called by an unauthorized caller. Should fail when share vault or staking module are
     * address(0) and should fail when the contract is already initialized.
     */

    function testNegativeInitMevEth() public {
        // Deploy the mevETH contract
        MevEth mevEth = new MevEth(SamBacha, address(weth), address(0));

        // Create new share vault and staking module
        address initialShareVault = address(new MevEthShareVault(SamBacha, address(mevEth), FEE_REWARDS_PER_BLOCK));
        address initialStakingModule = address(IStakingModule(address(new WagyuStaker(SamBacha, address(depositContract), address(mevEth)))));

        // Expect an unauthorized revert
        vm.expectRevert(Auth.Unauthorized.selector);
        mevEth.init(initialShareVault, initialStakingModule);

        // Expect an address zero revert
        vm.expectRevert(MevEthErrors.ZeroAddress.selector);
        vm.prank(SamBacha);
        mevEth.init(address(0), initialStakingModule);

        vm.expectRevert(MevEthErrors.ZeroAddress.selector);
        vm.prank(SamBacha);
        mevEth.init(initialShareVault, address(0));

        // Assert state changes have not occured
        assert(!mevEth.initialized());
        assertEq(address(mevEth.stakingModule()), address(0));
        assertEq(mevEth.mevEthShareVault(), address(0));

        vm.prank(SamBacha);
        mevEth.init(initialShareVault, initialStakingModule);

        vm.expectRevert(MevEthErrors.AlreadyInitialized.selector);
        vm.prank(SamBacha);
        mevEth.init(initialShareVault, initialStakingModule);
    }

    /**
     * Test share vault recoverToken function, check for event emission and state changes.
     * When an authorized caller invokes this function, it should emit a TokenRecovered event.
     */
    function testRecoverTokenFromMevEthShareVault(uint256 amount) public {
        address newShareVault = address(new MevEthShareVault(SamBacha, address(mevEth), FEE_REWARDS_PER_BLOCK));
        _updateShareVault(newShareVault);

        address mevEthShareVault = mevEth.mevEthShareVault();

        // Allocate weth to the mevEthSharevault
        vm.deal(address(this), amount);
        weth.deposit{ value: amount }();
        weth.transfer(mevEthShareVault, amount);
        assertEq(weth.balanceOf(mevEthShareVault), amount);

        // Recover the token funds
        vm.expectEmit(true, true, true, false, address(mevEthShareVault));
        emit TokenRecovered(SamBacha, address(weth), amount);
        vm.prank(SamBacha);
        IMevEthShareVault(mevEthShareVault).recoverToken(address(weth), SamBacha, amount);

        // Assert that the balance was removed from the share vault and added to the recipient address
        assertEq(weth.balanceOf(mevEthShareVault), 0);
        assertEq(weth.balanceOf(SamBacha), amount);
    }

    /**
     * Test for failure conditions for the share vault recoverToken function, check for and state changes.
     * When an unauthorized caller invokes this function, it should revert with an Auth.Unauthorized error.
     */

    function testNegativeRecoverTokenFromMevEthShareVault(uint256 amount) public {
        address newShareVault = address(new MevEthShareVault(SamBacha, address(mevEth), FEE_REWARDS_PER_BLOCK));
        _updateShareVault(newShareVault);

        address mevEthShareVault = mevEth.mevEthShareVault();

        // Allocate weth to the mevEthSharevault
        vm.deal(address(this), amount);
        weth.deposit{ value: amount }();
        weth.transfer(mevEthShareVault, amount);
        assertEq(weth.balanceOf(mevEthShareVault), amount);

        // Expect a revert due to an unaurhtorized error
        vm.expectRevert(Auth.Unauthorized.selector);
        IMevEthShareVault(mevEthShareVault).recoverToken(address(weth), SamBacha, amount);

        // Assert that the balance is still in the mevEthShareVault and the recipient address is still zero
        assertEq(weth.balanceOf(mevEthShareVault), amount);
        assertEq(weth.balanceOf(SamBacha), 0);
    }

    /**
     * Test staking module recoverToken function, check for event emission and state changes.
     * When an authorized caller invokes this function, it should emit a TokenRecovered event.
     */
    function testRecoverTokenFromStakingModule(uint256 amount) public {
        address stakingModule = address(mevEth.stakingModule());

        // Allocate weth to the mevEthSharevault
        vm.deal(address(this), amount);
        weth.deposit{ value: amount }();
        weth.transfer(stakingModule, amount);
        assertEq(weth.balanceOf(stakingModule), amount);

        // Recover the token funds
        vm.expectEmit(true, true, true, false, address(stakingModule));
        emit TokenRecovered(SamBacha, address(weth), amount);
        vm.prank(SamBacha);
        IStakingModule(stakingModule).recoverToken(address(weth), SamBacha, amount);

        // Assert that the balance was removed from the share vault and added to the recipient address
        assertEq(weth.balanceOf(stakingModule), 0);
        assertEq(weth.balanceOf(SamBacha), amount);
    }

    /**
     * Test for failure conditions for the staking module recoverToken function, check for state changes.
     * When an unauthorized caller invokes this function, it should revert with an Auth.Unauthorized error.
     */

    function testNegativeRecoverTokenFromStakingModule(uint256 amount) public {
        address stakingModule = address(mevEth.stakingModule());

        // Allocate weth to the mevEthSharevault
        vm.deal(address(this), amount);
        weth.deposit{ value: amount }();
        weth.transfer(stakingModule, amount);
        assertEq(weth.balanceOf(stakingModule), amount);

        // Expect a revert due to an unaurhtorized error
        vm.expectRevert(Auth.Unauthorized.selector);
        IStakingModule(stakingModule).recoverToken(address(weth), SamBacha, amount);

        // Assert that the balance is still in the mevEthShareVault and the recipient address is still zero
        assertEq(weth.balanceOf(stakingModule), amount);
        assertEq(weth.balanceOf(SamBacha), 0);
    }

    /**
     * Tests updating to MevEthShareVault.
     * Should update the share vault, transfer an amount to simulate rewards and successfully call mevEth.payRewards.
     */
    function testUpdateToMevEthShareVault(uint128 amount) public {
        vm.assume(amount > 10_000);

        // Update the staking module to the WagyuStaker and create a new validator
        address newShareVault = address(new MevEthShareVault(SamBacha, address(mevEth), FEE_REWARDS_PER_BLOCK));
        _updateShareVault(newShareVault);

        vm.deal(address(this), amount);
        payable(newShareVault).transfer(amount);

        vm.expectEmit();
        emit Rewards(newShareVault, amount);
        IMevEthShareVault(newShareVault).payRewards(amount);

        uint256 elastic = mevEth.totalAssets();
        uint256 base = mevEth.totalSupply();

        assertGt(elastic, base);
    }
}
