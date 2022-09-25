//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../security/Governable.sol";
import "./ChildMintableERC20.sol";
import "../interfaces/IUBIL2.sol";


contract UBIPolygon is IUBIL2, ChildMintableERC20, Governable {
    struct AccountInfo {
        uint256 incomingRate;
        uint256 accruedSince;
    }
    mapping(address => AccountInfo) public accountInfo;

    address public ubiBridge;

    event AccrualIncreased(address indexed sender, uint256 rate);
    event AccrualDecreased(address indexed sender, uint256 rate);

    modifier onlyBridge {
        require(ubiBridge != address(0), "ubiBridge not set");
        require(msg.sender == ubiBridge, "sender is not bridge");
        _;
    }

    constructor(string memory pName,
        string memory pSymbol,
        address pChildChainManager) ChildMintableERC20(pName, pSymbol, pChildChainManager) {   
    }

    function setUBIBridge(address pUBIBridge) public onlyGovernance {
        ubiBridge = pUBIBridge;
    }

    /// @dev The balance of the account. Sums consolidated balance + accrued balance.
    function balanceOf(address account) public view override returns(uint256) {
        return super.balanceOf(account) + getAccruedBalance(account);
    }

    /// @dev Accrued balance since last accrual. This is the amount of UBI that has been accrued since the last time the balance consolidated.
    function getAccruedBalance(address account) public view returns(uint256) {
        if(accountInfo[account].accruedSince == 0) {
            return 0;
        }
        return (block.timestamp - accountInfo[account].accruedSince) * accountInfo[account].incomingRate;
    }

    /// @dev Consolidates the balance of the account.
    function consolidateBalance(address account) internal {
        super._mint(account, getAccruedBalance(account));
        accountInfo[account].accruedSince = block.timestamp;
    }

    /// @dev Adds a specified accrual rate to an account. Only executed by the bridge.
    function addAccrual(address account, uint256 rate) public override onlyBridge {
        require(msg.sender == ubiBridge, "can only be called by bridge");
        consolidateBalance(account);
        accountInfo[account].incomingRate += rate;
        emit AccrualIncreased(account, rate);
    }

    /// @dev Subtracts a specified accrual rate from an account. Only executed by the bridge.
    function subAccrual(address account, uint256 rate) public override onlyBridge {
        require(msg.sender == ubiBridge, "can only be called by bridge");
        consolidateBalance(account);
        accountInfo[account].incomingRate -= rate;
        emit AccrualDecreased(account, rate);
    }

    /// @dev Adds the specified balance to the account. Only executed by the bridge.
    function addBalance(address account, uint256 value) public override onlyBridge {
        require(value > 0, "value must be greater than 0");
        super._mint(account, value);
    }

    /// @dev Adds the specified balance to the account. Only executed by the bridge.
    function subBalance(address account, uint256 value) public override onlyBridge {
        require(balanceOf(account) - value >= 0, "value lowerthan zero");
        super._burn(account, value);
    }

    function moveBalanceToL1(uint256 balanace) public override {

    }
}