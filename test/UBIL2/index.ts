import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers, network } from "hardhat";
import networkUtils from "../../utils/networkUtils";

let signers: SignerWithAddress[];

describe("UBIL2", function () {

  before(async () => {
    signers = await ethers.getSigners();
  })

  it("happy path - Should increase value of incomingRate when increasing accrual", async function () {
    const UBIL2 = await ethers.getContractFactory("UBIL2");
    const ubiL2 = await UBIL2.deploy("Universal Basic Income", "UBI");
    await ubiL2.deployed();
    // Simulate bridge is owner
    await ubiL2.setUBIBridge(signers[0].address);

    // Recipient of addign accrual
    const recipient = signers[1];
    // Initial balance should be 0
    expect(await ubiL2.balanceOf(recipient.address)).to.equal(0);

    // Add accrual
    await ubiL2.addAccrual(recipient.address, 1000);

    // Wait 1 seconds
    await networkUtils.timeForward(1, network);

    // Check balance
    const { incomingRate } = await ubiL2.accountInfo(recipient.address);

    expect(incomingRate).to.equal(1000);
  });

  it("happy path - Should accrue UBI when increasing accrual", async function () {
    const UBIL2 = await ethers.getContractFactory("UBIL2");
    const ubiL2 = await UBIL2.deploy("Universal Basic Income", "UBI");
    await ubiL2.deployed();
    // Simulate bridge is owner
    await ubiL2.setUBIBridge(signers[0].address);

    // Recipient of addign accrual
    const recipient = signers[1];
    // Initial balance should be 0
    expect(await ubiL2.balanceOf(recipient.address)).to.equal(0);

    // Add accrual
    await ubiL2.addAccrual(recipient.address, 1000);

    // Wait 1 seconds
    await networkUtils.timeForward(1, network);

    // Check balance
    expect(await ubiL2.balanceOf(recipient.address)).to.equal(1000);
  });

  it("happy path - Should decrease accrual UBI when calling subAccrual", async function () {
    const UBIL2 = await ethers.getContractFactory("UBIL2");
    const ubiL2 = await UBIL2.deploy("Universal Basic Income", "UBI");
    await ubiL2.deployed();
    // Simulate bridge is owner
    await ubiL2.setUBIBridge(signers[0].address);

    // Recipient of addign accrual
    const recipient = signers[1];
    // Initial balance should be 0
    expect(await ubiL2.balanceOf(recipient.address)).to.equal(0);

    // Add accrual
    await ubiL2.addAccrual(recipient.address, 1000);

    // Wait 1 seconds
    await networkUtils.timeForward(1, network);

    // Check balance
    expect(await ubiL2.balanceOf(recipient.address)).to.equal(1000);
  });
  it("happy path - Should stop accruing when accrual is decreased", async function () {
    const UBIL2 = await ethers.getContractFactory("UBIL2");
    const ubiL2 = await UBIL2.deploy("Universal Basic Income", "UBI");
    await ubiL2.deployed();
    // Simulate bridge is owner
    await ubiL2.setUBIBridge(signers[0].address);

    // Recipient of addign accrual
    const recipient = signers[1];
    // Initial balance should be 0
    expect(await ubiL2.balanceOf(recipient.address)).to.equal(0);

    // Add accrual
    await ubiL2.addAccrual(recipient.address, 1000);

    // Wait 1 seconds
    await networkUtils.timeForward(1, network);

    // Check balance
    const { incomingRate } = await ubiL2.accountInfo(recipient.address);

    expect(incomingRate).to.equal(1000);

    // Add accrual
    await ubiL2.subAccrual(recipient.address, 1000);

    // Wait 1 seconds
    await networkUtils.timeForward(1, network);

    // Check balance
    const { incomingRate: incomingRate2 } = await ubiL2.accountInfo(recipient.address);

    expect(incomingRate2).to.equal(0);
  });

  it("happy path - Should add balance when calling addBalance", async function () {
    const UBIL2 = await ethers.getContractFactory("UBIL2");
    const ubiL2 = await UBIL2.deploy("Universal Basic Income", "UBI");
    await ubiL2.deployed();
    // Simulate bridge is owner
    await ubiL2.setUBIBridge(signers[0].address);

    // Recipient of addign accrual
    const recipient = signers[1];

    // Initial balance should be 0
    expect(await ubiL2.balanceOf(recipient.address)).to.equal(0);

    // Add accrual
    await ubiL2.addBalance(recipient.address, 1500);

    // Subtract the balance
    await ubiL2.subBalance(recipient.address, 1000);

    // Check balance
    const currentBalance = await ubiL2.balanceOf(recipient.address);

    expect(currentBalance).to.equal(500);

  });
});
