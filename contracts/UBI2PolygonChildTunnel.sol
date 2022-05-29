//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@maticnetwork/fx-portal/contracts/tunnel/FxBaseChildTunnel.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUBIL2.sol";

contract UBI2PolygonChildTunnel is FxBaseChildTunnel, Ownable {
    address ubi;
    bytes public latestData;
    
    /// @dev Sync type for when UBI is deposited on the bridge
    bytes32 public constant UBI_DEPOSIT = keccak256("UBI_DEPOSIT");
    /// @dev Sync type for when FUBI is deposited on the bridge
    bytes32 public constant FUBI_DEPOSIT = keccak256("FUBI_DEPOSIT");

    /// @dev Event emited when FUBI deposit is received
    event FUBIDepositReceived(address indexed sender, uint256 ratePerSecond, uint256 depositTime, uint256 tokenId);
    /// @dev Event emited when UBI deposit is received
    event UBIDepositReceived(address indexed sender, uint256 amount, uint256 depositTime);

    constructor(address pUBI, address _fxChild, address _tokenTemplate) FxBaseChildTunnel(_fxChild) {
        ubi = pUBI;
    }

    /// @dev set the UBI address.
    function setUBI(address pUBI) public onlyOwner {
        ubi = pUBI;
    }

    //
    // Internal methods
    //
    function _processMessageFromRoot(
        uint256, /* stateId */
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        // decode incoming data
        (bytes32 syncType, bytes memory syncData) = abi.decode(data, (bytes32, bytes));

        if (syncType == FUBI_DEPOSIT) {
            _syncFUBIDeposit(syncData);
        } else if (syncType == UBI_DEPOSIT) {
            _syncUBIDeposit(syncData);
        } else {
            revert("FxERC721ChildTunnel: INVALID_SYNC_TYPE");
        }
    }

    function _syncFUBIDeposit(bytes memory syncData) internal {
        (address sender, uint256 ratePerSecond, uint256 depositTime, uint256 tokenId) = abi.decode(syncData, (address, uint256, uint256, uint256));
        IUBIL2(ubi).addAccrual(sender, ratePerSecond);
        emit FUBIDepositReceived(sender, ratePerSecond, depositTime, tokenId);
    }

    function _syncUBIDeposit(bytes memory syncData) internal {
        (address sender, uint256 amount, uint256 depositTime) = abi.decode(syncData, (address, uint256, uint256));
        IUBIL2(ubi).addBalance(sender, amount);
        emit UBIDepositReceived(sender, amount, depositTime);
    }



}
