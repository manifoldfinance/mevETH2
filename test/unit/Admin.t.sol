/// SPDX: License-Identifier: GPL-3.0-only
pragma solidity 0.8.20;

import "../MevEthTest.sol";
import "src/libraries/Auth.sol";

contract MevAdminTest is MevEthTest {

    uint256 constant AMOUNT_TO_STAKE = 1 ether;
    uint256 constant ONE = 1;    

    /**  Test pausing the staking functionality in the contract as an admin. Should only succeed when called by an account
    with the onlyAdmin role. After calling this function, staking should not be possible.
    
    Should emit a StakingPaused event when invoked.
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
        weth.deposit{value: AMOUNT_TO_STAKE}();

        //When stakingPaused is true, staking should fail
        vm.expectRevert();
        mevEth.deposit(AMOUNT_TO_STAKE, address(this));

        vm.expectRevert();
        mevEth.mint(ONE, address(this));

    }

    /**  Test pausing the staking functionality in the contract without admin role.
    After calling this function without admin privledges, staking should continue
    */   
     function testNegativePauseStaking() public {
        vm.expectRevert(Auth.Unauthorized.selector);
        mevEth.pauseStaking();
        assert(!mevEth.stakingPaused());  

        //When stakingPaused is false, staking should succeed

        //TODO: these are arbitrary values that should succeed, we can update these values to something specific if needed
        vm.deal(address(this), AMOUNT_TO_STAKE);
        weth.deposit{value: AMOUNT_TO_STAKE}();
        mevEth.deposit(AMOUNT_TO_STAKE / 2, address(this));
        mevEth.mint(ONE, address(this));


    }


    /**  Test unpausing the staking functionality in the contract as an admin. Should only succeed when called by an account
    with the onlyAdmin role. After calling this function, staking should be possible.
    
    Should emit a StakingUnpaused event when invoked.
    */   
    function test_UnpauseStaking() public {
        vm.prank(SamBacha);
        vm.expectEmit(false, false, false, false, address(mevEth));       
        emit StakingUnpaused();

        //Unpause staking and assert that the stakingPaused variable is false
        mevEth.unpauseStaking();
        assert(!mevEth.stakingPaused());  


        //Staking should succeed
        //TODO: these are arbitrary values that should succeed, we can update these values to something specific if needed
        vm.deal(address(this), AMOUNT_TO_STAKE);
        weth.deposit{value: AMOUNT_TO_STAKE}();
        mevEth.deposit(AMOUNT_TO_STAKE / 2, address(this));
        mevEth.mint(ONE, address(this));
    }


    /**  Test unpausing the staking functionality in the contract without admin role.
    After calling this function without admin privledges, staking should still be paused
    */   

    function testNegativeUnpauseStaking() public {
        vm.expectRevert(Auth.Unauthorized.selector);
        mevEth.unpauseStaking();
        assert(mevEth.stakingPaused());  

        //Deposit Eth to get weth to stake
        vm.deal(address(this), AMOUNT_TO_STAKE);
        weth.deposit{value: AMOUNT_TO_STAKE}();

        //When stakingPaused is true, staking should fail
        vm.expectRevert();
        mevEth.deposit(AMOUNT_TO_STAKE, address(this));

        vm.expectRevert();
        mevEth.mint(ONE, address(this));
    }

}