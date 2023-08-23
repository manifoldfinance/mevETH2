// SPDX-License-Identifier: UPL-1.0
// Copyright (C) 2023 CommodityStream, Inc.
// Copyright (C) 2023 Manifold Finance, Inc.

pragma solidity ^0.8.0;

/**
 * 
 * 
 * @notice OmniChainCompass
 * Integrate mevETH protocol 
 * Compass lets you integrate without worrying about the interfaces or addresses.
 * 
 * Basic PoC for this is implemented in the function:
 * 
 *      getMEVETH - Get the mevETH instance based off of ChainId reported from the execution enviornment
 * 
 *
 *  NOTE.
 *    ChainId may be mis-reported in deveoper tooling and may not report as it would on production enviornments
 * 
 * Libraries:
 * PrimitiveConstants
 *  MainnetConstants
 *  GoerliConstants
 *  
 */



// TODO: What parts of the IERC20 interface do we need, should we inline them?
// import { IERC20 } from "./IERC20.sol";
interface IERC20 {
    function balanceOf(address addr) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);
}


// TODO: Do we even really need this IERC165 interface?
/**
 * @dev Interface of the ERC165 standard
 *  OpenZeppelin Contracts (last updated v4.9.0)
 */
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/// @dev Primitive Constants agnostic to underlying network
library PrimitiveConstants {

    /// @dev Deposit amount required
    uint256 constant DEPOSIT_AMOUNT = 32 ether;
}

/// @dev Library containing address constants for the Ethereum mainnet
library MainnetConstants {

    /// @dev chain id of Ethereum homestead 
    // TODO: return hex or decimal? 
    uint256 constant CHAIN_ID = 1;

    /**
     * 
     *      0x617c8de5bDe54FFBB8D92716Cc947858ca38F582 = Mainnet Checksummed 
     *      0x617c8dE5BdE54ffbb8d92716CC947858cA38f582 = EIP55 Only
     */


    /// @dev MultiSig Address 
    address constant ProtocolMultiSig = 0x617c8dE5BdE54ffbb8d92716CC947858cA38f582;

    /// @dev mevETH address in the Ethereum Homestead Mainnet
    /// @notice This Address is a PLACEHOLDER VALUE 
    address constant mevETH = 0x6900000000000000000000000000000000000088;
}

/// @dev Library containing address constants for the Goerli testing network
library GoerliConstants {

    /// @dev chain id of Goerli
    uint256 constant CHAIN_ID = 5;
    /// @dev mevETH address in the Ethereum Goerli Test Network
    /// @notice This Address is a PLACEHOLDER VALUE 
    address constant mevETH = 0x6900000000000000000000000000000000000088;
}


// TODO: Better semantics instead of  `MainnetConstants` 
// import { {% extends '${name}' %} } from "@/{% extends '${name}' %}.sol";
// import { MainnetConstants, GoerliConstants } from "./Constants.sol";

/// @title OmniChainCompass
/// Integrate mevETH protocol 
/// Compass lets you integrate without worrying about the interfaces or addresses.
/// TODO: Implement versioning that is mutated in value by protocol upgrades

abstract contract OmniChainCompass {


    /// @notice Get the mevETH instance
    function getMEVETH() internal view virtual returns (IERC20 mevETH) {
        uint256 chainId = _getChainId();

        if(chainId == MainnetConstants.CHAIN_ID) {
            mevETH = IERC20(MainnetConstants.mevETH);
        }

        else if (chainId == GoerliConstants.CHAIN_ID) {
            mevETH = IERC20(GoerliConstants.mevETH);
        }

        else {
            _unsupported();
        }
    }

    /// @dev Invalid argument supplied, abort
    function _unsupported() internal pure {
        revert('INVAL');
    }

    /// @dev Helper function to get the id of the current chain
    // NOTE: This is not contentious fork safe
    // <% function getChainId() public view returns (uint256 chainId) { %>
    function _getChainId() internal view returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }
}
