//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@maticnetwork/fx-portal/contracts/tunnel/FxBaseRootTunnel.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IUBI.sol';
import './interfaces/IFUBI.sol';
import './interfaces/IBridge.sol';

contract UBIPolygonRootTunnelBridge is IBridge, FxBaseRootTunnel, Ownable {
    address UBI;
    address fUBI;
    address bridgeManager;
    bytes public latestData;
    mapping(uint256 => bool) bridgedFubis;

    bytes32 public constant FUBI_DEPOSIT = keccak256('FUBI_DEPOSIT');
    bytes32 public constant FUBI_CANCELLED_ON_L2 = keccak256('FUBI_CANCELLED_ON_L2');

    /// @dev Event emited when a FUBI has been deposited to the bridge.
    event FUBIDeposited(address indexed sourceHuman, address indexed depositer, uint256 id);

    constructor(
        address _UBI,
        address _fUBI,
        address _checkpointManager,
        address _fxRoot
    ) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
        UBI = _UBI;
        fUBI = _fUBI;
    }

    modifier onlyBridgeManager() {
        require(msg.sender == "Only Bridge Manager can call this");
        _;
    }

    /// @dev set the UBI address.
    function setUBI(address _UBI) public onlyOwner {
        UBI = _UBI;
    }

    /// @dev set the FUBI address.
    function setFUBI(address _fUBI) public onlyOwner {
        fUBI = _fUBI;
    }

    function _processMessageFromChild(bytes memory data) internal override {
        // decode incoming data
        (bytes32 syncType, bytes memory syncData) = abi.decode(data, (bytes32, bytes));
        if(syncType == FUBI_CANCELLED_ON_L2) {
            (uint256 tokenId, uint256 cancelationTime) = abi.decode(syncData, (address, uint256, uint256, uint256));
            
        } else {
            revert("FxERC721ChildTunnel: INVALID_SYNC_TYPE");
        }
    }

    function bridgeAmount(
        uint256 chainId,
        uint256 amount,
        bytes calldata data
    ) external override onlyBridgeManager {
        // TODO: Implement later
    }

    function bridgeFlow(
        uint256 chainId,
        uint256 tokenId,
        bytes calldata data
    ) external override onlyBridgeManager {
        // require(IUBI(ubi).isDelegator(msg.sender), 'only delegator can deposit');
        if (msg.sender != bridgeManager) {
            revert('OnlyBridgeManager');
        }
        // NOTE: BirdgeRouter already validated that the call comes from Flow owner or fUBI contract.
        (uint256 ratePerSecond, uint256 startTime, address sender, bool isActive) = IFUBI(fUBI).getFlow(tokenId);
        if (!isActive) {
            revert('InactiveFlow');
        }

        require(!bridgedFubis[tokenId], "flow already bridged");
        bridgedFubis[tokenId] = true;
        // TODO: Add origin chainId in the message, to avoid problems in case we have more bridges
        bytes memory message = abi.encode(FUBI_DEPOSIT, abi.encode(sender, ratePerSecond, block.timestamp, tokenId));
        _sendMessageToChild(message);
        emit FUBIDeposited(sender, msg.sender, tokenId);
    }

    function _getChainId() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function onDelegationCanceled(uint256 tokenId) {
        // ACA TIENE QUE CHEQUEAR QUE EL BRIDGE MAAGER LO HAYA MARCADO.
    }
}
