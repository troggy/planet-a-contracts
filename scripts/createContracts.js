#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const { bufferToHex, ripemd160 } = require("ethereumjs-util");
const Earth = require("../build/contracts/Earth");
const Air = require("../build/contracts/Air");

const outdir = process.argv[2] || ".";

const airOutFile = path.join(outdir, "Air.json");
const earthOutFile = path.join(outdir, "Earth.json");

const testnetCO2 = "0xF64fFBC4A69631D327590f4151B79816a193a8c6";
const testnetGOL = "0x1f89Fb2199220a350287B162B9D0A330A2D2eFAD";
const gameMaster = "0xaf0939af286A35DBfab7DEd7c777A5F6E8BE26A8";

const replaceAll = (str, find, replace) =>
  str.replace(new RegExp(find, "g"), replace.replace("0x", "").toLowerCase());

// deploy air
let airCode = Air.deployedBytecode;
// replace token address placeholder to real token address
airCode = replaceAll(
  airCode,
  "1231111111111111111111111111111111111123",
  testnetCO2
);
airCode = replaceAll(
  airCode,
  "2341111111111111111111111111111111111234",
  testnetGOL
);
airCode = replaceAll(
  airCode,
  "5671111111111111111111111111111111111567",
  gameMaster
);
const airContractAddr = bufferToHex(ripemd160(airCode));

fs.writeFileSync(
  airOutFile,
  JSON.stringify({ address: airContractAddr, code: airCode, abi: Air.abi })
);
console.log("Air exported to", airOutFile);

// only needed for testnet deployment
let earthCode = Earth.deployedBytecode;
earthCode = replaceAll(
  earthCode,
  "1231111111111111111111111111111111111123",
  testnetCO2
);
earthCode = replaceAll(
  earthCode,
  "2341111111111111111111111111111111111234",
  testnetGOL
);
earthCode = replaceAll(
  earthCode,
  "4561111111111111111111111111111111111456",
  airContractAddr
);
earthCode = replaceAll(
  earthCode,
  "5671111111111111111111111111111111111567",
  gameMaster
);
const earthContractAddr = bufferToHex(ripemd160(earthCode));
fs.writeFileSync(
  "Earth.json",
  JSON.stringify({
    address: earthContractAddr,
    code: earthCode,
    abi: Earth.abi
  })
);
console.log("Earth exported to", earthOutFile);
