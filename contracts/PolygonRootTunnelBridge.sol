//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@maticnetwork/fx-portal/contracts/tunnel/FxBaseRootTunnel.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IUBI.sol';
import './interfaces/IFUBI.sol';
import './interfaces/IBridge.sol';

contract PolygonRootTunnelBridge is IBridge, FxBaseRootTunnel, Ownable {
    address UBI;
    address fUBI;
    address bridgeRouter;
    bytes public latestData;

    bytes32 public constant FUBI_DEPOSIT = keccak256('FUBI_DEPOSIT');

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

    /// @dev set the UBI address.
    function setUBI(address _UBI) public onlyOwner {
        UBI = _UBI;
    }

    /// @dev set the FUBI address.
    function setFUBI(address _fUBI) public onlyOwner {
        fUBI = _fUBI;
    }

    function _processMessageFromChild(bytes memory data) internal override {
        //TODO: Implement later
    }

    function bridgeAmount(
        uint256 chainId,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool) {
        // TODO: Implement later
    }

    function bridgeFlow(
        uint256 chainId,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bool) {
        // require(IUBI(ubi).isDelegator(msg.sender), 'only delegator can deposit');
        if (msg.sender != bridgeRouter) {
            revert('OnlyBridgeRouter');
        }
        // NOTE: BirdgeRouter already validated that the call comes from Flow owner or fUBI contract.
        (uint256 ratePerSecond, uint256 startTime, address sender, bool isActive) = IFUBI(fUBI).getFlow(tokenId);
        if (!isActive) {
            revert('InactiveFlow');
        }
        // TODO: Add origin chainId in the message, to avoid problems in case we have more bridges
        bytes memory message = abi.encode(FUBI_DEPOSIT, abi.encode(sender, ratePerSecond, block.timestamp, tokenId));
        _sendMessageToChild(message);
        emit FUBIDeposited(sender, msg.sender, tokenId);
        return true;
    }

    function _getChainId() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}
