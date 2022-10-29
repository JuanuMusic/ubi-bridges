//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {IFUBI} from "../../contracts/interfaces/IFUBI.sol";

contract FUBIMock is ERC721, IFUBI {
    struct Flow {
            uint256 ratePerSecond; // The rate of UBI to drip to this Flow from the current accrued value
            uint256 startTime;
            address sender;
            bool isActive;
    }

    uint256 public tokenCounter = 0;

    constructor() ERC721("FUBI", "Flow"){}
    function mint(address recipient, uint256 ratePerSecond, uint256 startTime, address sender) public {
        _mint(recipient, ++tokenCounter);
        Flow memory flow = Flow({
            sender: sender,
            ratePerSecond: ratePerSecond,
            startTime: startTime,
            isActive: true
        });
        flows[tokenCounter] = flow;
    }


    mapping (uint256 => Flow) public flows;
    function getFlow(uint256 tokenId) public override view returns(
            uint256 ratePerSecond, // The rate of UBI to drip to this Flow from the current accrued value
            uint256 startTime,
            address sender,
            bool isActive
        ) {
            Flow memory flow = flows[tokenId];
            return (flow.ratePerSecond, flow.startTime, flow.sender, flow.isActive);
        }
}