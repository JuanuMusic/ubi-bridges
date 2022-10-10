// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../contracts/polygon/UBIPolygonChildTunnel.sol";
import "../../contracts/polygon/UBIPolygon.sol";

contract UBIPolygonChildTunnelTest is Test {
    address fxChild = address(123);
    UBIPolygonChildTunnel childTunnel;
    UBIPolygon ubi;

    address fxRootTunnel = address(1);
    address user1 = address(20);
    address user2 = address(21);

    // WHY CAN'T WE USE childTunnel.FUBI_DEPOSIT public constants ???
    bytes32 constant FUBI_DEPOSIT = keccak256("FUBI_DEPOSIT");
    bytes32 constant UBI_DEPOSIT = keccak256("UBI_DEPOSIT");

    function setUp() public {
        childTunnel  = new UBIPolygonChildTunnel(fxChild);
        childTunnel.setFxRootTunnel(fxRootTunnel);
        ubi = new UBIPolygon(address(childTunnel));
        childTunnel.setUBI(address(ubi));
    }

    function testSetUBI() public {
        address ubiAddress = address(28);
        childTunnel.setUBI(ubiAddress);
        assertEq(childTunnel.ubi(), ubiAddress);
    }

    function depositFUBI(address source, uint256 rate, uint256 tokenId) internal {
        bytes memory data = abi.encode(FUBI_DEPOSIT, abi.encode(user1, rate, block.timestamp, tokenId));
        childTunnel.processMessageFromRoot(1, fxRootTunnel, data);
    }

    function testFUBIDepositCorrectly() public {
        uint256 rate = 100;
        vm.startPrank(fxChild);
        depositFUBI(user1, rate, 10);
        (uint256 accruedSince, uint256 incomingRate) = ubi.accountInfo(user1);
        assertEq(incomingRate, rate);
        //  Move 10 seconds
        vm.warp(block.timestamp + 10);
        // Assert accrued balance increased correctly
        assertEq(ubi.accruedBalanceOf(user1), 1000);
        assertEq(ubi.balanceOf(user1), 1000);
    }

    function testUBIDepositCorrectly(uint256 amount) public {
        vm.startPrank(fxChild);
        bytes memory data = abi.encode(UBI_DEPOSIT, abi.encode(user1, amount, block.timestamp));
        childTunnel.processMessageFromRoot(1, fxRootTunnel, data);
        uint256 balance = ubi.balanceOf(user1);
        assertEq(balance, amount);
    }

    function testMessageFromRootStateID() public {
        revert("TODO: should we implement stateID validation tests??");
    }

    function testOnCancelDelegation() public {
        uint256 rate = 100;
        vm.startPrank(fxChild);
        depositFUBI(user1, rate, 11);
        vm.stopPrank();
        
        vm.startPrank(address(ubi));
        childTunnel.onCancelDelegation(user1, 11, rate);
        (uint256 accruedSince, uint256 incomingRate) = ubi.accountInfo(user1);
        assertEq(incomingRate, 0);
    }
}
