/**
 * Copyright (c) 2019-present, Social Dist0rtion Protocol
 *
 * This source code is licensed under the Mozilla Public License, version 2,
 * found in the LICENSE file in the root directory of this source tree.
 */
const chai = require('chai');
const ethUtil = require('ethereumjs-util');
const PassportManager = artifacts.require('./PassportManager.sol');
const ERC1948 = artifacts.require('./mocks/ERC1948');

const should = chai
  .use(require('chai-as-promised'))
  .should();

function replaceAll(str, find, replace) {
    return str.replace(new RegExp(find, 'g'), replace.replace('0x', ''));
}

String.prototype.hexEncode = function(){
    var hex, i;

    var result = "";
    for (i=0; i<this.length; i++) {
        hex = this.charCodeAt(i).toString(16);
        result += ("000"+hex).slice(-4);
    }

    return result
}


contract('Passport Manager', (accounts) => {
  const citizenA = accounts[1];
  const citizenAPriv = '0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501201';
  const passportA = 123;
  let country;
  let originalByteCode;

  before(async () => {
    country = await ERC1948.new();
  });

  it('should allow to update name', async () => {
    const passportManager = await PassportManager.new();

    // print passports for citizenA
    await country.mint(citizenA, passportA);
    // citizonA fills in some data
    country.writeData(passportA, '0x6a6f686261000000000000000000000000000000000000cc000000010000aabb', {from: citizenA});
    await country.approve(passportManager.address, passportA, {from: citizenA});

    // sending transaction
    const name = 'hans';
    const tx = await passportManager.setName(`0x${name.hexEncode()}`, country.address, passportA).should.be.fulfilled;

    // check result
    const passA = await country.readData(passportA);
    assert.equal(passA, '0x00000000000000000000000000680061006e0073000000cc000000010000aabb');
  });


});
