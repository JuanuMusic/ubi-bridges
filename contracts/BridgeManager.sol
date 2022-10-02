//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Governable} from "./security/Governable.sol";
import {IBridge} from "./interfaces/IBridge.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IFUBI} from "./interfaces/IFUBI.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

abstract contract BridgeManagerStorage {
    /**
     * WARNING: Only add storage fields appending them just before the `__gap`. Never change the order of them.
     *
     * Read about storage layout compatibility at https://blog.openzeppelin.com/the-state-of-smart-contract-upgrades/
     * and also at https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#modifying-your-contracts.
     */
    mapping(uint256 => address) public bridgeByChainId;
    mapping(uint256 => bool) public bridgedFlows;
    address public UBI;
    address public fUBI;

    /**
     * WARNING: Add the new storage fields just above this `__gap` field and decrement the `__gap` array size once per
     * each new storage SLOT used. Per each storage slot used, not storage field!
     *
     * Read about storage gaps at https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps.
     */
    uint256[100] private __gap;
}

/**
 * WARNING: If you add inheritance from contracts that have storage fields, make sure you do not brake storage layout
 * compatibility. Always add new inheritance appending them at the end of current ones and do not re-order them.
 * Add new non-inherited storage at `BridgeManagerStorage` following the rules documented there.
 *
 * Read about storage layout compatibility at https://blog.openzeppelin.com/the-state-of-smart-contract-upgrades/
 * and also at https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#modifying-your-contracts.
 */
contract BridgeManager is IERC721Receiver, Initializable, UUPSUpgradeable, Governable, BridgeManagerStorage {
    error InvalidAddress();
    error OnlyActive();
    error OnlySource();
    error OnlyUBI();
    error UnsupportedChain();
    error UnsupportedNft();

    event AmountBridged(address indexed bridge, uint256 indexed chainId, uint256 indexed amount, bytes data);
    event BridgeSet(uint256 indexed chainId, address bridge);
    event FlowBridged(address indexed bridge, uint256 indexed chainId, uint256 indexed tokenId, bytes data);

    /**
     * @dev Contract initializer. For new `BridgeManager` versions replace `initializer` modifier by `reinitializer(v)`
     * where `v` is the new version number of the contract. Read more about initializers at:
     * https://blog.openzeppelin.com/the-state-of-smart-contract-upgrades/#implementation-contract-limitations
     * @param _governance The governance address.
     * @param _UBI The UBI ERC-20 address.
     * @param _fUBI The fUBI ERC-721 address.
     */
    function initialize(
        address _governance,
        address _UBI,
        address _fUBI
    ) external initializer {
        governance = _governance;
        UBI = _UBI;
        fUBI = _fUBI;
    }

    /**
     * @dev Sets the bridge for the given chain ID.
     * @param _chainId The destination chain ID.
     * @param _bridge The bridge implementation address for given chain ID. Set as zero address for unsupported chains.
     */
    function setBridge(uint256 _chainId, address _bridge) external onlyGovernance {
        bridgeByChainId[_chainId] = _bridge;
        emit BridgeSet(_chainId, _bridge);
    }

    /**
     * @dev Bridges an amount by routing the call to the corresponding bride implementation.
     * @param _chainId The destination chain ID, specially in case same bridge can handle more than one.
     * @param _amount The amount of tokens to bridge.
     * @param _data Arbitrary data that might be required by the bridge implementation.
     */
    function bridgeAmount(
        uint256 _chainId,
        uint256 _amount,
        bytes calldata _data
    ) external {
        IERC20(UBI).transferFrom(msg.sender, address(this), _amount);
        address bridge = _getBridgeAddressIfSupported(_chainId);
        IBridge(bridge).bridgeAmount(_chainId, _amount, _data);
        emit AmountBridged(bridge, _chainId, _amount, _data);
    }

    /**
     * @dev Bridges a flow by routing the call to the corresponding bride implementation.
     * @param _chainId The destination chain ID, specially in case same bridge can handle more than one.
     * @param _tokenId The token ID of the flow NFT.
     * @param _data arbitrary data that might be required by the bridge implementation.
     */
    function bridgeFlow(
        uint256 _chainId,
        uint256 _tokenId,
        bytes calldata _data
    ) external {
        _validateFlowBridging(msg.sender, _tokenId);
        IERC721(fUBI).transferFrom(msg.sender, address(this), _tokenId);
        _bridgeFlow(_chainId, _tokenId, _data);
    }

    /**
     * @dev Hook used to enable ERC-721 token bridging through transfers to this contract.
     * @param _previousOwner The addess that was owning the NFT just before this
     * @param _tokenId The ID of the bridged ERC-721 token.
     * @param _data Arbitrary data passed by the user. It should first contain the chain ID encoded, followed by any
     * arbitrary data that might be required by the expected bridge implementation.
     */
    function onERC721Received(
        address,
        address _previousOwner,
        uint256 _tokenId,
        bytes calldata _data
    ) public override returns (bytes4) {
        if (msg.sender == fUBI) {
            _validateFlowBridging(_previousOwner, _tokenId);
            (uint256 chainId, bytes memory bridgeData) = abi.decode(_data, (uint256, bytes));
            _bridgeFlow(chainId, _tokenId, bridgeData);
        } else {
            revert UnsupportedNft();
        }
        return this.onERC721Received.selector;
    }

    // TODO: on cancel!

    function _validateFlowBridging(address _previousOwner, uint256 _tokenId) internal view {
        (, , address source, bool isActive) = IFUBI(fUBI).getFlow(_tokenId);
        if (!isActive) {
            revert OnlyActive();
        } else if (_previousOwner != source) {
            revert OnlySource();
        }
    }

    /**
     * @dev Bridges a flow by routing the call to the corresponding bride implementation. Reverts if the given chain
     * ID is not currently supported. Emits a `FlowBridged` event. Internal function to abstract bridge flow logic.
     * @param _chainId The destination chain ID, specially in case same bridge can handle more than one.
     * @param _tokenId The token ID of the flow NFT.
     * @param _data Arbitrary data that might be required by the bridge implementation.
     */
    function _bridgeFlow(
        uint256 _chainId,
        uint256 _tokenId,
        bytes memory _data
    ) internal {
        bridgedFlows[_tokenId] = true;
        address bridge = _getBridgeAddressIfSupported(_chainId);
        IBridge(bridge).bridgeFlow(_chainId, _tokenId, _data);
        emit FlowBridged(bridge, _chainId, _tokenId, _data);
    }

    /**
     * @dev Gets the bridge implementation address for the given chain ID, reverts in case of unsupported chain.
     * @param _chainId The ID of the destination chain for the bridge.
     * @return The address of the bridge implementation.
     */
    function _getBridgeAddressIfSupported(uint256 _chainId) internal view returns (address) {
        address bridge = bridgeByChainId[_chainId];
        if (bridge == address(0)) {
            revert UnsupportedChain();
        }
        return bridge;
    }

    /**
     * @dev Overrides the `_authorizeUpgrade` hook from `UUPSUpgradeable` adding the `onlyGovernance` modifier.
     * @param _newImplementation The new contract implementation address.
     */
    function _authorizeUpgrade(address _newImplementation) internal override onlyGovernance {}
}
