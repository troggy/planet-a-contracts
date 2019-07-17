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
  
  uint256 constant CO2_TO_GOELLARS_FACTOR = 1000;
  uint256 constant LOW_TO_HIGH_FACTOR = 4;

  function getGoellars(bool isDefectA, bool isDefectB, uint256 lowCO2) internal view returns (uint256) {
    if (isDefectA) {
      if (isDefectB) {
        return (lowCO2 / CO2_TO_GOELLARS_FACTOR);
      } else {
        return (lowCO2 / CO2_TO_GOELLARS_FACTOR) * LOW_TO_HIGH_FACTOR;
      }
    } else {
      if (isDefectB) {
        return (lowCO2 / CO2_TO_GOELLARS_FACTOR) * LOW_TO_HIGH_FACTOR;
      } else {
        return (lowCO2 / CO2_TO_GOELLARS_FACTOR);
      }
    }
  }

  function getCo2B(bool isDefectB, uint256 lowCO2) internal view returns (uint256) {
    if (isDefectB) {
      return lowCO2 * LOW_TO_HIGH_FACTOR;
    } else {
      return lowCO2;
    }
  }

  // (CO2mintedBefore - CO2mintedAfter) = co2Amount
  // (CO2lockedBefore - CO2lockedAfter) > 0 ? collaborate : defect
  // 
  function trade(
    uint256 passportA,
    bytes32 passDataAfter, 
    bytes memory sigA,
    uint256 passportB,
    bool isDefectB,
    address countryAaddr,
    address countryBaddr
  ) public {
    // calculate payout for A
    IERC1948 countryA = IERC1948(countryAaddr);
    bytes32 passDataBefore = countryA.readData(passportA);
    uint256 lowCO2 = uint256(uint32(uint256(passDataAfter)) - uint32(uint256(passDataBefore)));
    bool isDefectA = false;

    if ((uint256(passDataAfter) - uint256(passDataBefore) == lowCO2) {
      // if CO2locked unchanged, then consider defect by player 1
      lowCO2 = lowCO2 / LOW_TO_HIGH_FACTOR;
      isDefectA = true;
    }

    // pay out trade        
    IERC20 dai = IERC20(DAI);
    dai.transfer(countryA.ownerOf(passportA), getGoellars(isDefectA, isDefectB, lowCO2));
    IERC1948 countryB = IERC1948(countryBaddr);
    dai.transfer(countryB.ownerOf(passportB), getGoellars(isDefectA, isDefectB, lowCO2));
    
    // update passports
    countryA.writeDataByReceipt(passportA, passDataAfter, sigA);
    bytes32 dataB = countryB.readData(passportB);
    countryB.writeData(passportB, bytes32(uint256(dataB) + getCo2B(isDefectB, lowCO2)));

    // emit CO2
    IERC20 co2 = IERC20(CO2);
    co2.transfer(AIR_ADDR, getCo2B(isDefectB, lowCO2) + uint256(uint32(uint256(passDataAfter)) - uint32(uint256(passDataBefore))));
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