//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Governable {
    event GovernanceTransferred(address indexed oldGovernance, address indexed newGovernance);
    error OnlyGovernance();

    address public governance;


    modifier onlyGovernance() {
        if (msg.sender == governance) {
            _;
        } else {
            revert OnlyGovernance();
        }
    }

    /**
     * @dev Transfers governance rights to a new address.
     * @param _newGovernance The new governance address.
     */
    function transferGovernance(address _newGovernance) external onlyGovernance {
        governance = _newGovernance;
        emit GovernanceTransferred(governance, _newGovernance);
    }
}