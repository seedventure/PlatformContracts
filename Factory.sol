pragma solidity ^0.5.2;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: d:/SEED/SeedPlatform/contracts/CustomOwnable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract CustomOwnable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
/*    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
*/
    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: D:/SEED/SeedPlatform/contracts/AdminTools.sol

/**
 * @title SetAdministration
 * @dev Base contract implementing a whitelist to keep track of holders and adminitration roles .
 * The construction parameter allow for both whitelisted and non-whitelisted contracts:
 * 1) whitelistThresholdBalance = 0: whitelist enabled, full whitelisting
 * 2) whitelistThresholdBalance > 0: whitelist enabled, partial whitelisting
 * Roles: Owner, Managers and Operators for whitelisting e funding panel
 */
contract AdminTools is CustomOwnable {
    using SafeMath for uint256;

    event LogWLThresholdBalanceChanged(address indexed caller, uint256 indexed whitelistThresholdBalance);
    event LogWLAddressAdded(address indexed caller, address indexed subscriber, uint256 maxAmount);
    event LogWLAddressRemoved(address indexed caller, address indexed subscriber);
    event LogFundingAddressAdded(address indexed caller, address indexed subscriber, uint256 maxAmount);
    event LogFundingAddressRemoved(address indexed caller, address indexed subscriber);


    struct wlVars {
        bool permitted;
        uint256 maxAmount;
    }

    mapping (address => wlVars) private whitelist;

    uint256 private whitelistLength;

    uint256 private whitelistThresholdBalance;

    event WLManagersAdded(address indexed account);
    event WLManagersRemoved(address indexed account);
    event WLOperatorsAdded(address indexed account);
    event WLOperatorsRemoved(address indexed account);
    event FundingManagersAdded(address indexed account);
    event FundingManagersRemoved(address indexed account);
    event FundingOperatorsAdded(address indexed account);
    event FundingOperatorsRemoved(address indexed account);

    mapping (address => bool) private _WLManagers;
    mapping (address => bool) private _FundingManagers;
    mapping (address => bool) private _WLOperators;
    mapping (address => bool) private _FundingOperators;

    address private _minterAddress;

    event MinterChanged(address indexed account);

    address private _ownerWallet;

    event OwnerWalletChanged(address indexed account);

    constructor(uint256 _whitelistThresholdBalance) public {
        _addWLManagers(msg.sender);
        _addWLOperators(msg.sender);
        _addFundingManagers(msg.sender);
        _addFundingOperators(msg.sender);
        //_minterAddress = 0;
        whitelistThresholdBalance = _whitelistThresholdBalance.mul(10**18);
    }

    /* Minter Contract manager */
    function getMinterAddress() public view returns(address){
        return _minterAddress;
    }

    function setMinterAddress(address _minter) public onlyOwner returns(address){
        require(_minter != address(0), "Not valid minter address!");
        require(_minter != _minterAddress, " No change in minter contract");
        _minterAddress = _minter;
        emit MinterChanged(_minterAddress);
        return _minterAddress;
    }

    function getOwnerWallet() public view returns (address) {
        return _ownerWallet;
    }

    function setOwnerWallet(address _wallet) public onlyOwner returns(address){
        require(_wallet != address(0), "Not valid wallet address!");
        require(_wallet != _ownerWallet, " No change in minter contract");
        _ownerWallet = _wallet;
        emit MinterChanged(_ownerWallet);
        return _ownerWallet;
    }
    

    /* Modifiers */
    modifier onlyWLManagers() {
        require(isWLManager(msg.sender));
        _;
    }

    modifier onlyWLOperators() {
        require(isWLOperator(msg.sender));
        _;
    }

    modifier onlyFundingManagers() {
        require(isFundingManager(msg.sender));
        _;
    }

    modifier onlyFundingOperators() {
        require(isFundingOperator(msg.sender));
        _;
    }

    /*   WL Roles Mngmt  */
    function addWLManagers(address account) public onlyOwner {
        _addWLManagers(account);
        _addWLOperators(account);
    }

    function removeWLManagers(address account) public onlyOwner {
        _removeWLManagers(account);
        _removeWLManagers(account);
    }

    function isWLManager(address account) public view returns (bool) {
        return _WLManagers[account];
    }

    function addWLOperators(address account) public onlyWLManagers {
        _addWLOperators(account);
    }

    function removeWLOperators(address account) public onlyWLManagers {
        _addWLOperators(account);
    }

    function renounceWLManager() public onlyWLManagers {
        _removeWLManagers(msg.sender);
    }

    function _addWLManagers(address account) internal {
        _WLManagers[account] = true;
        emit WLManagersAdded(account);
    }

    function _removeWLManagers(address account) internal {
        _WLManagers[account] = false;
        emit WLManagersRemoved(account);
    }


    function isWLOperator(address account) public view returns (bool) {
        return _WLOperators[account];
    }

    function renounceWLOperators() public onlyWLOperators {
        _removeWLOperators(msg.sender);
    }

    function _addWLOperators(address account) internal {
        _WLOperators[account] = true;
        emit WLOperatorsAdded(account);
    }

    function _removeWLOperators(address account) internal {
        _WLOperators[account] = false;
        emit WLOperatorsRemoved(account);
    }


    /*   Funding Roles Mngmt  */
    function addFundingManagers(address account) public onlyOwner {
        _addFundingManagers(account);
        _addFundingOperators(account);
    }

    function removeFundingManagers(address account) public onlyOwner {
        _removeFundingManagers(account);
        _removeFundingManagers(account);
    }

    function isFundingManager(address account) public view returns (bool) {
        return _FundingManagers[account];
    }

    function addFundingOperators(address account) public onlyFundingManagers {
        _addFundingOperators(account);
    }

    function removeFundingOperators(address account) public onlyFundingManagers {
        _addFundingOperators(account);
    }

    function renounceFundingManager() public onlyFundingManagers {
        _removeFundingManagers(msg.sender);
    }

    function _addFundingManagers(address account) internal {
        _FundingManagers[account] = true;
        emit FundingManagersAdded(account);
    }

    function _removeFundingManagers(address account) internal {
        _WLManagers[account] = false;
        emit FundingManagersRemoved(account);
    }


    function isFundingOperator(address account) public view returns (bool) {
        return _FundingOperators[account];
    }

    function renounceFundingOperators() public onlyWLOperators {
        _removeFundingOperators(msg.sender);
    }

    function _addFundingOperators(address account) internal {
        _FundingOperators[account] = true;
        emit FundingOperatorsAdded(account);
    }

    function _removeFundingOperators(address account) internal {
        _FundingOperators[account] = false;
        emit FundingOperatorsRemoved(account);
    }

    /*  Whitelisting  Mngmt  */

    /**
     * @return true if subscriber is whitelisted, false otherwise
     */
    function isWhitelisted(address _subscriber) public view returns(bool) {
        return whitelist[_subscriber].permitted;
    }

    /**
     * @return the anonymous threshold
     */
    function getWLThresholdBalance() public view returns (uint256) {
        return whitelistThresholdBalance;
    }

    /**
     * @return maxAmount for holder
     */
    function getMaxWLAmount(address _subscriber) public view returns(uint256) {
        return whitelist[_subscriber].maxAmount;
    }

    /**
     * @dev length of the whitelisted accounts
     */
    function getWLLength() public view returns(uint256) {
        return whitelistLength;
    }
    
    /**
     * @dev set new anonymous threshold 
     * @param _newThreshold The new anonymous threshold.
     */
    function setNewThreshold(uint256 _newThreshold) public onlyWLManagers {
        require(whitelistThresholdBalance != _newThreshold, "New Threshold like the old one!");
        //require(_newThreshold != getWLThresholdBalance(), "NewMax equal to old MaxAmount");
        whitelistThresholdBalance = _newThreshold;
        emit LogWLThresholdBalanceChanged(msg.sender, whitelistThresholdBalance);
    }

    /**
     * @dev Change maxAmount for holder
     * @param _subscriber The subscriber in the whitelist.
     * @param _newMaxToken New max amount that a subscriber can hold (in set tokens).
     */
    function changeMaxWLAmount(address _subscriber, uint256 _newMaxToken) public onlyWLOperators {
        require(isWhitelisted(_subscriber), "Investor is not whitelisted!");
        whitelist[_subscriber].maxAmount = _newMaxToken;
    }

    /**
     * @dev Add the subscriber to the whitelist.
     * @param _subscriber The subscriber to add to the whitelist.
     * @param _maxAmnt max amount that a subscriber can hold (in set tokens).
     */
    function addToWhitelist(address _subscriber, uint256 _maxAmnt) public onlyWLOperators {
        require(_subscriber != address(0), "_subscriber is zero");
        require(!whitelist[_subscriber].permitted, "already whitelisted");

        whitelistLength++;

        whitelist[_subscriber].permitted = true;
        whitelist[_subscriber].maxAmount = _maxAmnt;

        emit LogWLAddressAdded(msg.sender, _subscriber, _maxAmnt);
    }

    /**
     * @dev Remove the subscriber to the whitelist.
     * @param _subscriber The subscriber to add to the whitelist.
     * @param _balance balance of a subscriber to be under the anonymous threshold, otherwise de-whilisting not permitted.
     */
    function removeFromWhitelist(address _subscriber, uint256 _balance) public onlyWLOperators {
        require(_subscriber != address(0), "_subscriber is zero");
        require(whitelist[_subscriber].permitted, "not whitelisted");
        require(_balance <= whitelistThresholdBalance, "_balance greater than whitelist threshold");

        whitelistLength--;

        whitelist[_subscriber].permitted = false;
        whitelist[_subscriber].maxAmount = 0;

        emit LogWLAddressRemoved(msg.sender, _subscriber);
    }

}

// File: D:/SEED/SeedPlatform/node_modules/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://eips.ethereum.org/EIPS/eip-20
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token to a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

// File: d:/SEED/SeedPlatform/contracts/IToken.sol

/**
 * @title SetToken interface
 */
interface IToken { 

    function checkTransferAllowed (address from, address to, uint256 value) external view returns (byte);
   
    function checkTransferFromAllowed (address from, address to, uint256 value) external view returns (byte);
   
    function checkMintAllowed (address to, uint256 value) external pure returns (byte);

    function checkBurnAllowed (address from, uint256 value) external pure returns (byte);    
}

// File: D:/SEED/SeedPlatform/contracts/Token.sol

contract Token is IToken, ERC20, CustomOwnable {

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    AdminTools private ATContract;
    address private ATAddress;

    byte private constant STATUS_ALLOWED = 0x11;
    byte private constant STATUS_DISALLOWED = 0x10;

    constructor(string memory name, string memory symbol, address _ATAddress) public {  // cap?
        _name = name;
        _symbol = symbol;
        _decimals = 18;
        ATAddress = _ATAddress;
        ATContract = AdminTools(ATAddress);
    }

    modifier onlyMinterAddress() {
        require(ATContract.getMinterAddress() == msg.sender, "Address can not mint!");
        _;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(checkTransferAllowed(msg.sender, _to, _value) == STATUS_ALLOWED, "transfer must be allowed");
        return ERC20.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(checkTransferFromAllowed(_from, _to, _value) == STATUS_ALLOWED, "transfer must be allowed");
        return ERC20.transferFrom(_from, _to,_value);
    }

    function mint(address _account, uint256 _amount) public onlyMinterAddress {
        require(checkMintAllowed(_account, _amount) == STATUS_ALLOWED, "mint must be allowed");
        ERC20._mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) public {
        require(checkBurnAllowed(_account, _amount) == STATUS_ALLOWED, "burn must be allowed");
        ERC20._burn(_account, _amount);
    }

    function okToTransferTokens(address _holder, uint256 _amountToAdd) public view returns (bool){
        uint256 holderBalanceToBe = balanceOf(_holder) + _amountToAdd;
        bool okToTransfer = ATContract.isWhitelisted(_holder) && holderBalanceToBe <= ATContract.getMaxWLAmount(_holder) ? true :
                          holderBalanceToBe <= ATContract.getWLThresholdBalance() ? true : false;
        return okToTransfer;
    }

    function checkTransferAllowed (address _sender, address _receiver, uint256 _amount) public view returns (byte) {
        require( balanceOf(_sender) >= _amount, "Sender does not have enough tokens!" );
        require( okToTransferTokens(_receiver, _amount), "Receiver not allowed to perform transfer!" );
        return STATUS_ALLOWED;
    }
   
    function checkTransferFromAllowed (address _sender, address _receiver, uint256 _amount) public view returns (byte) {
        require( balanceOf(_sender) >= _amount, "Sender does not have enough tokens!" );
        require( okToTransferTokens(_receiver, _amount), "Receiver not allowed to perform transfer!" );
        return STATUS_ALLOWED;
    }
   
    function checkMintAllowed (address, uint256) public pure returns (byte) {
        //require(ATContract.isOperator(_minter), "Not Minter!");
        return STATUS_ALLOWED;
    }
   
    function checkBurnAllowed (address, uint256) public pure returns (byte) {
        // default
        return STATUS_ALLOWED;
    }

    function withdraw() public onlyOwner returns (bool) {
        msg.sender.transfer(address(this).balance);
        return true;
    }

}

// File: D:/SEED/SeedPlatform/contracts/FundingPanel.sol

//import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
//import "openzeppelin-solidity/contracts/ownership/Ownable.sol";



/*
Selezione: impostazione voting con contratto esterno su balanceof per lista holders con diritto di voto
*/

contract FundingPanel is CustomOwnable {
    using SafeMath for uint256;

    // address private owner;
    string private setDocURL;
    string private setDocHash;
    //bytes32 private setDocHash;

    address private seedAddress;
    ERC20 private seedToken;
    Token private token;
    address private tokenAddress;
    AdminTools private ATContract;
    address private ATAddress;

    uint256 private seedMaxSupply;  // can it be changed?

    uint256 private exchangeRateSeed;
    uint8 private exchRateDecimals;
    uint256 private exchangeRateOnTop;

    uint private deployBlock;

    struct infoMember {
        bool isInserted;
        bool enabled; 
        string memberURL; 
        string memberHash; 
        //bytes32 memberHash;
        uint listPointer;
    }
    mapping(address => infoMember) private membersArray; // mapping of members
    address[] membersList; //array for counting or accessing in a sequencialing way the members

    constructor(string memory _setDocURL, 
                string memory _setDocHash, 
                uint256 _exchRateSeed, 
                uint256 _seedMaxSupply, 
                uint256 _exchRateOnTop,
                uint8 _exchRateDecim,
                address _seedTokenAddress, 
                address _tokenAddress,
                address _ATAddress) public {
        setDocURL = _setDocURL;
        setDocHash = _setDocHash;

        exchangeRateSeed = _exchRateSeed;
        exchangeRateOnTop = _exchRateOnTop;
        exchRateDecimals = _exchRateDecim;

        uint256 multiplier = 10 ** 18;
        seedMaxSupply = _seedMaxSupply.mul(uint256(multiplier));

        tokenAddress = _tokenAddress;
        ATAddress = _ATAddress;
        seedAddress = _seedTokenAddress;
        seedToken = ERC20(seedAddress);
        token = Token(tokenAddress);
        ATContract = AdminTools(ATAddress);

        deployBlock = block.number;  // block number that creates the contract
    }


/**************** Modifiers ***********/

    modifier onlyMemberEnabled() {
        require(membersArray[msg.sender].isInserted && membersArray[msg.sender].enabled, "Member not present or not enabled");
        _;
    }

    modifier whitelistedOnly(address holder) {
        require(ATContract.isWhitelisted(holder), "Investor is not whitelisted!");
        _;
    }

    modifier holderEnabledInSeeds(address _holder, uint256 _seedAmountToAdd) {
        uint256 amountInTokens = getTokenExchangeAmount(_seedAmountToAdd);
        uint256 holderBalanceToBe = token.balanceOf(_holder) + amountInTokens;
        bool okToInvest = ATContract.isWhitelisted(_holder) && holderBalanceToBe <= ATContract.getMaxWLAmount(_holder) ? true :
                          holderBalanceToBe <= ATContract.getWLThresholdBalance() ? true : false;
        require(okToInvest, "Investor not allowed to perform operations!");
        _;
    }

    modifier onlyFundingOperator() {
        require(ATContract.isFundingOperator(msg.sender));
        _;
    }

    /**
     * @dev operator members can change the set token address
     */
    function changeToken(address _setTokenAddress) public onlyFundingOperator {
        require(_setTokenAddress != address(0), "Invalid Address");
        require(_setTokenAddress == tokenAddress, "No new set Token address");
        tokenAddress = _setTokenAddress;
        token = Token(tokenAddress);
    }

    /**
     * @dev find if a member is inserted
     * @return bool for success
     */
    function isMemberInserted(address memberWallet) public view returns(bool isIndeed) {
        return membersArray[memberWallet].isInserted;
    }

    /**
     * @dev only operator members can add a member
     * @return bool for success
     */
    function addMemberToSet(address memberWallet, bool enabled, string memory memberURL, string memory memberHash) public onlyFundingOperator returns (bool) {
        require(!isMemberInserted(memberWallet), "Member already inserted!");
        uint memberPlace = membersList.push(memberWallet) - 1;
        infoMember memory tmpStUp = infoMember(true, enabled, memberURL, memberHash, memberPlace); 
        membersArray[memberWallet] = tmpStUp;
        return true;
    }

    /**
     * @dev only operator members can delete a member
     * @return bool for success
     */
    function deleteMemberFromSet(address memberWallet) public onlyFundingOperator returns (bool) {
        require(isMemberInserted(memberWallet), "Member to delete not found!");
        uint rowToDelete = membersArray[memberWallet].listPointer;
        address keyToMove = membersList[membersList.length-1];
        membersList[rowToDelete] = keyToMove;
        membersArray[keyToMove].listPointer = rowToDelete;
        membersList.length--;
        return true;
    }

    /**
     * @return get the number of inserted members in the set
     */
    function getMemberNumber() public view returns (uint) {
        return membersList.length;
    }

    /**
     * @dev only operator memebers can enable a member
     */
    function enableMember(address _memberAddress) public onlyFundingOperator {
        require(membersArray[_memberAddress].isInserted, "Member not present"); 
        membersArray[_memberAddress].enabled = true;
    }

    /**
     * @dev operator members can disable an already inserted member
     */
    function disableMemberByStaff(address _memberAddress) public onlyFundingOperator {
        require(membersArray[_memberAddress].isInserted, "Member not present"); 
        membersArray[_memberAddress].enabled = false;
    }

    /**
     * @dev member can disable itself if already inserted and enabled 
     */
    function disableMemberByMember(address _memberAddress) public onlyMemberEnabled {
        membersArray[_memberAddress].enabled = false;
    }

    /**
     * @dev operator members can change URL of an already inserted member
     */
    function changeMemberURLByStaff(address _memberAddress, string memory newURL) public onlyFundingOperator {
        require(membersArray[_memberAddress].isInserted, "Member not present"); 
        membersArray[_memberAddress].memberURL = newURL;
    }

    /**
     * @dev member can change URL by itself if already inserted and enabled 
     */
    function changeMemberURLByMember(address _memberAddress, string memory newURL) public onlyMemberEnabled {
        membersArray[_memberAddress].memberURL = newURL;
    }

    /**
     * @dev operator members can change hash of an already inserted member
     */
    function changeMemberHashByStaff(address _memberAddress, string memory newHash) public onlyFundingOperator {
        require(membersArray[_memberAddress].isInserted, "Member not present"); 
        membersArray[_memberAddress].memberHash = newHash;
    }

    /**
     * @dev member can change hash by itself if already inserted and enabled 
     */
    function changeMemberHashByMember(address _memberAddress, string memory newHash) public onlyMemberEnabled {
        membersArray[_memberAddress].memberURL = newHash;
    }

    /**
     * @dev operator members can change the rate exchange of the set
     */
    function changeTokenExchangeAmount(uint256 newExchRate) external onlyFundingOperator {
        require(newExchRate > 0, "Wrong exchange rate!");
        exchangeRateSeed = newExchRate;
    }

    /** 
     * @dev Shows the amount of tokens the user will receive for amount of Seed token
     * @param _Amount Exchanged seed tokens amount to convert
     * @return The amount of token that will be received
     */
    function getTokenExchangeAmount(uint256 _Amount) internal view returns(uint256) {
        require(_Amount > 0);
        return _Amount.mul(exchangeRateSeed).div(10 ** uint256(exchRateDecimals));
    }

    /** 
     * @dev Shows the amount of token the owner will receive for amount of Seed token
     * @param _Amount Exchanged chong amount to convert
     * @return The amount of set Token that will be received
     */
    function getTokenExchangeAmountOnTop(uint256 _Amount) internal view returns(uint256) {
        require(_Amount > 0);
        return _Amount.mul(exchangeRateOnTop).div(10 ** uint256(exchRateDecimals));
    }

    /**
     * @return get the set token address
     */
    function getTokenAddress() public view returns (address) {
        return tokenAddress;
    }

    /**
     * @return get the operator members URL and hash
     */
    function getOwnerData() public view returns (string memory, string memory) {
        return (setDocURL, setDocHash);
    }

    /**
     * @dev get the max Supply of SEED
     */
    function getSeedMaxSupply() public view returns (uint256) {
        return seedMaxSupply;
    }

    /**
     * @dev change the max Supply of SEED
     */
    function setNewSeedMaxSupply(uint256 _newMaxSeedSupply) public returns (uint256) {
        seedMaxSupply = _newMaxSeedSupply;
        return seedMaxSupply;
    }
 
    /**
     * @return get the number of Seed token inside the contract
     */
    function getTotalRaised() public view returns (uint256) {
        return seedToken.balanceOf(address(this));
    }

    /**
     * @dev get the number of Seed token inside the contract an mint new tokens
     * @notice owner has to mint and approve transfer the tokens BEFORE holders call this function
     */
    function holderSendSeeds(uint256 _seeds) public holderEnabledInSeeds(msg.sender, _seeds) {
        require(seedToken.balanceOf(address(this)) + _seeds <= seedMaxSupply, "Maximum supply reached!");
        require(seedToken.balanceOf(msg.sender) >= _seeds, "Not enough seeds in holder wallet");
        address walletOnTop = ATContract.getOwnerWallet();
        require(ATContract.isWhitelisted(walletOnTop), "Owner wallet not whitelisted");

        //apply conversion seed/set token
        uint256 amount = getTokenExchangeAmount(_seeds);
        seedToken.transferFrom(msg.sender, address(this), _seeds);
        token.mint(msg.sender, amount);

        uint256 amountOnTop = getTokenExchangeAmountOnTop(_seeds);
        token.mint(walletOnTop, amountOnTop);
    }

    /**
     * @dev Funds unlock by operator members 
     */
     function unlockFunds(address memberWallet, uint256 amount) external onlyFundingOperator {
         require(seedToken.balanceOf(address(this)) >= amount, "Not enough seeds to unlock!");
         require(membersArray[memberWallet].isInserted && membersArray[memberWallet].enabled, "Member not present or not enabled");
         seedToken.transferFrom(address(this), memberWallet, amount);
     }

}

// File: contracts\Factory.sol

contract Factory {

    // index of created contracts 
    address[] public AdminToolsContracts;
    address[] public TokenContracts;
    address[] public FundingPanelContracts;
    //mapping(address => address) counters;

    address lastATContract;
    address lastTokenContract;
    address lastFundingPanelContract;

    // useful to know the row count in contracts index
    function getAdminToolsContractCount() public view returns(uint contractCount) {
        return AdminToolsContracts.length;
    }

    // deploy a new AdminTools contract
    function newAdminTools() public returns(address newContract) {
        AdminTools c = new AdminTools(0);
        lastATContract = address(c);
        AdminToolsContracts.push(lastATContract);
        return lastATContract;
    }
}
