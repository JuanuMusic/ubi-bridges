// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contracts/BridgeManager.sol";
import "../contracts/polygon/UBIPolygonRootTunnel.sol";
import {FUBIMock} from "./mocks/FUBIMock.sol";
import {FXRootMock} from "./mocks/FXRootMock.sol";

contract BridgeManagerTest is Test {
    address GOVERNOR = address(1);
    address ubi = address(777);
    address checkpointManager = address(111);
    FXRootMock fxRootManager;

    address user1 = address(123);
    address user2 = address(321);

    uint256 CHAIN_ID = 112233; 

    function _getChainId() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    FUBIMock fubi;
    UBIPolygonRootTunnelBridge root;
    BridgeManager bm;
     function setUp() public {
        fubi = new FUBIMock();
        fxRootManager = new FXRootMock();
        root = new UBIPolygonRootTunnelBridge(ubi, address(fubi), checkpointManager, address(fxRootManager));
        bm  = new BridgeManager();
        root.setBridgeManager(address(bm));
        
        bm.initialize(GOVERNOR, ubi, address(fubi));
        vm.startPrank(GOVERNOR);
        bm.setBridge(_getChainId(), address(root));
        vm.stopPrank();
    }

    function testBridgeFlowTransferred() public {
        fubi.mint(user1, 100, block.timestamp, user2);

        vm.startPrank(user1);
        fubi.approve(address(bm), 1);
        bm.bridgeFlow(_getChainId(), 1, abi.encode("hi"));
        vm.stopPrank();

        assertEq(fubi.ownerOf(1), address(bm));
    }

    function testBridgeFlowMinted() public {
        fubi.mint(address(bm), 100, block.timestamp, address(bm));
        assertEq(fubi.ownerOf(1), address(bm));
    }

}