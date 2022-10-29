// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUBI {
    function isDelegator(address _implementation) external view returns (bool);
}
