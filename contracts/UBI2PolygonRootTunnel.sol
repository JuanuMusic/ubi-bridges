//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@maticnetwork/fx-portal/contracts/tunnel/FxBaseRootTunnel.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUBI.sol";
import "./interfaces/IFUBI.sol";

contract UBI2PolygonRootTunnel is IERC721Receiver, FxBaseRootTunnel, ReentrancyGuard, Ownable {
    address ubi;
    address fubi;
    bytes public latestData;
    
    bytes32 public constant FUBI_DEPOSIT = keccak256("FUBI_DEPOSIT");
    
    /// @dev Event emited when a FUBI has been deposited to the bridge.
    event FUBIDeposited(address indexed sourceHuman, address indexed depositer, uint256 id);

    constructor(address pUBI, address pFUBI, address _checkpointManager, address _fxRoot) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
        ubi = pUBI;
        fubi = pFUBI;
    }

    /// @dev set the UBI address.
    function setUBI(address pUBI) public onlyOwner {
        ubi = pUBI;
    }

    /// @dev set the FUBI address.
    function setFUBI(address pFUBI) public onlyOwner {
        fubi = pFUBI;
    }

    function _processMessageFromChild(bytes memory data) internal override {
        
    }

    /// @dev Callabck for when an ERC721 tokenm is received. Caller must be FUBI contract.
    function onERC721Received(address, address, uint256 _tokenId, bytes calldata _data) public virtual override nonReentrant returns (bytes4) {
        require(IUBI(ubi).isDelegator(msg.sender), "only delegator can deposit");
        require(msg.sender == fubi, "sender must be fubi");
        (uint256 ratePerSecond, // The rate of UBI to drip to this Flow from the current accrued value
        uint256 startTime,
        address sender,
        bool isActive) = IFUBI(fubi).getFlow(_tokenId);
         require(isActive, "can't bridge inactive flow");

        // Source (will be recipient), rate, time the the flow was delegated to the bridge.
         bytes memory message = abi.encode(FUBI_DEPOSIT, abi.encode(sender, ratePerSecond, block.timestamp, _tokenId));
         _sendMessageToChild(message);

         emit FUBIDeposited(sender, msg.sender, _tokenId);
        
        return this.onERC721Received.selector;
    }
}
