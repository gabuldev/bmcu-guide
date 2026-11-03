import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:bmcu_flash/bmcu_flash.dart';
import 'package:bmcu_flash/src/isp_protocol.dart';
import 'package:test/test.dart';

/// Bootloader da WCH simulado: so responde depois de um reset com o BOOT0
/// ativo, decifra o que for gravado com a chave do UID e confere o verify.
class FakeBootloader implements SerialLink {
  FakeBootloader({
    this.bootOnDtr = false,
    this.bootLevel = false,
    this.resetLevel = false,
    this.wprProtected = false,
    this.failFastBaud = false,
    this.eraseAll = false,
    this.readProtected = false,
  });

  /// RDPR diferente de A5: como o chip real, apaga tudo ao liberar.
  bool readProtected;

  /// Bootloader que ignora o numero de setores e apaga a flash inteira.
  final bool eraseAll;

  /// Liga o BOOT0 no DTR (senao no RTS) e o nivel em que ele fica ativo.
  final bool bootOnDtr;
  final bool bootLevel;
  final bool resetLevel;
  bool wprProtected;
  final bool failFastBaud;

  final flash = Uint8List(64 * 1024)..fillRange(0, 64 * 1024, 0xFF);
  final uid = Uint8List.fromList([0x3c, 0x9a, 0x11, 0x08, 0x5e, 0x72, 0x00, 0xd4]);
  final log = <int>[];
  final _out = <int>[];
  var _dtr = false;
  var _rts = false;
  var _inBoot = false;
  var _running = true;
  var _unlocked = false;
  var _baud = 0;
  var _chipBaud = 115200;
  var resets = 0;

  bool get runningApp => _running && !_inBoot;

  Uint8List get key => xorKeyFromUid(uid, bmcuChipId);

  @override
  Future<void> setBaud(int baud) async => _baud = baud;

  @override
  Future<void> setDtr(bool value) async => _lines(dtr: value, rts: _rts);

  @override
  Future<void> setRts(bool value) async => _lines(dtr: _dtr, rts: value);

  /// O chip fica parado enquanto a linha de reset esta ativa e sobe quando
  /// ela solta; sobe no bootloader se o BOOT0 estiver ativo nesse momento.
  void _lines({required bool dtr, required bool rts}) {
    bool resetActive(bool d, bool r) => (bootOnDtr ? r : d) == resetLevel;
    final wasHeld = resetActive(_dtr, _rts);
    _dtr = dtr;
    _rts = rts;
    if (resetActive(dtr, rts)) {
      _running = false;
    } else if (wasHeld) {
      resets++;
      _running = true;
      _inBoot = (bootOnDtr ? dtr : rts) == bootLevel;
      _unlocked = false;
      _chipBaud = 115200;
    }
  }

  @override
  Future<void> purge() async => _out.clear();

  @override
  Future<Uint8List> read(Duration timeout) async {
    final data = Uint8List.fromList(_out);
    _out.clear();
    return data;
  }

  @override
  Future<void> write(Uint8List data) async {
    if (!_running || !_inBoot || _baud != _chipBaud) return;
    expect(data.sublist(0, 2), [0x57, 0xAB]);
    final cmd = data[2];
    final len = data[3] | (data[4] << 8);
    final body = data.sublist(5, 5 + len);
    expect(data[5 + len], checksum(data.sublist(2, 5 + len)));
    log.add(cmd);
    switch (cmd) {
      case IspCmd.identify:
        _reply(cmd, [bmcuChipId, bmcuChipType]);
      case IspCmd.readCfg:
        final rdpr = readProtected ? [0xFF, 0xFF] : [0xA5, 0x5A];
        final wpr = wprProtected ? [0, 0, 0, 0] : [0xFF, 0xFF, 0xFF, 0xFF];
        _reply(cmd, [0x1F, 0, ...rdpr, 0x3F, 0xC0, 0, 0xFF, 0, 0xFF, ...wpr,
          0, 2, 7, 0, ...uid]);
      case IspCmd.writeCfg:
        if (body.sublist(10, 14).every((b) => b == 0xFF)) wprProtected = false;
        final protect = body[2] != 0xA5;
        if (readProtected && !protect) flash.fillRange(0, flash.length, 0xFF);
        readProtected = protect;
        _reply(cmd, [0, 0]);
      case IspCmd.ispKey:
        _unlocked = true;
        _reply(cmd, [checksum(key)]);
      case IspCmd.erase:
        if (wprProtected) return _reply(cmd, [0, 0], code: 0xF5);
        // Apaga a partir do inicio, em setores de 1 KB.
        flash.fillRange(0, eraseAll ? flash.length : _u32(body) * 1024, 0xFF);
        _reply(cmd, [0, 0]);
      case IspCmd.program:
        final address = _u32(body);
        final plain = xorCrypt(body.sublist(5), key);
        if (!_unlocked) return _reply(cmd, [0, 0], code: 0xF5);
        flash.setRange(address, address + plain.length, plain);
        _reply(cmd, [0, 0]);
      case IspCmd.verify:
        final address = _u32(body);
        final plain = xorCrypt(body.sublist(5), key);
        final same = Iterable<int>.generate(plain.length)
            .every((i) => flash[address + i] == plain[i]);
        _reply(cmd, [0, 0], code: same ? 0 : 0xF5);
      case IspCmd.setBaud:
        _reply(cmd, [0, 0]);
        if (!failFastBaud) _chipBaud = _u32(body);
      case IspCmd.ispEnd:
        _reply(cmd, [0, 0]);
        _inBoot = false;
    }
  }

  int _u32(List<int> b) => b[0] | (b[1] << 8) | (b[2] << 16) | (b[3] << 24);

  void _reply(int cmd, List<int> data, {int code = 0}) {
    final payload = [cmd, code, data.length & 0xFF, data.length >> 8, ...data];
    // Um byte de lixo antes, como a serial as vezes entrega.
    _out.addAll([0x00, 0x55, 0xAA, ...payload, checksum(payload)]);
  }
}

Future<void> _noDelay(Duration _) async {}

Uint8List _firmware(int size) {
  final r = Random(7);
  return Uint8List.fromList(List.generate(size, (_) => r.nextInt(256)));
}

void main() {
  group('protocolo', () {
    test('monta o identify igual ao flasher original', () {
      final p = identifyPacket();
      expect(p.sublist(0, 6), [0x57, 0xAB, 0xA1, 0x12, 0x00, 0x31]);
      expect(String.fromCharCodes(p.sublist(7, 23)), 'MCU ISP & WCH.CN');
      expect(p.last, checksum(p.sublist(2, p.length - 1)));
    });

    test('a chave do UID tem a soma que o bootloader devolve', () {
      final key = xorKeyFromUid([1, 2, 3, 4, 5, 6, 7, 8], 0x31);
      expect(key, [36, 36, 36, 36, 36, 36, 36, 36 + 0x31]);
    });

    test('o parser junta respostas cortadas e ignora lixo', () {
      final parser = ResponseParser();
      expect(parser.add([0x13, 0x55]), isNull);
      expect(parser.add([0xAA, 0xA1, 0x00, 0x02]), isNull);
      final r = parser.add([0x00, 0x31, 0x19, (0xA1 + 2 + 0x31 + 0x19) & 0xFF]);
      expect(r!.cmd, 0xA1);
      expect(r.data, [0x31, 0x19]);
    });
  });

  group('gravacao', () {
    test('grava e confere o firmware inteiro', () async {
      final chip = FakeBootloader();
      final fw = _firmware(53656);
      final stages = <FlashStage>{};
      await BmcuFlasher(chip, delay: _noDelay)
          .flash(fw, onProgress: (s, _) => stages.add(s));
      expect(chip.flash.sublist(0, fw.length), fw);
      expect(chip.flash.sublist(fw.length).every((b) => b == 0xFF), isTrue);
      expect(stages, containsAll(FlashStage.values));
      expect(chip.runningApp, isTrue, reason: 'sobe o firmware no fim');
      expect(chip.log.where((c) => c == IspCmd.verify).length,
          // NVM no inicio e antes de apagar (2 paginas cada) + bloco final
          // apagado + um por bloco gravado
          5 + (fw.length / bmcuChunk).ceil());
    });

    test('mantem a calibracao no ultimo setor', () async {
      final chip = FakeBootloader();
      chip.flash.fillRange(0, 0x10000, 0x00);
      final fw = _firmware(3000);
      final logs = <String>[];
      await BmcuFlasher(chip, delay: _noDelay).flash(fw, onLog: logs.add);
      expect(chip.flash.sublist(0, fw.length), fw);
      expect(chip.flash.sublist(fw.length, 0xF000).every((b) => b == 0xFF), isTrue);
      expect(chip.flash.sublist(0xF000).every((b) => b == 0x00), isTrue,
          reason: 'NVM em 0x0800F000 intacta');
      expect(logs.any((l) => l.contains('calibracao mantida')), isTrue);
    });

    test('avisa quando o bootloader apaga a calibracao mesmo assim', () async {
      final chip = FakeBootloader(eraseAll: true);
      chip.flash.fillRange(0, 0x10000, 0x00);
      final logs = <String>[];
      await BmcuFlasher(chip, delay: _noDelay).flash(_firmware(3000), onLog: logs.add);
      expect(logs, contains('NVM antes de apagar: com dados'));
      expect(logs.any((l) => l.contains('apagou a calibracao junto')), isTrue);
    });

    test('restaura a calibracao quando o bootloader apagou', () async {
      final chip = FakeBootloader(eraseAll: true);
      chip.flash.fillRange(0, 0x10000, 0x00);
      final page = Uint8List.fromList(List.generate(256, (i) => i));
      final fw = _firmware(3000);
      final logs = <String>[];
      await BmcuFlasher(chip, delay: _noDelay)
          .flash(fw, nvmRestore: page, onLog: logs.add);
      expect(chip.flash.sublist(0, fw.length), fw);
      expect(chip.flash.sublist(0xF000, 0xF100), page);
      expect(logs.any((l) => l.contains('restaurando')), isTrue);
    });

    test('nao mexe na calibracao que sobreviveu', () async {
      final chip = FakeBootloader();
      chip.flash.fillRange(0, 0x10000, 0x00);
      await BmcuFlasher(chip, delay: _noDelay).flash(_firmware(3000),
          nvmRestore: Uint8List.fromList(List.filled(256, 7)));
      expect(chip.flash.sublist(0xF000).every((b) => b == 0x00), isTrue);
    });

    test('deixa o chip sem protecao e o proximo flash mantem a calibracao', () async {
      final chip = FakeBootloader(readProtected: true);
      chip.flash.fillRange(0, 0x10000, 0x00);
      final logs = <String>[];
      await BmcuFlasher(chip, delay: _noDelay).flash(_firmware(3000), onLog: logs.add);
      expect(logs.any((l) => l.contains('protecao de leitura ligada')), isTrue);
      // Mostra que foi a liberacao da protecao que apagou a NVM.
      expect(logs, containsAllInOrder(['NVM no inicio: com dados', 'NVM antes de apagar: vazia']));
      expect(chip.readProtected, isFalse);
      chip.flash.fillRange(0xF000, 0x10000, 0x11); // calibracao feita depois
      await BmcuFlasher(chip, delay: _noDelay).flash(_firmware(3000), onLog: logs.add);
      expect(chip.flash.sublist(0xF000).every((b) => b == 0x11), isTrue);
      expect(logs.any((l) => l.contains('calibracao mantida')), isTrue);
    });

    test('apagando tudo, grava a pagina pedida no lugar', () async {
      final chip = FakeBootloader();
      chip.flash.fillRange(0, 0x10000, 0x00);
      final page = Uint8List.fromList(List.filled(256, 9));
      await BmcuFlasher(chip, delay: _noDelay)
          .flash(_firmware(3000), keepSettings: false, nvmRestore: page);
      expect(chip.flash.sublist(0xF000, 0xF100), page);
      expect(chip.flash.sublist(0xF100).every((b) => b == 0xFF), isTrue);
    });

    test('apaga tudo quando pedido', () async {
      final chip = FakeBootloader();
      chip.flash.fillRange(0, 0x10000, 0x00);
      await BmcuFlasher(chip, delay: _noDelay).flash(_firmware(3000), keepSettings: false);
      expect(chip.flash.sublist(0xF000).every((b) => b == 0xFF), isTrue);
    });

    test('recusa firmware que invade a area da calibracao', () async {
      final flasher = BmcuFlasher(FakeBootloader(), delay: _noDelay);
      await expectLater(flasher.flash(_firmware(61441)), throwsA(isA<FlashException>()));
    });

    test('acha o BOOT0 em qualquer linha e nivel', () async {
      for (final onDtr in [true, false]) {
        for (final boot in [true, false]) {
          for (final reset in [true, false]) {
            final chip = FakeBootloader(
                bootOnDtr: onDtr, bootLevel: boot, resetLevel: reset);
            final fw = _firmware(1000);
            await BmcuFlasher(chip, delay: _noDelay).flash(fw);
            expect(chip.flash.sublist(0, fw.length), fw);
          }
        }
      }
    });

    test('libera a flash protegida antes de apagar', () async {
      final chip = FakeBootloader(wprProtected: true);
      await BmcuFlasher(chip, delay: _noDelay).flash(_firmware(500));
      expect(chip.wprProtected, isFalse);
    });

    test('volta para 115200 se o adaptador nao aguentar 1 Mbaud', () async {
      final chip = FakeBootloader(failFastBaud: true);
      final logs = <String>[];
      final fw = _firmware(2000);
      await BmcuFlasher(chip, delay: _noDelay).flash(fw, onLog: logs.add);
      expect(chip.flash.sublist(0, fw.length), fw);
      expect(logs.any((l) => l.contains('repetindo')), isTrue);
    });

    test('falha clara quando nada responde', () async {
      final flasher = BmcuFlasher(_Silent(), delay: _noDelay);
      await expectLater(flasher.flash(_firmware(10)),
          throwsA(isA<FlashException>()));
    });
  });

  group('calibracao', () {
    test('CRC igual ao periferico do STM32/CH32', () {
      expect(stm32Crc([0x78, 0x56, 0x34, 0x12]), 0xDF8A8A2B);
    });

    test('pagina CAL2 com cabecalho, valores e CRC', () {
      final cal = BufferCalibration.fromTelemetry(
        centerMv: [1612, 1637, 1749, 1570],
        vminMv: [1217, 1248, 1032, 1071],
        vmaxMv: [2195, 2033, 2241, 2161],
        polarity: [-1, -1, -1, -1],
        keyIdleMv: [412, 194, 287, 223],
      );
      final page = cal.toPage();
      final d = ByteData.sublistView(page);
      expect(d.getUint32(0, Endian.little), 0x324C4143);
      expect(d.getUint16(4, Endian.little), 2);
      expect(d.getUint16(6, Endian.little), 64);
      expect(d.getUint32(8, Endian.little), 0x0F0F);
      expect(d.getFloat32(12, Endian.little), closeTo(1.65 - 1.612, 1e-6));
      expect(d.getFloat32(12 + 16, Endian.little), closeTo(1.217, 1e-6));
      expect(d.getFloat32(12 + 48, Endian.little), closeTo(0.60, 1e-6));
      expect(d.getUint32(252, Endian.little), stm32Crc(page.sublist(0, 252)));
    });

    test('limiar do sensor igual ao firmware', () {
      expect(BufferCalibration.keyNoneFromIdle(0.412), closeTo(0.60, 1e-6));
      expect(BufferCalibration.keyNoneFromIdle(0.555), closeTo(0.66, 1e-6));
      expect(BufferCalibration.keyNoneFromIdle(1.35), closeTo(1.39, 1e-6));
    });
  });

  group('firmware', () {
    final manifest =
        parseManifest(File('test/fixtures/manifest.txt').readAsStringSync());

    test('o caminho da variante existe no manifest publicado', () {
      for (final force in LoadForce.values) {
        for (final slot in AmsSlot.values) {
          for (final retract in retractLengths.keys) {
            for (final flag in [true, false]) {
              final v = FirmwareVariant(
                  force: force, autoload: flag, rgb: !flag, slot: slot, retract: retract);
              expect(manifest, contains(v.path), reason: v.path);
            }
          }
        }
      }
    });

    test('sugere a forca pelo modelo', () {
      expect(LoadForce.suggestedFor('A1 mini'), LoadForce.standard);
      expect(LoadForce.suggestedFor('P1S'), LoadForce.highForce);
    });

    test('CRC32 e SHA-256 batem com os valores conhecidos', () {
      final bytes = '123456789'.codeUnits;
      expect(crc32Of(bytes), 0xCBF43926);
      expect(sha256Hex(bytes),
          '15e2b0d3c33891ebb0f1ef609ec419420c20e320ce94c65fbc8c3312448eb225');
    });

    test('a variante sobrevive ao json', () {
      const v = FirmwareVariant(
          force: LoadForce.soft, autoload: true, rgb: false, slot: AmsSlot.b, retract: '20 cm');
      expect(FirmwareVariant.fromJson(v.toJson())!.path, v.path);
    });
  });
}

class _Silent implements SerialLink {
  @override
  Future<void> purge() async {}
  @override
  Future<Uint8List> read(Duration timeout) async => Uint8List(0);
  @override
  Future<void> setBaud(int baud) async {}
  @override
  Future<void> setDtr(bool value) async {}
  @override
  Future<void> setRts(bool value) async {}
  @override
  Future<void> write(Uint8List data) async {}
}
