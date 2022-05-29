import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers, network } from "hardhat";
import networkUtils from "../../utils/networkUtils";

let signers: SignerWithAddress[];

describe("UBIL2", function () {

  before(async () => {
    signers = await ethers.getSigners();
  })

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
});
