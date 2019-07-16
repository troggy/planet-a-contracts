/**
 * Copyright (c) 2019-present, Social Dist0rtion Protocol
 *
 * This source code is licensed under the Mozilla Public License, version 2,
 * found in the LICENSE file in the root directory of this source tree.
 */
pragma solidity ^0.5.2;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./IERC1948.sol";
import "openzeppelin-solidity/contracts/cryptography/ECDSA.sol";

contract Air {
  using ECDSA for bytes32;

  bytes32 constant LOCK_MAP = 0xffffffffffffffffffffffffffffffffffffffffffffffff00000000ffffffff;
  address constant CO2 = 0x1231111111111111111111111111111111111123;
  address constant DAI = 0x2341111111111111111111111111111111111234;

  function getLocked(bytes32 data) internal pure returns (uint32) {
    return uint32(uint256(data) >> 32);
  }

  function addLocked(bytes32 prevData, uint32 more) internal pure returns (bytes32 rv) {
    uint32 locked = getLocked(prevData);
    uint32 sum = locked + more;
    require(sum > locked, "buffer overflow");
    rv = LOCK_MAP & prevData;
    rv = rv | bytes32(uint256(sum) << 32);
  }
  
  function plantTree(
    uint256 amount,
    address countryAddr,
    uint256 passport,
    address earthAddr) public {

    // signer information
    IERC1948 country = IERC1948(countryAddr);
    address signer = country.ownerOf(passport);

    // pull payment
    IERC20 dai = IERC20(DAI);
    uint256 allowance = dai.allowance(signer, address(this));
    require(allowance >= amount, "no funds allocated");
    dai.transferFrom(signer, address(this), amount);
    
    // update passports
    bytes32 data = country.readData(passport);
    // TODO: apply formula
    country.writeData(passport, addLocked(data, uint32(amount)));

    // lock CO2
    IERC20 co2 = IERC20(CO2);
    co2.transfer(earthAddr, amount);
  }

  // account used as game master.
  address constant GAME_MASTER = 0x5671111111111111111111111111111111111567;

  // used to model natural reduction of CO2 if below run-away point
  function lockCO2(uint256 amount, address earthAddr, bytes memory sig) public {
    address signer = bytes32(bytes20(address(this))).recover(sig);
    require(signer == GAME_MASTER, "signer does not match");
    // lock CO2
    IERC20 co2 = IERC20(CO2);
    co2.transfer(earthAddr, amount);
  }

  // used to combine multiple contract UTXOs into one.
  function consolidate(bytes memory sig) public {
    address signer = bytes32(bytes20(address(this))).recover(sig);
    require(signer == GAME_MASTER, "signer does not match");
    // lock CO2
    IERC20 co2 = IERC20(CO2);
    uint256 amount = co2.balanceOf(address(this));
    co2.transfer(address(this), amount);
  }
}