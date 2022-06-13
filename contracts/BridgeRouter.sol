//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {IERC721Receiver} from '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import {IBridge} from './interfaces/IBridge.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

// TODO: Make the BridgeRouter a TransparentUpgradeableProxy so it could support future use cases.
// TODO: Also consider renaming it to BridgeManager.
contract BridgeRouter is IERC721Receiver {
    error OnlyGovernance();
    error UnsupportedChain();
    error InvalidAddress();

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

    address governance;
    address UBI;
    address fUBI;

    mapping(uint256 => address) bridgeByChainId;

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
        IERC20(UBI).transferFrom(msg.sender, address(this), amount); //TODO: Worth to use SafeERC20 with a fixed impl?
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
        //TODO: Could use safeTransferFrom and let the onERC721Received do the magic, but this should be cheaper
        IERC721(fUBI).transferFrom(msg.sender, address(this), tokenId);
        _bridgeFlow(chainId, tokenId, data);
    }

    /**
     * @param data it should contain encoded the chainId and then any arbitrary data that might be required by the
     * bridge implementation.
     */
    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256 tokenId,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        if (msg.sender == fUBI) {
            (uint256 chainId, bytes memory bridgeData) = abi.decode(data, (uint256, bytes));
            _bridgeFlow(chainId, tokenId, bridgeData);
        }
        // TODO: Maybe add else branch with revert to be firendly against accidental unsupported-NFTs transfers?
        return this.onERC721Received.selector;
    }

    function _bridgeFlow(
        uint256 chainId,
        uint256 tokenId,
        bytes memory data
    ) internal {
        _getBridgeIfSupported(chainId).bridgeFlow(chainId, tokenId, data);
        emit FlowBridged();
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
