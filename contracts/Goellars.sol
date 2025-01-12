pragma solidity 0.5.2;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/openzeppelin-solidity/contracts/access/roles/MinterRole.sol";


contract Goellars is IERC20, MinterRole {
  using SafeMath for uint256;
  
  bytes32 public name;
  bytes32 public symbol;
  uint8 public decimals;

  address public bridgeAddr;
  IERC20 public dai;
  mapping(address => uint256) public daiBalance;

  constructor(address _daiAddr, address _bridgeAddr, bytes32 _name, bytes32 _symbol) public {
    dai = IERC20(_daiAddr);
    bridgeAddr = _bridgeAddr;
    decimals = 18;
    name = _name;
    symbol = _symbol;
  }

  // 1. DAI is pulled into the contract, and record created
  // 2. goellars are minted in amount of DAI deposited
  // 3. goellars transfered to the Bridge
  function _pullAndMint(address from, address to, uint256 value) internal {
    require(dai.transferFrom(from, address(this), value));
    daiBalance[from] = daiBalance[from].add(value);
    _mint(to, value);
  }

  function _transferFrom(address from, address to, uint256 value) internal {
    _transfer(from, to, value);

    // only check allowance if other caller than bridge
    if (to != bridgeAddr) {
      approve(from, _allowed[from][msg.sender].sub(value));
    }
  }

  // +------+         +----------+     +--------+
  // |  DAI |         | goellars |     | Bridge |
  // +---+--+         +----+-----+     +----+---+
  //     |                 |                |
  //     |                 |                |
  //     |                 | transferFrom   |
  //     |  transferFrom   | <------------+ |
  //     | <------------+  |                |
  //     |                 | mint           |
  //     | +------------>  | +--+           |
  //     |                 |    |           |
  //     |                 | <--+           |
  //     |                 |                |
  //     |                 | transfer       |
  //     |                 | +----------->  |
  //     |                 |                |
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    uint256 amountToMint = 0;
    if (_balances[from] < value) {
      amountToMint = value.sub(_balances[from]);
      if (amountToMint > 0) {
        require(msg.sender == bridgeAddr, "pullAndMint only for bridge");
        require(to == bridgeAddr, "pullAndMint only to bridge");
      }
      _pullAndMint(from, msg.sender, amountToMint);
    }
    if (amountToMint < value) {
      if (msg.sender == bridgeAddr || to == bridgeAddr) {
        require(msg.sender == bridgeAddr, "transferFrom only by bridge to bridge");
        require(to == bridgeAddr, "transferFrom only by bridge to bridge 2");
      }
      _transferFrom(from, to, value.sub(amountToMint));
    }
    return true;
  }

  function _burn(address owner) internal {
    uint256 amount = _balances[owner];
    if (!isMinter(owner)) {
      require(daiBalance[owner] > 0);
      if (daiBalance[owner] < amount) {
        amount = daiBalance[owner];
      }
      daiBalance[owner] = daiBalance[owner].sub(amount);
    }
    _burn(owner, amount);
    require(dai.transfer(owner, amount), "dai transfer failed");
  }

  function burnSender() public {
    _burn(msg.sender);
  }

  function addMinter(address _newMinter) public onlyMinter {
    _addMinter(_newMinter);
  }


  // default open zepplin code from here on

  /**
   * @dev Function to mint tokens
   * @param to The address that will receive the minted tokens.
   * @param value The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address to, uint256 value) public onlyMinter returns (bool) {
    _mint(to, value);
    return true;
  }

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
  * @return An uint256 representing the amount owned by the passed address.
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
  * @dev Transfer token for a specified address
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
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * Emits an Approval event.
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * Emits an Approval event.
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
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
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender's allowance for said account. Uses the
   * internal burn function.
   * Emits an Approval event (reflecting the reduced allowance).
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 value) internal {
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
    _burn(account, value);
    emit Approval(account, msg.sender, _allowed[account][msg.sender]);
  }

}