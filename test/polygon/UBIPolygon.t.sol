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
        vm.startPrank(childTunnel);
        uint256 ratePerSecond =100;
        uint256 waitSeconds = 3600;
        uint256 expectedIncrease = ratePerSecond * waitSeconds;
        ubi.addAccrual(user1, ratePerSecond); 

        // Get current balance
        uint256 curAccruedBalance = ubi.accruedBalanceOf(user1);
        console.log("Current block timestamp", block.timestamp);
        // Move forwd 10 secs
        vm.warp(block.timestamp + waitSeconds);

        uint256 newAccruedBalance = ubi.accruedBalanceOf(user1);
        console.log("NEW block timestamp", block.timestamp);

        console.log(newAccruedBalance, curAccruedBalance + expectedIncrease);
    }

    function testConsolidateBalanceOnAddAccrual() public {
        vm.startPrank(childTunnel);
        ubi.addAccrual(user1, 1); 

        // Get current balance
        console.log("Current block timestamp", block.timestamp);
        // Move forwd 10 secs
        vm.warp(block.timestamp + 10);

        // Add accrual (which consolidates balance)
        assertEq(ubi.accruedBalanceOf(user1), 10);
        assertEq(ubi.balanceOf(user1), 10);
        ubi.addAccrual(user1, 1);
        assertEq(ubi.accruedBalanceOf(user1), 0);
        assertEq(ubi.balanceOf(user1), 10);

        // Move forwd 10 secs
        vm.warp(block.timestamp + 1);
        assertEq(ubi.accruedBalanceOf(user1), 2);
        assertEq(ubi.balanceOf(user1), 12);
    }

    function testConsolidateBalanceOnSubAccrual() public {
        vm.startPrank(childTunnel);
        ubi.addAccrual(user1, 2); 

        // Get current balance
        console.log("Current block timestamp", block.timestamp);
        // Move forwd 10 secs
        vm.warp(block.timestamp + 10);

        // Sub accrual (which consolidates balance)
        assertEq(ubi.accruedBalanceOf(user1), 20);
        assertEq(ubi.balanceOf(user1), 20);
        ubi.subAccrual(user1, 1);
        assertEq(ubi.accruedBalanceOf(user1), 0);
        assertEq(ubi.balanceOf(user1), 20);

        // Move forwd 10 secs
        vm.warp(block.timestamp + 1);
        assertEq(ubi.accruedBalanceOf(user1), 1);
        assertEq(ubi.balanceOf(user1), 21);
    }

    function testMint(uint256 amount) public {
        vm.startPrank(childTunnel);
        ubi.mint(user1, amount);
        assertEq(ubi.balanceOf(user1), amount);
    }
}
