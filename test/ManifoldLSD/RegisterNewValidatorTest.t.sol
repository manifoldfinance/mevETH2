pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../../src/ManifoldLSD.sol";
import "../../src/MevETH.sol";
import "../../src/OperatorRegistry.sol";
import {IOperatorRegistry} from "../../src/interfaces/IOperatorRegistry.sol";

contract MockDepositContract {
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable {}
}

contract RegisterNewValidatorTest is Test {
    bytes32 internal nextUser = keccak256(abi.encodePacked("user address"));

    ManifoldLSD internal lsd;
    MevETH internal mevEth;
    MockDepositContract internal deposit;
    OperatorRegistry internal operatorRegistry;

    function getNextUserAddress() external returns (address payable) {
        address payable user = payable(address(uint160(uint256(nextUser))));
        nextUser = keccak256(abi.encodePacked(nextUser));
        return user;
    }

    address payable internal owner;
    address payable internal staker;
    address payable internal operator;

    function setUp() public {
        owner = this.getNextUserAddress();
        vm.deal(owner, 1 ether);

        staker = this.getNextUserAddress();
        vm.deal(staker, 32 ether);

        operator = this.getNextUserAddress();

        vm.prank(owner);
        deposit = new MockDepositContract();
        lsd = new ManifoldLSD("Manifold LSD", "MFLSD", 18, address(deposit));
        mevEth = new MevETH(
            "Mev Eth",
            "MevETH",
            18,
            address(lsd),
            address(0x0)
        );

        operatorRegistry = new OperatorRegistry(address(lsd));

        lsd.setMevETH(address(mevEth));
        vm.prank(staker);

        lsd.deposit{value: 32 ether}(address(staker));
        lsd.setOperatorRegistry(address(operatorRegistry));

        operatorRegistry.commitOperator(operator);
        operatorRegistry.setMaxValidators(operator, 2);
    }

    function test_GetWithdrawalCredentials() public {
        assertEq(
            lsd.withdrawalCredentials(), bytes32(abi.encodePacked(bytes12(0x010000000000000000000000), address(lsd)))
        );
    }

    function test_RegisterNewValidator() public {
        lsd.registerNewValidator(
            IOperatorRegistry.ValidatorData(operator, "pk", lsd.withdrawalCredentials(), "sign", 0)
        );
    }
}
