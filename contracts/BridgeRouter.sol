//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {IBridge} from './interfaces/IBridge.sol';

contract BridgeRouter {
    error OnlyGovernance();
    error UnsupportedChain();
    error InvalidAddress();

    modifier onlyGovernance() {
        if (msg.sender == governance) {
            _;
        } else {
            revert OnlyGovernance();
        }
    }

    address governance;

    mapping(uint256 => address) bridgeByChainId;

    /**
     * @notice Sets the
     *
     * @param chainId destination chain ID.
     * @param bridge address where bridge implementation for given chain ID is; use zero-address to disable chain ID.
     */
    function setBridge(uint256 chainId, address bridge) external onlyGovernance {
        if (bridge == address(0)) {
            revert InvalidAddress();
        } else {
            bridgeByChainId[chainId] = bridge;
        }
    }

    /**
     * @dev Bridges an amount by routing the call to the corresponding bride implementation.
     * @param chainId the destination chain ID, specially in case same bridge can handle more than one.
     * @param amount the amount of tokens to bridge.
     * @param data arbitrary data that might be required by the bridge implementation.
     */
    function bridgeAmount(
        uint256 chainId,
        uint256 amount,
        bytes calldata data
    ) external {
        _getBridgeIfSupported(chainId).bridgeAmount(chainId, amount, data);
    }

    /**
     * @dev Bridges a flow by routing the call to the corresponding bride implementation.
     * @param chainId the destination chain ID, specially in case same bridge can handle more than one.
     * @param accrualPerSecond the accrual of the flow to brige.
     * @param data arbitrary data that might be required by the bridge implementation.
     */
    function bridgeFlow(
        uint256 chainId,
        uint256 accrualPerSecond,
        bytes calldata data
    ) external {
        _getBridgeIfSupported(chainId).bridgeFlow(chainId, accrualPerSecond, data);
    }

    /**
     * @dev Gets the bridge implementation for the given chain ID, fails in case of unsupported chain.
     * @param chainId the ID of the destination chain for the bridge.
     */
    function _getBridgeIfSupported(uint256 chainId) internal view returns (IBridge) {
        address bridge = bridgeByChainId[chainId];
        if (bridge == address(0)) {
            revert UnsupportedChain();
        }
        return IBridge(bridge);
    }
}
