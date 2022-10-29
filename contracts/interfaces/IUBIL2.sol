//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUBIL2 {
    /// @dev Adds a specified accrual rate to an account.
    function addAccrual(address account, uint256 rate) external;

    /// @dev Subtracts a specified accrual rate from an account.
    function subAccrual(address account, uint256 rate) external;

    /// @dev Mints an amount to an account.
    function mint(address account, uint256 amount) external;
}
