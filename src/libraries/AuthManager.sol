/// SPDX-License-Identifier: SSPL-1.-0



pragma solidity ^0.8.19;

import { IAuth } from "src/interfaces/IAuth.sol";

/// @notice Periphery contract to unify Auth updates across MevEth, MevEthShareVault and WagyuStaker
/// @dev deployment address should be added as admin in initial setup
/// @dev contract addresses are upgradeable. To upgrade auth a redeploy is necessary
contract AuthManager {
    address public immutable auth;
    address public mevEth;
    address public mevEthShareVault;
    address public wagyuStaker;

    error Unauthorized();

    enum Operation {
        ADDADMIN,
        DELETEADMIN,
        ADDOPERATOR,
        DELETEOPERATOR
    }

    /// @notice emitted when MevEthShareVault is a multisig to log missed auth updates
    /// @dev missed updates will need to be manually added when upgrading from a multisig
    event MevEthShareVaultAuthUpdateMissed(address changeAddress, Operation operation);

    constructor(address initialAdmin, address initialMevEth, address initialShareVault, address initialStaker) {
        // auth set one time for safety
        auth = initialAdmin;
        // upgradeable contract addresses
        mevEth = initialMevEth;
        mevEthShareVault = initialShareVault;
        wagyuStaker = initialStaker;
    }

    modifier onlyAuth() {
        if (msg.sender != auth) {
            revert Unauthorized();
        }
        _;
    }

    /**
     * @notice Updates the mevEth address
     * @dev This function is only callable by the authorized address
     * @param newMevEth The new mevEth address
     */
    function updateMevEth(address newMevEth) external onlyAuth {
        mevEth = newMevEth;
    }

    function updateMevEthShareVault(address newMevEthShareVault) external onlyAuth {
        mevEthShareVault = newMevEthShareVault;
    }

    function updateWagyuStaker(address newWagyuStaker) external onlyAuth {
        wagyuStaker = newWagyuStaker;
    }


                           Maintenance Functions
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Adds a new admin to the MevEth, WagyuStaker, and MevEthShareVault contracts.
     * @dev If the MevEthShareVault is a multisig, the `MevEthShareVaultAuthUpdateMissed` event is emitted.
     */
    function addAdmin(address newAdmin) external onlyAuth {
        IAuth(mevEth).addAdmin(newAdmin);
        IAuth(wagyuStaker).addAdmin(newAdmin);
        try IAuth(mevEthShareVault).addAdmin(newAdmin) { }
        catch {
            // handle multisig case
            emit MevEthShareVaultAuthUpdateMissed(newAdmin, Operation.ADDADMIN);
        }
    }

    function deleteAdmin(address oldAdmin) external onlyAuth {
        IAuth(mevEth).deleteAdmin(oldAdmin);
        IAuth(wagyuStaker).deleteAdmin(oldAdmin);
        try IAuth(mevEthShareVault).deleteAdmin(oldAdmin) { }
        catch {
            // handle multisig case
            emit MevEthShareVaultAuthUpdateMissed(oldAdmin, Operation.DELETEADMIN);
        }
    }

    function addOperator(address newOperator) external onlyAuth {
        IAuth(mevEth).addOperator(newOperator);
        IAuth(wagyuStaker).addOperator(newOperator);
        try IAuth(mevEthShareVault).addOperator(newOperator) { }
        catch {
            // handle multisig case
            emit MevEthShareVaultAuthUpdateMissed(newOperator, Operation.ADDOPERATOR);
        }
    }

    function deleteOperator(address oldOperator) external onlyAuth {
        IAuth(mevEth).deleteOperator(oldOperator);
        IAuth(wagyuStaker).deleteOperator(oldOperator);
        try IAuth(mevEthShareVault).deleteOperator(oldOperator) { }
        catch {
            // handle multisig case
            emit MevEthShareVaultAuthUpdateMissed(oldOperator, Operation.DELETEOPERATOR);
        }
    }
}
