import 'dart:typed_data';

/// Pacotes do bootloader serial da WCH (CH32V203), portados do BMCU Flasher
/// de Pawel Jarczak (MIT): https://github.com/jarczakpawel/BMCU-Flasher
///
/// Pedido: 57 AB | cmd | len (u16 LE) | dados | soma dos bytes desde cmd.
/// Resposta: 55 AA | cmd | codigo | len (u16 LE) | dados | soma desde cmd.
abstract final class IspCmd {
  static const identify = 0xA1;
  static const ispEnd = 0xA2;
  static const ispKey = 0xA3;
  static const erase = 0xA4;
  static const program = 0xA5;
  static const verify = 0xA6;
  static const readCfg = 0xA7;
  static const writeCfg = 0xA8;
  static const setBaud = 0xC5;
}

/// CH32V203C8T6, o chip do BMCU-370C.
const bmcuChipId = 0x31;
const bmcuChipType = 0x19;
const bmcuFlashKb = 64;

/// Ultimo setor da flash (0x0800F000), onde o firmware guarda a calibracao.
const bmcuNvmKb = 4;
const bmcuNvmAddress = (bmcuFlashKb - bmcuNvmKb) * 1024;
const bmcuCfgMask = 0x1F;
const cfgMaskRdprUserDataWpr = 0x07;

/// Tamanho do bloco gravado por pedido, o mesmo do flasher original.
const bmcuChunk = 56;

int checksum(List<int> bytes) => bytes.fold(0, (s, b) => (s + b) & 0xFF);

Uint8List _u16(int x) => Uint8List.fromList([x & 0xFF, (x >> 8) & 0xFF]);

Uint8List _u32(int x) => Uint8List.fromList(
    [x & 0xFF, (x >> 8) & 0xFF, (x >> 16) & 0xFF, (x >> 24) & 0xFF]);

Uint8List _request(int cmd, List<int> data) {
  final payload = [cmd, ..._u16(data.length), ...data];
  return Uint8List.fromList([0x57, 0xAB, ...payload, checksum(payload)]);
}

Uint8List identifyPacket() => _request(IspCmd.identify,
    [bmcuChipId, bmcuChipType, ...'MCU ISP & WCH.CN'.codeUnits]);

Uint8List readCfgPacket() => _request(IspCmd.readCfg, [bmcuCfgMask, 0]);

Uint8List writeCfgPacket(List<int> cfg12) =>
    _request(IspCmd.writeCfg, [cfgMaskRdprUserDataWpr, 0, ...cfg12]);

Uint8List ispKeyPacket(List<int> seed) => _request(IspCmd.ispKey, seed);

Uint8List erasePacket(int sectors) => _request(IspCmd.erase, _u32(sectors));

Uint8List setBaudPacket(int baud) => _request(IspCmd.setBaud, _u32(baud));

Uint8List programPacket(int address, List<int> data) =>
    _request(IspCmd.program, [..._u32(address), 0, ...data]);

Uint8List verifyPacket(int address, List<int> data) =>
    _request(IspCmd.verify, [..._u32(address), 0, ...data]);

Uint8List ispEndPacket(int reason) => _request(IspCmd.ispEnd, [reason]);

/// Os dados gravados vao cifrados com XOR por uma chave de 8 bytes que o
/// bootloader deriva do UID do chip.
Uint8List xorCrypt(List<int> data, List<int> key) => Uint8List.fromList(
    [for (var i = 0; i < data.length; i++) data[i] ^ key[i & 7]]);

Uint8List xorKeyFromUid(List<int> uid, int chipId) {
  final s = checksum(uid);
  return Uint8List.fromList([s, s, s, s, s, s, s, (s + chipId) & 0xFF]);
}

Uint8List xorKeyFromSeed(List<int> seed, int uidChk, int chipId) {
  final a = seed.length ~/ 5;
  final b = seed.length ~/ 7;
  final k = [
    for (final i in [b * 4, a, b, b * 6, b * 3, a * 3, b * 5])
      seed[i] ^ uidChk,
  ];
  return Uint8List.fromList([...k, (k[0] + chipId) & 0xFF]);
}

class IspResponse {
  const IspResponse(this.cmd, this.code, this.data);

  final int cmd;
  final int code;
  final Uint8List data;

  bool get ok => code == 0;
}

/// Junta os bytes que chegam da serial e devolve respostas completas.
/// Lixo antes do 55 AA e respostas com soma errada sao descartados.
class ResponseParser {
  final _buffer = <int>[];

  void clear() => _buffer.clear();

  IspResponse? add(List<int> bytes) {
    _buffer.addAll(bytes);
    while (true) {
      final start = _findMagic();
      if (start < 0) {
        // Guarda o ultimo byte: pode ser o 55 de um 55 AA cortado ao meio.
        if (_buffer.length > 1) _buffer.removeRange(0, _buffer.length - 1);
        return null;
      }
      _buffer.removeRange(0, start);
      if (_buffer.length < 7) return null;
      final len = _buffer[4] | (_buffer[5] << 8);
      final total = 6 + len + 1;
      if (_buffer.length < total) return null;
      final frame = _buffer.sublist(0, total);
      _buffer.removeRange(0, total);
      if (checksum(frame.sublist(2, total - 1)) != frame[total - 1]) continue;
      return IspResponse(
          frame[2], frame[3], Uint8List.fromList(frame.sublist(6, total - 1)));
    }
  }

  int _findMagic() {
    for (var i = 0; i + 1 < _buffer.length; i++) {
      if (_buffer[i] == 0x55 && _buffer[i + 1] == 0xAA) return i;
    }
    return -1;
  }
}
