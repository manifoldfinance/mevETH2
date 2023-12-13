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
contract ProcessQueueRewardsScript is BatchScript {
    error NothingToProcess();

    function run() public {
        address safe = 0x617c8dE5BdE54ffbb8d92716CC947858cA38f582;
        IMevEthQueue mevEth = IMevEthQueue(0x24Ae2dA0f361AA4BE46b48EB19C91e02c5e4f27E);

        // assuming rewards balance = multisig balance - 10%
        uint256 rewardsBalance = safe.balance * 90 / 100;
        // get the withdraw queue offset
        uint256 queueOffset = mevEth.requestsFinalisedUntil();
        // calculate how many tickets can be processed with balance
        uint256 requestLen = queueOffset;
        uint256 queueLen = mevEth.queueLength();
        uint256 amountToProcess;
        (,,, uint128 initAccumulatedAmount) = mevEth.withdrawalQueue(queueOffset);
        for (uint256 i = queueOffset + 1; i < queueLen; i++) {
            (,, uint256 amount, uint128 accumulatedAmount) = mevEth.withdrawalQueue(i);
            if (accumulatedAmount - initAccumulatedAmount > rewardsBalance) {
                break;
            }
            amountToProcess += amount;
            requestLen = i;
        }
        if (requestLen == queueOffset) {
            revert NothingToProcess();
        }

        bytes memory txn = abi.encodeWithSelector(mevEth.grantRewards.selector);

        addToBatch(address(mevEth), amountToProcess, txn);

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
