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
  const UBIPolygonChildTunnel = await ethers.getContractFactory("UBIPolygonChildTunnel");
  const child = await UBIPolygonChildTunnel.attach(process.env.FX_CHILD_TUNNEL!);

  console.log("Setting root tunnel...")
  await child.setFxRootTunnel(process.env.FX_ROOT_TUNNEL!);

  console.log("Setting UBI address...")
  await child.setUBI(process.env.UBI_L2!);

  console.log("Child Tunnel Setup completed");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
