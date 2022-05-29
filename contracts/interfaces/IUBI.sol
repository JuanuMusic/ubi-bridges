// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity 0.8.4;

interface IUBI {
    function isDelegator(address _implementation) external view returns(bool);
}