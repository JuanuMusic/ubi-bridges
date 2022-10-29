import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BaseUBI is ERC20 {
    struct AccountInfo {
        uint256 accruedSince;
        uint256 incomingRate;
    }

    mapping(address => AccountInfo) public accountInfo;

    event AccrualIncreased(address indexed sender, uint256 rate);
    event AccrualDecreased(address indexed sender, uint256 rate);

    constructor() ERC20("Universal Basic Income", "UBI") {}

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
    function _consolidateBalance(address account) internal {
        super._mint(account, accruedBalanceOf(account));
        accountInfo[account].accruedSince = block.timestamp;
    }

    /// @dev Adds a specified accrual rate to an account. Only executed by the bridge.
    function _addAccrual(address account, uint256 rate) internal {    
        _consolidateBalance(account);
        accountInfo[account].incomingRate += rate;
        emit AccrualIncreased(account, rate);
    }

    /// @dev Subtracts a specified accrual rate from an account. Only executed by the bridge.
    function _subAccrual(address account, uint256 rate) internal {
        _consolidateBalance(account);
        accountInfo[account].incomingRate -= rate;
        emit AccrualDecreased(account, rate);
    }
}