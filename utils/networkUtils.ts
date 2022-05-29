import { Network } from "hardhat/types";
const { ethers, expect } = require("hardhat");

const networkUtils = {
    async timeForward(seconds: number, network: Network) {
        await network.provider.send("evm_increaseTime", [seconds]);
        await network.provider.send("evm_mine");
    },
    async getCurrentBlockTime() {
        const blockNumber = await ethers.provider.getBlockNumber();
        const block = await ethers.provider.getBlock(blockNumber);
        return block.timestamp;
    },
};

export default networkUtils;