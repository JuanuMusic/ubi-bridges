//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../security/Governable.sol";
//import "./ChildMintableERC20.sol";
import "../interfaces/IUBIL2.sol";
import "../BaseUBI.sol";
import "./UBIPolygonChildTunnel.sol";

error NotChildTunnel();

contract UBIPolygon is IUBIL2, BaseUBI, Governable {

    address public childTunnel;

    modifier onlyChildTunnel {
        if(msg.sender != childTunnel) revert NotChildTunnel();
        _;
    }

    constructor(address pChildTunnel) {
            childTunnel = pChildTunnel;   
    }

    function setchildTunnel(address pchildTunnel) public onlyGovernance {
        childTunnel = pchildTunnel;
    }

    /// @dev Adds a specified accrual rate to an account. Only executed by the bridge.
    function addAccrual(address account, uint256 rate) public override onlyChildTunnel {    
        super._addAccrual(account, rate);
    }

    /// @dev Subtracts a specified accrual rate from an account. Only executed by the bridge.
    function subAccrual(address account, uint256 rate) public override onlyChildTunnel {
        super._subAccrual(account, rate);
    }

    /// @dev Consolidates the balance of the account.
    function mint(address account, uint256 amount) external override onlyChildTunnel {
        super._mint(account, accruedBalanceOf(account) + amount);
        accountInfo[account].accruedSince = block.timestamp;
    }

    function cancelDelegation(uint256 tokenId, uint256 ratePerSecond) external {
        UBIPolygonChildTunnel(childTunnel).onCancelDelegation(msg.sender, tokenId, ratePerSecond);
    }
}