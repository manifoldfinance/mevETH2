// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IMevETH {
    /**
     * @notice Sets the Manifold LSD address
     * @dev This function sets the Manifold LSD address. This address is used to interact with the Manifold LSD contract.
     * @param _manifoldLSD The address of the Manifold LSD contract.
     */
    function setManifoldLSD(address _manifoldLSD) external;

    function mint(address to, uint256 amount) external;

    /**
     * @notice This function burns a given amount of tokens from the given address.
     * @dev This function is used to burn a given amount of tokens from the given address. It is important to note that this function is only available to the owner of the contract.
     */
    function burn(address from, uint256 amount) external;
}
