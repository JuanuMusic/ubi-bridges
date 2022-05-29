//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IUBIL2 {
    /// @dev Adds a specified accrual rate to an account.
    function addAccrual(address account, uint256 rate) external;

    /// @dev Subtracts a specified accrual rate from an account.
    function subAccrual(address account, uint256 rate) external;

    /// @dev Adds the specified balance to the account. Only executed by the bridge.
    function addBalance(address account, uint256 value) external;
}