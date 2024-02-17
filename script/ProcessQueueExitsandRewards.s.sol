// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import { ITinyMevEth } from "src/interfaces/ITinyMevEth.sol";
import { BatchScript } from "forge-safe/BatchScript.sol";

interface IMevEthQueue is ITinyMevEth {
    function processWithdrawalQueue(uint256 newRequestsFinalisedUntil) external;
    function requestsFinalisedUntil() external returns (uint256);
    function queueLength() external returns (uint256);
    function withdrawalQueue(uint256 ticketNumber) external returns (bool claimed, address receiver, uint128 amount, uint128 accumulatedAmount);
    function claim(uint256 ticketNumber) external;
    function addOperator(address) external;
    function operators(address) external returns (bool);
}

/// @notice script to process withdraw queue
contract ProcessQueueExitsandRewardsScript is BatchScript {
    error NothingToProcess();

    function run(uint256 numExits) public {
        address safe = 0x617c8dE5BdE54ffbb8d92716CC947858cA38f582;
        address treasury = 0xe664B134d96fdB0bf7951E0c0557B87Bac5e5277;
        IMevEthQueue mevEth = IMevEthQueue(0x24Ae2dA0f361AA4BE46b48EB19C91e02c5e4f27E);

        uint256 exitsBalance = numExits * 32 ether;
        // assuming rewards balance = remaing multisig balance - 10%
        uint256 rewardsBalance = (safe.balance - exitsBalance) * 90 / 100;

        uint256 payout = exitsBalance + rewardsBalance + address(mevEth).balance;

        if (numExits == 0 && rewardsBalance == 0) {
            revert NothingToProcess();
        }

        // get the withdraw queue offset
        uint256 queueOffset = mevEth.requestsFinalisedUntil();
        // calculate how many tickets can be processed with balance
        uint256 requestLen = queueOffset;
        uint256 queueLen = mevEth.queueLength();
        // uint256 queueLen = 5;
        uint256 amountToProcess;
        uint256 rewardsToProcess;
        (,,, uint128 initAccumulatedAmount) = mevEth.withdrawalQueue(queueOffset);
        for (uint256 i = queueOffset + 1; i < queueLen + 1; i++) {
            (,, uint256 amount, uint128 accumulatedAmount) = mevEth.withdrawalQueue(i);
            if (accumulatedAmount - initAccumulatedAmount > payout) {
                break;
            }
            amountToProcess += amount;
            requestLen = i;
        }
        if (requestLen == queueOffset) {
            revert NothingToProcess();
        }

        if (amountToProcess < exitsBalance) {
            numExits = amountToProcess / 32 ether + 1;
            // rewards to process are zero for queue
        } else {
            // numExits stays the max as original
            rewardsToProcess = amountToProcess - exitsBalance;
            if (address(mevEth).balance >= rewardsToProcess) {
                rewardsToProcess = 0;
            } else {
                rewardsToProcess = rewardsToProcess - address(mevEth).balance;
            }
        }

        // build tx
        bytes memory txn;
        // each exit payment called separately
        for (uint256 i; i < numExits; i++) {
            txn = abi.encodeWithSelector(mevEth.grantValidatorWithdraw.selector);
            addToBatch(address(mevEth), 32 ether, txn);
        }
        // rewards payout for queue
        if (rewardsToProcess > 0) {
            txn = abi.encodeWithSelector(mevEth.grantRewards.selector);
            addToBatch(address(mevEth), rewardsToProcess, txn);
            // transfer admin fee
            addToBatch(treasury, rewardsToProcess / 10, new bytes(0));
        }

        if (!mevEth.operators(safe)) {
            txn = abi.encodeWithSelector(mevEth.addOperator.selector, safe);
            addToBatch(address(mevEth), 0, txn);
        }

        txn = abi.encodeWithSelector(mevEth.processWithdrawalQueue.selector, requestLen);

        addToBatch(address(mevEth), 0, txn);

        for (uint256 i = queueOffset + 1; i < requestLen + 1; i++) {
            txn = abi.encodeWithSelector(mevEth.claim.selector, i);
            addToBatch(address(mevEth), 0, txn);
        }

        vm.startBroadcast();

        executeBatch(safe, false);
        vm.stopBroadcast();
    }
}
