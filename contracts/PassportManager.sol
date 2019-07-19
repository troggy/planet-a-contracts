/**
 * Copyright (c) 2019-present, Social Dist0rtion Protocol
 *
 * This source code is licensed under the Mozilla Public License, version 2,
 * found in the LICENSE file in the root directory of this source tree.
 */
pragma solidity ^0.5.2;
import "./IERC1948.sol";

contract PassportManager {

  bytes32 constant LOCK_MAP = 0xffffffffffffffffffffffffffffffffffffffffffffffff00000000ffffffff;
  bytes32 constant PIC_MAP = 0xffffffffffffffffffffffffffffffffffffffff00000000ffffffffffffffff;

  function addLocked(bytes32 prevData, uint32 more) internal pure returns (bytes32 rv) {
    uint32 locked = uint32(uint256(prevData) >> 32);
    uint32 sum = locked + more;
    require(sum > locked, "buffer overflow");
    rv = LOCK_MAP & prevData;
    rv = rv | bytes32(uint256(sum) << 32);
  }
  
  function setName(uint160 newName, address countryAddr, uint256 passport) public {
    IERC1948 country = IERC1948(countryAddr);
    bytes32 data = country.readData(passport);
    country.writeData(passport, bytes32(uint256(newName) << 96 | uint256(uint96(uint256(data)))));
  }

  function setPic(uint32 newPicId, address countryAddr, uint256 passport) public {
    IERC1948 country = IERC1948(countryAddr);
    bytes32 data = country.readData(passport);
    country.writeData(passport, PIC_MAP & data | bytes32(uint256(newPicId) << 64));
  }

  function addLockedCo2(uint32 amount, address countryAddr, uint256 passport) public {
    IERC1948 country = IERC1948(countryAddr);
    bytes32 data = country.readData(passport);
    country.writeData(passport, addLocked(data, amount));
  }

  function addEmittedCo2(uint32 amount, address countryAddr, uint256 passport) public {
    IERC1948 country = IERC1948(countryAddr);
    bytes32 data = country.readData(passport);
    uint32 newAmount = uint32(uint256(data)) + amount;
    country.writeData(passport, bytes32((uint256(data) >> 32) << 32 & newAmount));
  }

}