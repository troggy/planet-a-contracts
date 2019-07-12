/**
 * Copyright (c) 2019-present, Social Dist0rtion Protocol
 *
 * This source code is licensed under the Mozilla Public License, version 2,
 * found in the LICENSE file in the root directory of this source tree.
 */
const chai = require('chai');
const ethUtil = require('ethereumjs-util');
const Earth = artifacts.require('./Earth.sol');
const SimpleToken = artifacts.require('./mocks/SimpleToken');
const ERC1948 = artifacts.require('./mocks/ERC1948');

const should = chai
  .use(require('chai-as-promised'))
  .should();

function replaceAll(str, find, replace) {
    return str.replace(new RegExp(find, 'g'), replace.replace('0x', ''));
}


contract('Earth Contract', (accounts) => {
  const citizenA = accounts[1];
  const citizenB = accounts[2];
  const air = accounts[3];
  const citizenAPriv = '0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501201';
  const zero = '0000000000000000000000000000000000000000000000000000000000000000';
  const factorA = '00000000000000000000000000000000000000000000000000000000000000ff';
  const passportA = 123;
  const passportB = 234;
  let goellars;
  let co2;
  let passports;
  let originalByteCode;

  before(async () => {
    goellars = await SimpleToken.new();
    co2 = await SimpleToken.new();
    passports = await ERC1948.new();
    originalByteCode = Earth._json.bytecode;
  });

  afterEach(() => {
    Earth._json.bytecode = originalByteCode;
  });

  it('should allow to shake', async () => {

    // deploy earth
    let tmp = Earth._json.bytecode;
    // replace token address placeholder to real token address
    tmp = replaceAll(tmp, '1231111111111111111111111111111111111123', co2.address);
    tmp = replaceAll(tmp, '2341111111111111111111111111111111111234', goellars.address);
    tmp = replaceAll(tmp, '3451111111111111111111111111111111111345', passports.address);
    Earth._json.bytecode = tmp;
    const earth = await Earth.new();

    // fund earth
    await goellars.transfer(earth.address, 1000);
    await co2.transfer(earth.address, 1000);

    // print passports for citizens
    await passports.mint(citizenA, passportA);
    await passports.mint(citizenB, passportB);

    // citizen A sharing signed receipt through QR code
    const hash = ethUtil.hashPersonalMessage(Buffer.from(zero + factorA, 'hex'));
    const sig = ethUtil.ecsign(
      hash,
      Buffer.from(citizenAPriv.replace('0x', ''), 'hex'),
    );
    // citizen B signing transaction
    await passports.approve(earth.address, passportB, {from: citizenB});

    // sending transaction
    const tx = await earth.trade(
      passportA,           // uint256 passportA,
      `0x${factorA}`,      // bytes32 passDataAfter, 
      `0x${sig.r.toString('hex')}${sig.s.toString('hex')}${sig.v.toString(16)}`, // sig
      passportB,           // uint256 passportB,
      100,                 // uint256 factorB,
      air,                 // address airAddr
    ).should.be.fulfilled;

    // check result
    const emission = await co2.balanceOf(air);
    assert.equal(emission.toNumber(), 355);
    const balanceA = await goellars.balanceOf(citizenA);
    assert.equal(balanceA.toNumber(), 255);
    const balanceB = await goellars.balanceOf(citizenB);
    assert.equal(balanceB.toNumber(), 100);
    const passA = await passports.readData(passportA);
    assert.equal(passA, `0x${factorA}`);
  });


});
