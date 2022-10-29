// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import { env } from "process";

async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile
    // manually to make sure everything is compiled
    // await hre.run('compile');

    // We get the contract to deploy
    const UBIPolygon = await ethers.getContractFactory("UBIPolygon");
    const ubiPolygon = await UBIPolygon.deploy("Universal Basic Income", "UBI", process.env.MUMBAI_CHILD_MANAGER!);

    await ubiPolygon.deployed();

    console.log("UBIL2 deployed to:", ubiPolygon.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
