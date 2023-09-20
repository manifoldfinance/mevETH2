// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/console.sol";
import "../MevEthTest.sol";
import "src/interfaces/Errors.sol";
import "src/interfaces/ICommonOFT.sol";

contract LayerZeroDisabledTest is MevEthTest {
    string constant name = "Mev Liquid Staked Ether";
    string constant symbol = "mevETH";

    error DestinationChainNotTrusted();

    OFTWithFee public polyMevEth;
    OFTWithFee public arbMevEth;
    LZEndpointMock polygonEndpoint;
    LZEndpointMock arbitrumEndpoint;

    function setUp() public override {
        //  setup mocks
        depositContract = new DepositContract();
        weth = new WETH9();
        layerZeroEndpoint = new LZEndpointMock(ETH_ID);
        // deploy mevEth (mainnet)
        mevEth = new MevEth(SamBacha, address(weth), address(layerZeroEndpoint));
    }

    /// @notice test send mevEth token cross chain through mock lz endpoint
    function testSendFromFail() public {
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

        vm.expectRevert(DestinationChainNotTrusted.selector);
        mevEth.sendFrom{ value: nativeFee }(User01, ARBITRUM_ID, _addressToBytes32(User02), amount, amount, callParams);

        vm.stopPrank();
    }

    function testQuoteFee() public {
        // default fee 0%
        assertEq(mevEth.quoteOFTFee(ETH_ID, 10_000), 0);

        vm.prank(SamBacha);
        // change default fee to 10%
        mevEth.setDefaultFeeBp(1000);
        assertEq(mevEth.quoteOFTFee(ETH_ID, 10_000), 1000);
    }

    function _addressToBytes32(address _address) internal pure virtual returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }
}
