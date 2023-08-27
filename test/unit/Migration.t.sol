/// SPDX: License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../MevEthTest.sol";
import { MevEthShareVault } from "src/MevEthShareVault.sol";
import { Empty } from "test/mocks/Empty.sol";
import "src/libraries/Auth.sol";
import "../mocks/DepositContract.sol";
import { IStakingModule } from "../../src/interfaces/IStakingModule.sol";
import "../../src/interfaces/IMevEthShareVault.sol";
import "../../lib/safe-tools/src/SafeTestTools.sol";

contract MevEthMigrationTest is MevEthTest {
  function setUp() override public {
    super.setUp();

    string memory MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
    vm.selectFork(vm.createFork(MAINNET_RPC_URL));
  }

  function testMigrationYieldsCorrectAmount() public {

  }
}
