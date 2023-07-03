// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/console.sol";
import "../MevEthTest.sol";
import "src/interfaces/Errors.sol";
import "src/interfaces/ICommonOFT.sol";

contract LayerZeroTest is MevEthTest {
    string constant name = "Mev Liquid Staked Ether";
    string constant symbol = "mevETH";

    OFTV2 public polyMevEth;
    OFTV2 public arbMevEth;
    LZEndpointMock polygonEndpoint;
    LZEndpointMock arbitrumEndpoint;

    function setUp() public override {
        //  setup mocks
        depositContract = new DepositContract();
        weth = new WETH9();
        layerZeroEndpoint = new LZEndpointMock(ETH_ID);
        // deploy mevEth (mainnet)
        mevEth = new MevEth(SamBacha, address(weth), address(layerZeroEndpoint));

        // simulate deploy OFT on arbitrum
        arbitrumEndpoint = new LZEndpointMock(ARBITRUM_ID);
        arbMevEth = new OFTV2(name, symbol, 18, 8, SamBacha, address(arbitrumEndpoint));

        // set trusted remotes
        vm.prank(SamBacha);
        arbMevEth.setTrustedRemote(ETH_ID, abi.encodePacked(address(mevEth), address(arbMevEth)));
        // internal bookkeeping for endpoints (not part of a real deploy, just for this test)
        arbitrumEndpoint.setDestLzEndpoint(address(mevEth), address(layerZeroEndpoint));

        vm.prank(SamBacha);
        mevEth.setTrustedRemote(ARBITRUM_ID, abi.encodePacked(address(arbMevEth), address(mevEth)));
        // internal bookkeeping for endpoints (not part of a real deploy, just for this test)
        layerZeroEndpoint.setDestLzEndpoint(address(arbMevEth), address(arbitrumEndpoint));
    }

    /// @notice test send mevEth token cross chain through mock lz endpoint
    function testSendFrom() public {
        uint256 amount = 1 ether;
        vm.deal(User01, amount * 2);
        vm.deal(User02, amount * 2);
        vm.startPrank(User01);

        // Deposit 1 ETH into the mevETH contract
        mevEth.deposit{ value: amount }(amount, User01);

        // Check that the mevETH contract has 1 ETH
        assertEq(address(mevEth).balance, amount);

        // Check the user has 1 mevETH
        assertEq(mevEth.balanceOf(User01), amount);

        // setup call params
        ICommonOFT.LzCallParams memory callParams;
        callParams.refundAddress = payable(User01);
        callParams.zroPaymentAddress = address(0);
        callParams.adapterParams = "";
        // call estimate send fee
        (uint256 nativeFee,) = mevEth.estimateSendFee(ARBITRUM_ID, _addressToBytes32(User02), amount, false, "");
        // send tokens from mainnet to simulated arbitrum
        mevEth.sendFrom{ value: nativeFee }(User01, ARBITRUM_ID, _addressToBytes32(User02), amount, callParams);

        assertEq(arbMevEth.totalSupply(), amount);
        assertEq(arbMevEth.balanceOf(User02), amount);

        vm.stopPrank();
        vm.startPrank(User02);
        // send funds back
        // setup call params
        callParams.refundAddress = payable(User02);
        callParams.zroPaymentAddress = address(0);
        callParams.adapterParams = "";
        // call estimate send fee
        (nativeFee,) = arbMevEth.estimateSendFee(ETH_ID, _addressToBytes32(User01), amount, false, "");
        // send tokens back to mainnet from simulated arbitrum
        arbMevEth.sendFrom{ value: nativeFee }(User02, ETH_ID, _addressToBytes32(User01), amount, callParams);

        assertEq(mevEth.totalSupply(), amount);
        assertEq(mevEth.balanceOf(User01), amount);
    }

    function _addressToBytes32(address _address) internal pure virtual returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }
}
