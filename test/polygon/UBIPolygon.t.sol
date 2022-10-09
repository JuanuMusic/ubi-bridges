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

    function testAddAccrual() public {
        vm.startPrank(childTunnel);
        ubi.addAccrual(user1, 100);
        (uint256 accruedSince, uint256 incomingRate) = ubi.accountInfo(user1);
        assertEq(incomingRate, 100);
    }

    function testAddAccrualAdNotChildTunnel() public {
        vm.expectRevert(NotChildTunnel.selector);
        ubi.addAccrual(user1, 100);
    }

    function testSubAccrual() public {
        vm.startPrank(childTunnel);
        ubi.addAccrual(user1, 100);
        ubi.subAccrual(user1, 25);
        (uint256 accruedSince, uint256 incomingRate) = ubi.accountInfo(user1);
        assertEq(incomingRate, 75);
    }

    function testSubAccrualAdNotChildTunnel() public {
        vm.expectRevert(NotChildTunnel.selector);
        ubi.subAccrual(user1, 100);
        (uint256 accruedSince, uint256 incomingRate) = ubi.accountInfo(user1);
        assertEq(incomingRate, 0);
    }

    function testGetAccruedBalane() public{
        revert("TODO: Implement time-dependant test for getAccruedBalance");
    }

    function testConsolidateBalanceOnAddAccrual() public {
        vm.startPrank(childTunnel);
        ubi.addAccrual(user1, 100); 
        revert("TODO: Implement time-dependant test of consolidate balance");
    }

    function testConsolidateBalanceOnSubAccrual() public {
        vm.startPrank(childTunnel);
        ubi.addAccrual(user1, 100); 
        revert("TODO: Implement time-dependant test of consolidate balance");
    }

    function testMint() public {
        vm.startPrank(childTunnel);
        uint256 toMint  = 100;
        ubi.mint(user1, toMint);
        assertEq(ubi.balanceOf(user1), toMint);
    }
}
