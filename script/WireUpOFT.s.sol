// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import { OFTWithFee } from "src/layerZero/oft/OFTWithFee.sol";

contract WireUpOFTScript is Script {
    error ListMismatch();

    /// @notice Set trusted remotes for localMevEth
    /// @dev only Admin
    /// @param defaultFeeBp default fee for bridging out of 10,000 i.e. 2 = 0.02%
    /// @param localMevEth local mevETH contract
    /// @param lzChainIds list of remote lz chain ids to set trusted remotes for
    /// @param remoteMevEths list of remote mevETH contracts to set trusted remotes for
    function run(uint16 defaultFeeBp, address localMevEth, uint16[] calldata lzChainIds, address[] calldata remoteMevEths) public {
        uint256 length = lzChainIds.length;
        if (length != remoteMevEths.length) revert ListMismatch();
        vm.startBroadcast();
        for (uint256 i; i < length; i++) {
            OFTWithFee(localMevEth).setTrustedRemote(lzChainIds[i], abi.encodePacked(remoteMevEths[i], localMevEth));
        }
        OFTWithFee(localMevEth).setDefaultFeeBp(defaultFeeBp);
        vm.stopBroadcast();
    }
}
