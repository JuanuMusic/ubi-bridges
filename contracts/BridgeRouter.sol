//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {IERC721Receiver} from '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import {IBridge} from './interfaces/IBridge.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract BridgeRouterStorage {
    address governance;
    address UBI;
    address fUBI;

    mapping(uint256 => address) bridgeByChainId;
}

// TODO: Make the BridgeRouter a TransparentUpgradeableProxy so it could support future use cases.
// TODO: Also consider renaming it to BridgeManager.
contract BridgeRouter is IERC721Receiver, BridgeRouterStorage {
    error OnlyGovernance();
    error UnsupportedChain();
    error InvalidAddress();
    error UnsupportedNft();

    //TODO: improve event signatures
    event FlowBridged();
    event AmountBridged();

    modifier onlyGovernance() {
        if (msg.sender == governance) {
            _;
        } else {
            revert OnlyGovernance();
        }
    }

    constructor(
        address _governance,
        address _UBI,
        address _fUBI
    ) {
        governance = _governance;
        UBI = _UBI;
        fUBI = _fUBI;
    }

    //TODO: Should we add EIP-712 meta-tx support for bridge functions?

    /**
     * @notice Sets the
     *
     * @param chainId destination chain ID.
     * @param bridge address where bridge implementation for given chain ID is; use zero-address to disable chain ID.
     */
    function setBridge(uint256 chainId, address bridge) external onlyGovernance {
        bridgeByChainId[chainId] = bridge;
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
        IERC20(UBI).transferFrom(msg.sender, address(this), amount); //TODO: Worth to use SafeERC20 with a fixed UBI impl?
        _getBridgeIfSupported(chainId).bridgeAmount(chainId, amount, data);
        emit AmountBridged();
    }

    /**
     * @dev Bridges a flow by routing the call to the corresponding bride implementation.
     * @param chainId the destination chain ID, specially in case same bridge can handle more than one.
     * @param tokenId the token ID of the flow NFT.
     * @param data arbitrary data that might be required by the bridge implementation.
     */
    function bridgeFlow(
        uint256 chainId,
        uint256 tokenId,
        bytes calldata data
    ) external {
        IERC721(fUBI).transferFrom(msg.sender, address(this), tokenId);
        _bridgeFlow(chainId, tokenId, data);
    }

    /**
     * @dev Hook used to enable ERC-721 token bridging through transfers to this contract.
     * @param tokenId The ID of the bridged ERC-721 token.
     * @param data Arbitrary data passed by the user. It should first contain the chain ID encoded, followed by any
     *             arbitrary data that might be required by the expected bridge implementation.
     */
    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        if (msg.sender == fUBI) {
            (uint256 chainId, bytes memory bridgeData) = abi.decode(data, (uint256, bytes));
            _bridgeFlow(chainId, tokenId, bridgeData);
        } else {
            revert UnsupportedNft();
        }
        return this.onERC721Received.selector;
    }

    /**
     * @dev Bridges a flow by routing the call to the corresponding bride implementation. Reverts if the given chain
     *      ID is not currently supported. Emits a `FlowBridged` event. Internal function to abstract bridge flow logic.
     * @param chainId the destination chain ID, specially in case same bridge can handle more than one.
     * @param tokenId the token ID of the flow NFT.
     * @param data arbitrary data that might be required by the bridge implementation.
     */
    function _bridgeFlow(
        uint256 chainId,
        uint256 tokenId,
        bytes memory data
    ) internal {
        _getBridgeIfSupported(chainId).bridgeFlow(chainId, tokenId, data);
        emit FlowBridged();
    }

    /**
     * @dev Gets the bridge implementation for the given chain ID, reverts in case of unsupported chain.
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
