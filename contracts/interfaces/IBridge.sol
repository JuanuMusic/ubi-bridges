//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IBridge {
    /**
     * @dev Bridges an amount from origin chain to the chain corresponding to the given chain ID.
     * @param chainId the destination chain ID, specially in case same bridge can handle more than one.
     * @param amount the amount of tokens to bridge.
     * @param data arbitrary data that might be required by the bridge implementation.
     */
    function bridgeAmount(
        uint256 chainId,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    /**
     * @dev Bridges a flow from origin chain to the chain corresponding to the given chain ID.
     * @param chainId the destination chain ID, specially in case same bridge can handle more than one.
     * @param accrualPerSecond the accrual of the flow to brige.
     * @param data arbitrary data that might be required by the bridge implementation.
     */
    function bridgeFlow(
        uint256 chainId,
        uint256 accrualPerSecond,
        bytes calldata data
    ) external returns (bool);
}