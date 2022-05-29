//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUBIL2.sol";


contract UBIL2 is IUBIL2, ERC20, Ownable {
    mapping(address => uint256) incomingRate;
    mapping(address => uint256) accruedSince;
    address ubiBridge;

    modifier onlyBridge {
        require(msg.sender == ubiBridge, "sender is not bridge");
        _;
    }

    constructor(address pUBIBridge, string memory pName, string memory pSymbol) ERC20(pName, pSymbol) {
        ubiBridge = pUBIBridge;
    }

    function setUBIBridge(address pUBIBridge) public onlyOwner {
        ubiBridge = pUBIBridge;
    }

    /// @dev The balance of the account. Sums consolidated balance + accrued balance.
    function balanceOf(address account) public view override returns(uint256) {
        return super.balanceOf(account) + getAccruedBalance(account);
    }

    /// @dev Accrued balance since last accrual. This is the amount of UBI that has been accrued since the last time the balance consolidated.
    function getAccruedBalance(address account) public view returns(uint256) {
        return (block.timestamp - accruedSince[account]) * incomingRate[account];
    }

    /// @dev Consolidates the balance of the account.
    function consolidateBalance(address account) internal {
        super._mint(account, getAccruedBalance(account));
        accruedSince[account] = block.timestamp;
    }

    /// @dev Adds a specified accrual rate to an account. Only executed by the bridge.
    function addAccrual(address account, uint256 rate) public override onlyBridge {
        require(msg.sender == ubiBridge, "can only be called by bridge");
        consolidateBalance(account);
        incomingRate[account] += rate;
    }

    /// @dev Subtracts a specified accrual rate from an account. Only executed by the bridge.
    function subAccrual(address account, uint256 rate) public override onlyBridge {
        require(msg.sender == ubiBridge, "can only be called by bridge");
        consolidateBalance(account);
        incomingRate[account] -= rate;
    }

    /// @dev Adds the specified balance to the account. Only executed by the bridge.
    function addBalance(address account, uint256 value) public override onlyBridge {
        require(value > 0, "value must be greater than 0");
        super._mint(account, value);
    }
}