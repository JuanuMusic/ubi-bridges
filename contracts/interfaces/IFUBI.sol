// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFUBI {
    function getFlow(uint256 FlowId)
        external
        view
        returns (
            uint256 ratePerSecond,
            uint256 startTime,
            address source,
            bool isActive
        );

    function burn(uint256 tokenId) external;
}
