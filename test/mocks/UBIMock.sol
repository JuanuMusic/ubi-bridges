// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BaseUBI} from "../../contracts/BaseUBI.sol";

contract UBIMock is BaseUBI {

    uint256 ratePerSecond = 100_000_000;

  /** @dev Starts accruing UBI for a registered submission.
  *  @param _human The submission ID.
  */
  function startAccruing(address _human) external {
    _consolidateBalance(_human);
    _addAccrual(_human, ratePerSecond);
  }
}