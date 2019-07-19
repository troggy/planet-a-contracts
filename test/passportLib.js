module.exports = class PassportLib {

  static makeBuf(data) {
    let buf;
    if (!Buffer.isBuffer(data)) {
      buf = Buffer.from(data.replace('0x', ''), 'hex');
    } else {
      buf = data;
    }
    return buf;
  }

  static hexDecode(str) {
    var j;
    var hexes = str.match(/.{1,4}/g) || [];
    var back = "";
    for(j = 0; j<hexes.length; j++) {
        back += String.fromCharCode(parseInt(hexes[j], 16));
    }
    return back;
  }

  static hexEncode(str) {
    var hex, i;

    var result = "";
    for (i=0; i<str.length; i++) {
        hex = str.charCodeAt(i).toString(16);
        result += ("000"+hex).slice(-4);
    }
    return result
  }

  static getReleasedCo2(data) {
    return PassportLib.makeBuf(data).readUInt32BE(28);
  }

  static getLockedCo2(data) {
    return PassportLib.makeBuf(data).readUInt32BE(24);
  }

  static getPicId(data) {
    return PassportLib.makeBuf(data).readUInt32BE(24);
  }

  static getName(data) {
    return PassportLib.hexDecode(makeBuf(data).slice(0, 20).toString('hex'));
  }

  constructor(data) {
    this.dataBefore = makeBuf(data);
  }

  updateReleasedCo2(amount) {
    const newAmount = PassportLib.getReleasedCo2(this.dataBefore) + amount;
    this.dataBefore.writeUInt32BE(newAmount, 28);
    return this.dataBefore;
  }

  updateLockedCo2(amount) {
    const newAmount = PassportLib.getLockedCo2(this.dataBefore) + amount;
    this.dataBefore.writeUInt32BE(newAmount, 24);
    return this.dataBefore;
  }

  setPicId(picId) {
    this.dataBefore.writeUInt32BE(picId, 20);
    return this.dataBefore;
  }

  setName(name) {
    Buffer.from(PassportLib.hexEncode(name), 'hex').copy(this.dataBefore, 0, 0, 20);
    return this.dataBefore;
  }
    
}
