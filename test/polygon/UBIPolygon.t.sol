// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../contracts/polygon/UBIPolygon.sol";

contract UBIPolygonTest is Test {
    UBIPolygon public ubi;
    address childTunnel = address(1);
    address user1 = address(20);
    address user2 = address(21);

    function setUp() public {
        ubi = new UBIPolygon(childTunnel);
    }

    function testAddAccrual(uint256 amount) public {
        vm.startPrank(childTunnel);
        ubi.addAccrual(user1, amount);
        (uint256 accruedSince, uint256 incomingRate) = ubi.accountInfo(user1);
        assertEq(incomingRate, amount);
    }

    function testAddAccrualAdNotChildTunnel(uint256 amount) public {
        vm.expectRevert(NotChildTunnel.selector);
        ubi.addAccrual(user1, amount);
    }

    function testSubAccrual() public {
        vm.startPrank(childTunnel);
        ubi.addAccrual(user1, 100);
        ubi.subAccrual(user1, 25);
        (uint256 accruedSince, uint256 incomingRate) = ubi.accountInfo(user1);
        assertEq(incomingRate, 75);
    }

    function testSubAccrualAdNotChildTunnel(uint256 amount) public {
        vm.expectRevert(NotChildTunnel.selector);
        ubi.subAccrual(user1, amount);
        (uint256 accruedSince, uint256 incomingRate) = ubi.accountInfo(user1);
        assertEq(incomingRate, 0);
    }

    function testGetAccruedBalane() public{
        revert("TODO: Implement time-dependant test for getAccruedBalance");
    }

    function testConsolidateBalanceOnAddAccrual(uint256 amount) public {
        vm.startPrank(childTunnel);
        ubi.addAccrual(user1, amount); 
        revert("TODO: Implement time-dependant test of consolidate balance");
    }

    function testConsolidateBalanceOnSubAccrual() public {
        vm.startPrank(childTunnel);
        uint256 amount =10;
        ubi.addAccrual(user1, amount); 
        // Move forwd 10 secs
        vm.warp(10);

        assertEq(ubi.balanceOf(user1), amount * 10);
    }

    function testMint(uint256 amount) public {
        vm.startPrank(childTunnel);
        ubi.mint(user1, amount);
        assertEq(ubi.balanceOf(user1), amount);
    }
}
