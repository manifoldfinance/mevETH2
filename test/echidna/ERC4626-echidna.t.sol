pragma solidity 0.8.19;

import { CryticERC4626PropertyTests } from "properties/ERC4626/ERC4626PropertyTests.sol";
// this token _must_ be the vault's underlying asset
import { TestERC20Token } from "properties/ERC4626/util/TestERC20Token.sol";

import { MevEth } from "src/MevEth.sol";
import "../mocks/WETH9.sol";
import "../mocks/DepositContract.sol";
import "../mocks/LZEndpointMock.sol";
import "src/MevEthShareVault.sol";

contract CryticERC4626Harness is CryticERC4626PropertyTests {
    uint16 constant ETH_ID = 101;
    DepositContract internal depositContract;
    MevEth internal mevEth;
    WETH9 internal weth;
    LZEndpointMock internal layerZeroEndpoint;
    address immutable SamBacha = address(0x01);

    constructor() {
        depositContract = new DepositContract();
        weth = new WETH9();
        layerZeroEndpoint = new LZEndpointMock(ETH_ID);

        // Deploy the mevETH contract
        mevEth = new MevEth(SamBacha, address(weth), address(layerZeroEndpoint));
        // TestERC20Token _asset = new TestERC20Token("Test Token", "TT", 18);
        initialize(address(mevEth), address(weth), false);
    }
}
