/**
 * Copyright (c) 2019-present, Social Dist0rtion Protocol
 *
 * This source code is licensed under the Mozilla Public License, version 2,
 * found in the LICENSE file in the root directory of this source tree.
 */
pragma solidity ^0.5.2;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/cryptography/ECDSA.sol";
import "./IERC1948.sol";

contract Earth {
  using ECDSA for bytes32;

  address constant CO2 = 0x1231111111111111111111111111111111111123;
  address constant DAI = 0x2341111111111111111111111111111111111234;
  // CO2 flows from Earth to Air and maybe back. This is the address of the
  // air contract.
  address constant AIR_ADDR = 0x4561111111111111111111111111111111111456;
  
  function trade(
    uint256 passportA,
    bytes32 passDataAfter, 
    bytes memory sigA,
    uint256 passportB,
    uint32 factorB,
    address countryAaddr,
    address countryBaddr
  ) public {
    // calculate payout for A
    IERC1948 countryA = IERC1948(countryAaddr);
    bytes32 passDataBefore = countryA.readData(passportA);
    uint256 factorA = uint256(passDataAfter) - uint256(passDataBefore);
    // TODO calculate factor B

    // pay out trade        
    IERC20 dai = IERC20(DAI);
    // TODO: apply formula
    dai.transfer(countryA.ownerOf(passportA), factorA);
    IERC1948 countryB = IERC1948(countryBaddr);
    dai.transfer(countryB.ownerOf(passportB), uint256(factorB));
    
    // TODO: apply formula
    countryA.writeDataByReceipt(passportA, passDataAfter, sigA);
    bytes32 dataB = countryB.readData(passportB);
    countryB.writeData(passportB, bytes32(uint256(dataB) + uint256(factorB)));

    // emit CO2
    if (factorA > 100 || factorB > 100) {
      IERC20 co2 = IERC20(CO2);
      // TODO: apply formula
      co2.transfer(AIR_ADDR, factorA + factorB);
    }
  }

  // account used as game master.
  address constant GAME_MASTER = 0x5671111111111111111111111111111111111567;

  // used to model natural increase of CO2 if above run-away point.
  // question: temprature will increase, but will CO2 increase as well?
  function unlockCO2(uint256 amount, bytes memory sig) public {
    address signer = bytes32(bytes20(address(this))).recover(sig);
    require(signer == GAME_MASTER, "signer does not match");
    // unlock CO2
    IERC20 co2 = IERC20(CO2);
    co2.transfer(AIR_ADDR, amount);
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