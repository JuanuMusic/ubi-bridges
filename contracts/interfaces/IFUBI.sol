// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFUBI {
    function getFlow(uint256 FlowId)
        external
        view
        returns (
            uint256 ratePerSecond, // The rate of UBI to drip to this Flow from the current accrued value
            uint256 startTime,
            address sender,
            bool isActive
        );
}
