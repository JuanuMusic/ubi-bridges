// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile
    // manually to make sure everything is compiled
    // await hre.run('compile');

    // We get the contract to deploy
    const UBIL2 = await ethers.getContractFactory("UBIL2");
    const ubiL2 = await UBIL2.attach(process.env.UBI_L2!);
    await ubiL2.deployed();

    console.log("SETTING Setting UBI child tunnel...")
    await ubiL2.setUBIBridge(process.env.FX_CHILD_TUNNEL!);

    console.log("UBIL2 setup completed");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
