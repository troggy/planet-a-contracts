/**
 * Copyright (c) 2019-present, Social Dist0rtion Protocol
 *
 * This source code is licensed under the Mozilla Public License, version 2,
 * found in the LICENSE file in the root directory of this source tree.
 */
const chai = require('chai');
const ethUtil = require('ethereumjs-util');
const Air = artifacts.require('./Air.sol');
const SimpleToken = artifacts.require('./mocks/SimpleToken');
const ERC1948 = artifacts.require('./mocks/ERC1948');

const should = chai
  .use(require('chai-as-promised'))
  .should();

function replaceAll(str, find, replace) {
    return str.replace(new RegExp(find, 'g'), replace.replace('0x', ''));
}


contract('Air Contract', (accounts) => {
  const citizenA = accounts[1];
  const earth = accounts[2];
  const citizenAPriv = '0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501201';
  const passportA = 123;
  let goellars;
  let co2;
  let country;
  let originalByteCode;

  before(async () => {
    goellars = await SimpleToken.new();
    await goellars.transfer(citizenA, 1000);
    co2 = await SimpleToken.new();
    country = await ERC1948.new();
    originalByteCode = Air._json.bytecode;
  });

  afterEach(() => {
    Air._json.bytecode = originalByteCode;
  });

  it('should allow to plant', async () => {

    // deploy earth
    let tmp = Air._json.bytecode;
    // replace token address placeholder to real token address
    tmp = replaceAll(tmp, '1231111111111111111111111111111111111123', co2.address);
    tmp = replaceAll(tmp, '2341111111111111111111111111111111111234', goellars.address);
    Air._json.bytecode = tmp;
    const air = await Air.new();

    // pollute air
    await co2.transfer(air.address, 1000);

    // print passports for citizenA
    await country.mint(citizenA, passportA);
    // citizonA fills in some data
    country.writeData(passportA, '0x6a6f686261000000000000000000000000000000000000cc000000010000aabb', {from: citizenA});

    // citizen A signing transaction
    await country.approve(air.address, passportA, {from: citizenA});
    await goellars.approve(air.address, 1000, {from: citizenA});

    // sending transaction
    const tx = await air.plantTree(500, country.address, passportA, earth).should.be.fulfilled;

    // check result
    const locked = await co2.balanceOf(earth);
    assert.equal(locked.toNumber(), 500);
    const balanceAir = await goellars.balanceOf(air.address);
    assert.equal(balanceAir.toNumber(), 500);
    const passA = await country.readData(passportA);
    assert.equal(passA, '0x6a6f686261000000000000000000000000000000000000cc000001f50000aabb');
  });


});
