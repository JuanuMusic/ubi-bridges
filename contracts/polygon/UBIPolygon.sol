//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../security/Governable.sol";
//import "./ChildMintableERC20.sol";
import "../interfaces/IUBIL2.sol";
import "./UBIPolygonChildTunnel.sol";

error NotChildTunnel();

contract UBIPolygon is IUBIL2, ERC20, Governable {

    struct AccountInfo {
        uint256 accruedSince;
        uint256 incomingRate;
    }
    mapping(address => AccountInfo) public accountInfo;

    address public childTunnel;

    event AccrualIncreased(address indexed sender, uint256 rate);
    event AccrualDecreased(address indexed sender, uint256 rate);

    modifier onlyChildTunnel {
        if(msg.sender != childTunnel) revert NotChildTunnel();
        _;
    }

    constructor(address pChildTunnel) ERC20("Universal Basic Income", "UBI") {
            childTunnel = pChildTunnel;   
    }

    function setchildTunnel(address pchildTunnel) public onlyGovernance {
        childTunnel = pchildTunnel;
    }

    /// @dev The balance of the account. Sums consolidated balance + accrued balance.
    function balanceOf(address account) public view override returns(uint256) {
        return super.balanceOf(account) + accruedBalanceOf(account);
    }

    /// @dev Accrued balance since last accrual. This is the amount of UBI that has been accrued since the last time the balance consolidated.
    function accruedBalanceOf(address account) public view returns(uint256) {
        if(accountInfo[account].accruedSince == 0) {
            return 0;
        }
        return (block.timestamp - accountInfo[account].accruedSince) * accountInfo[account].incomingRate;
    }

    /// @dev Consolidates the balance of the account.
    function consolidateBalance(address account) internal {
        super._mint(account, accruedBalanceOf(account));
        accountInfo[account].accruedSince = block.timestamp;
    }

    /// @dev Adds a specified accrual rate to an account. Only executed by the bridge.
    function addAccrual(address account, uint256 rate) public override onlyChildTunnel {    
        consolidateBalance(account);
        accountInfo[account].incomingRate += rate;
        emit AccrualIncreased(account, rate);
    }

    /// @dev Subtracts a specified accrual rate from an account. Only executed by the bridge.
    function subAccrual(address account, uint256 rate) public override onlyChildTunnel {
        consolidateBalance(account);
        accountInfo[account].incomingRate -= rate;
        emit AccrualDecreased(account, rate);
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