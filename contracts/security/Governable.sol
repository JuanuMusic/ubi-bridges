//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Governable {
    error OnlyGovernance();
    error OnlyGovernanceCandidate();

    event GovernanceTransferInitialized(address indexed currentGovernance, address indexed governanceCandidate);
    event GovernanceTransferred(address indexed oldGovernance, address indexed newGovernance);

    address public governance;
    address public governanceCandidate;

    modifier onlyGovernance() {
        if (msg.sender == governance) {
            _;
        } else {
            revert OnlyGovernance();
        }
    }

    /**
     * @dev Transfers governance rights to a new address.
     * @param _governanceCandidate The new governance address.
     */
    function initGovernanceTransfer(address _governanceCandidate) external onlyGovernance {
        governanceCandidate = _governanceCandidate;
        emit GovernanceTransferInitialized(governance, _governanceCandidate);
    }

    /**
     * @dev Transfers governance rights to a new address.
     */
    function confirmGovernanceTransfer() external {
        address newGovernance = governanceCandidate;
        if (msg.sender == newGovernance) {
            _transferGovernance(governanceCandidate);
        } else {
            revert OnlyGovernanceCandidate();
        }
    }

    /**
     * @dev Transfers governance rights to a new address.
     * @param _newGovernance The new governance address.
     */
    function _transferGovernance(address _newGovernance) internal {
        emit GovernanceTransferred(governance, _newGovernance);
        governance = _newGovernance;
    }
}
