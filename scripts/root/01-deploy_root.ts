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

  const UBI = "0xf261c4f93d1b2991bB47e7F295AF3B2Fc17BD440"
  const FUBI = "0xAAeCD4c0045F7c798B2E76820281B2ff7026328b"
  // We get the contract to deploy
  const UBI2PolygonRootTunnel = await ethers.getContractFactory("UBI2PolygonRootTunnel");
  const root = await UBI2PolygonRootTunnel.deploy(UBI, FUBI, process.env.ROOT_CHECKPOINT_MANAGER!, process.env.FX_ROOT!);

  await root.deployed();

  console.log("Greeter deployed to:", root.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
