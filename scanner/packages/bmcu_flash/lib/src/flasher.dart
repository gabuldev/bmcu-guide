import 'dart:typed_data';

import 'isp_protocol.dart';

/// A porta USB-serial do BMCU (um CH340 na placa). O DTR e o RTS estao
/// ligados no BOOT0 e no RESET do chip, por isso da para entrar no
/// bootloader sem apertar botao.
abstract interface class SerialLink {
  Future<void> setBaud(int baud);
  Future<void> setDtr(bool value);
  Future<void> setRts(bool value);
  Future<void> write(Uint8List data);

  /// Devolve o que chegar ate o [timeout]; pode vir vazio.
  Future<Uint8List> read(Duration timeout);

  /// Descarta o que estiver nos buffers do adaptador.
  Future<void> purge();
}

enum FlashStage { connecting, unlocking, erasing, writing, verifying, done }

class FlashException implements Exception {
  const FlashException(this.message);

  final String message;

  @override
  String toString() => 'FlashException: $message';
}

/// Qual linha vai no BOOT0 e em que nivel cada uma fica ativa. Varia entre
/// placas, entao o flasher testa as oito combinacoes.
class _LineMap {
  const _LineMap(this.bootIsDtr, this.bootAssert, this.resetAssert);

  final bool bootIsDtr;
  final bool bootAssert;
  final bool resetAssert;
}

class _FastBaudFailed implements Exception {
  const _FastBaudFailed(this.cause);

  final Object cause;
}

typedef FlashProgress = void Function(FlashStage stage, double fraction);
typedef FlashLog = void Function(String line);

/// Grava o firmware pelo bootloader da WCH, na mesma sequencia do BMCU
/// Flasher (modo "usb"): entra no bootloader, libera as option bytes,
/// apaga, grava em blocos de 56 bytes e confere bloco a bloco.
///
/// Por padrao apaga so a area do firmware e deixa o ultimo setor de 4 KB,
/// onde o firmware guarda a calibracao dos buffers e os filamentos. O BMCU
/// Flasher apaga a flash inteira, o que obriga a calibrar tudo de novo.
class BmcuFlasher {
  BmcuFlasher(
    this._link, {
    this.baud = 115200,
    this.fastBaud = 1000000,
    Future<void> Function(Duration)? delay,
  }) : _delay = delay ?? Future<void>.delayed;

  final SerialLink _link;
  final int baud;
  final int fastBaud;
  final Future<void> Function(Duration) _delay;
  final _parser = ResponseParser();

  Future<void> flash(
    Uint8List firmware, {
    FlashProgress? onProgress,
    FlashLog? onLog,
    bool keepSettings = true,
    Uint8List? nvmRestore,
  }) async {
    final eraseKb = keepSettings ? bmcuFlashKb - bmcuNvmKb : bmcuFlashKb;
    if (firmware.isEmpty || firmware.length > eraseKb * 1024) {
      throw FlashException('tamanho de firmware invalido: ${firmware.length}');
    }
    try {
      await _flashOnce(firmware,
          fast: true,
          eraseKb: eraseKb,
          nvmRestore: nvmRestore,
          onProgress: onProgress,
          onLog: onLog);
    } on _FastBaudFailed catch (e) {
      // Alguns adaptadores nao aguentam 1 Mbaud. Como a flash ja foi
      // apagada, recomeca do zero na velocidade normal.
      onLog?.call('1 Mbaud falhou (${e.cause}); repetindo a $baud baud');
      await _flashOnce(firmware,
          fast: false,
          eraseKb: eraseKb,
          nvmRestore: nvmRestore,
          onProgress: onProgress,
          onLog: onLog);
    }
  }

  Future<void> _flashOnce(
    Uint8List firmware, {
    required bool fast,
    required int eraseKb,
    Uint8List? nvmRestore,
    FlashProgress? onProgress,
    FlashLog? onLog,
  }) async {
    void log(String line) => onLog?.call(line);
    void progress(FlashStage stage, double f) => onProgress?.call(stage, f);

    progress(FlashStage.connecting, 0);
    await _link.setBaud(baud);
    var lines = await _findLineMap();
    if (lines == null) {
      throw const FlashException('o BMCU nao entrou no modo de gravacao');
    }
    log('bootloader ok (boot=${lines.bootIsDtr ? 'DTR' : 'RTS'})');

    final id = await _txrx(identifyPacket(), IspCmd.identify, 1000);
    if (!id.ok || id.data.length < 2) {
      throw const FlashException('o chip nao respondeu a identificacao');
    }
    final chipId = id.data[0];
    if (chipId != bmcuChipId || id.data[1] != bmcuChipType) {
      throw FlashException('chip inesperado: '
          '${_hex(chipId)}/${_hex(id.data[1])}, esperava CH32V203');
    }

    progress(FlashStage.unlocking, 0);
    var cfg = await _readCfg();
    // Confere a NVM antes de mexer nas option bytes. Se aqui ela tem dados e
    // la embaixo esta vazia, quem apagou foi a gravacao da configuracao.
    final earlySeed = Uint8List(0x1E);
    final earlyResp = await _txrx(ispKeyPacket(earlySeed), IspCmd.ispKey, 1200);
    final earlyKey = earlyResp.ok && earlyResp.data.isNotEmpty
        ? _matchKey(earlyResp.data[0], cfg, earlySeed, chipId)
        : null;
    log(earlyKey == null
        ? 'NVM no inicio: nao deu para conferir'
        : await _nvmBlank(earlyKey)
            ? 'NVM no inicio: vazia'
            : 'NVM no inicio: com dados');
    // A ferramenta da WCH grava as option bytes duas vezes, com um reset no
    // meio, antes de liberar a gravacao. Sem isso o chip recusa a chave.
    // RDPR diferente de A5 e protecao de leitura. Desligar a protecao faz o
    // chip apagar a flash inteira, inclusive a calibracao.
    log(cfg.readProtected
        ? 'protecao de leitura ligada (RDPR=${_hex(cfg.raw[2])}): o chip vai apagar tudo ao liberar'
        : 'protecao de leitura desligada');
    await _writeCfg(_patchCfg(cfg.cfg12,
        [0xA5, 0x5A, 0x3F, 0xC0, 0x00, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]));
    cfg = await _readCfg();
    try {
      await _txrx(ispEndPacket(1), IspCmd.ispEnd, 1200);
    } on FlashException {
      // O chip reinicia logo depois de aplicar, as vezes sem responder.
    }
    if (!await _reenter(lines)) {
      // A primeira combinacao pode ter dado certo por acaso (o chip reiniciou
      // so de mexer na linha); entao procura de novo antes de desistir.
      lines = await _findLineMap();
      if (lines == null) {
        throw const FlashException('o BMCU nao voltou ao modo de gravacao');
      }
    }
    for (var i = 0; i < 2; i++) {
      final again = await _txrx(identifyPacket(), IspCmd.identify, 1000);
      if (!again.ok) throw const FlashException('identificacao falhou');
      cfg = await _readCfg();
    }
    // O BMCU Flasher grava FF FF aqui, o que religa a protecao de leitura e
    // faz o proximo flash apagar a calibracao. Mantem A5 5A (sem protecao)
    // e so cai no jeito antigo se o chip recusar a chave assim.
    final seed = Uint8List(0x1E);
    Future<IspResponse?> unlock(int rdpr, int nrdpr) async {
      await _writeCfg(_patchCfg(cfg.cfg12,
          [rdpr, nrdpr, 0x3F, 0xC0, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF]));
      cfg = await _readCfg();
      final r = await _txrx(ispKeyPacket(seed), IspCmd.ispKey, 1200);
      return r.ok && r.data.isNotEmpty ? r : null;
    }

    var keyResp = await unlock(0xA5, 0x5A);
    if (keyResp == null) {
      log('chave recusada sem protecao; usando a configuracao do BMCU Flasher');
      keyResp = await unlock(0xFF, 0xFF);
    }
    if (keyResp == null) {
      throw const FlashException('o chip recusou a chave de gravacao');
    }
    final bootSum = keyResp.data[0];
    final key = _matchKey(bootSum, cfg, seed, chipId);
    if (key == null) {
      throw FlashException('chave nao confere (boot=${_hex(bootSum)})');
    }

    if (!cfg.wprCleared) {
      log('flash protegida (WPR=${cfg.wprHex}), liberando');
      await _writeCfg(_patchCfg(cfg.cfg12, [0xA5, 0x5A], wpr: true));
      await _delay(const Duration(milliseconds: 80));
      cfg = await _readCfg();
      if (!cfg.wprCleared) {
        throw const FlashException(
            'a protecao da flash nao saiu; desligue e ligue o BMCU e tente de novo');
      }
    }

    progress(FlashStage.erasing, 0);
    final blank = Uint8List(bmcuChunk)..fillRange(0, bmcuChunk, 0xFF);
    Future<bool> nvmBlank() => _nvmBlank(key);
    final keep = eraseKb < bmcuFlashKb;
    final hadNvm = !await nvmBlank();
    log(hadNvm ? 'NVM antes de apagar: com dados' : 'NVM antes de apagar: vazia');
    final erased = await _txrx(erasePacket(eraseKb), IspCmd.erase, 12000);
    if (!erased.ok) throw const FlashException('falha ao apagar a flash');
    // Confere o ultimo bloco apagado para ter certeza de que apagou tudo.
    final tail = ((eraseKb * 1024 - bmcuChunk) ~/ bmcuChunk) * bmcuChunk;
    final tailOk = await _txrx(verifyPacket(tail, xorCrypt(blank, key)), IspCmd.verify, 1800);
    if (!tailOk.ok) throw const FlashException('a flash nao foi apagada inteira');
    var nvmEmpty = true;
    if (!keep) {
      log('flash apagada (com a calibracao)');
    } else if (!hadNvm) {
      log('flash apagada ($eraseKb KB; nao havia calibracao para manter)');
    } else if (await nvmBlank()) {
      log('flash apagada ($eraseKb KB), mas o bootloader apagou a calibracao junto');
    } else {
      nvmEmpty = false;
      log('flash apagada ($eraseKb KB, calibracao mantida)');
    }

    // Com a NVM vazia, grava junto a pagina de calibracao guardada, no mesmo
    // fluxo continuo do firmware (preenchido com 0xFF ate 0x0800F000).
    var image = firmware;
    if (nvmEmpty && nvmRestore != null) {
      image = Uint8List(bmcuNvmAddress + nvmRestore.length)
        ..fillRange(0, bmcuNvmAddress + nvmRestore.length, 0xFF)
        ..setRange(0, firmware.length, firmware)
        ..setRange(bmcuNvmAddress, bmcuNvmAddress + nvmRestore.length, nvmRestore);
      log('restaurando a calibracao guardada (${nvmRestore.length} bytes)');
    }
    final blocks = (image.length + bmcuChunk - 1) ~/ bmcuChunk;
    final padded = Uint8List(blocks * bmcuChunk)..fillRange(0, blocks * bmcuChunk, 0xFF);
    padded.setRange(0, image.length, image);

    var speedUp = false;
    if (fast && fastBaud != baud) {
      try {
        final r = await _txrx(setBaudPacket(fastBaud), IspCmd.setBaud, 1200);
        if (!r.ok) throw const FlashException('set_baud recusado');
        await _delay(const Duration(milliseconds: 30));
        await _link.setBaud(fastBaud);
        await _flush();
        speedUp = true;
        log('velocidade $fastBaud baud');
      } on FlashException catch (e) {
        throw _FastBaudFailed(e);
      }
    }

    Future<void> eachBlock(int cmd, FlashStage stage) async {
      for (var i = 0; i < blocks; i++) {
        final address = i * bmcuChunk;
        final data = xorCrypt(padded.sublist(address, address + bmcuChunk), key);
        final packet = cmd == IspCmd.program
            ? programPacket(address, data)
            : verifyPacket(address, data);
        final IspResponse r;
        try {
          r = await _txrx(packet, cmd, 1800);
        } on FlashException catch (e) {
          if (speedUp) throw _FastBaudFailed(e);
          rethrow;
        }
        if (!r.ok) {
          final what = stage == FlashStage.writing ? 'gravar' : 'conferir';
          throw FlashException('falha ao $what o endereco 0x${address.toRadixString(16)}');
        }
        progress(stage, (i + 1) / blocks);
      }
    }

    await eachBlock(IspCmd.program, FlashStage.writing);
    // Um A5 vazio no fim descarrega o que o bootloader ainda tem em buffer.
    final flushed = await _txrx(programPacket(blocks * bmcuChunk, const []), IspCmd.program, 2200);
    if (!flushed.ok) throw const FlashException('falha ao finalizar a gravacao');
    log('gravados ${firmware.length} bytes');

    final key2 = await _txrx(ispKeyPacket(seed), IspCmd.ispKey, 1200);
    if (!key2.ok || key2.data.isEmpty || key2.data[0] != bootSum) {
      throw const FlashException('a chave mudou antes da conferencia');
    }
    await eachBlock(IspCmd.verify, FlashStage.verifying);
    log('conferencia ok');

    try {
      await _txrx(ispEndPacket(0), IspCmd.ispEnd, 1200);
    } on FlashException {
      // Ja esta gravado; o chip pode reiniciar sem responder.
    }
    // Solta o BOOT0 e reinicia para o firmware novo subir.
    await _setLines(lines, boot: !lines.bootAssert, reset: lines.resetAssert);
    await _delay(const Duration(milliseconds: 20));
    await _pulseReset(lines);
    progress(FlashStage.done, 1);
  }

  Future<_LineMap?> _findLineMap() async {
    for (final bootIsDtr in [true, false]) {
      for (final bootAssert in [true, false]) {
        for (final resetAssert in [true, false]) {
          final lines = _LineMap(bootIsDtr, bootAssert, resetAssert);
          if (await _enterBootloader(lines, settle: 60, timeout: 600)) {
            return lines;
          }
        }
      }
    }
    return null;
  }

  Future<bool> _reenter(_LineMap lines) async {
    final end = DateTime.now().add(const Duration(milliseconds: 2500));
    while (true) {
      if (await _enterBootloader(lines, settle: 80, timeout: 800)) return true;
      if (DateTime.now().isAfter(end)) return false;
      await _delay(const Duration(milliseconds: 100));
    }
  }

  Future<bool> _enterBootloader(_LineMap lines,
      {required int settle, required int timeout}) async {
    try {
      await _flush();
      await _setLines(lines, boot: lines.bootAssert, reset: lines.resetAssert);
      await _delay(const Duration(milliseconds: 20));
      await _pulseReset(lines);
      await _delay(Duration(milliseconds: settle));
      await _flush();
      final r = await _txrx(identifyPacket(), IspCmd.identify, timeout);
      return r.ok && r.data.length >= 2;
    } on FlashException {
      return false;
    }
  }

  Future<void> _setLines(_LineMap lines,
      {required bool boot, required bool reset}) async {
    if (lines.bootIsDtr) {
      await _link.setDtr(boot);
      await _link.setRts(reset);
    } else {
      await _link.setRts(boot);
      await _link.setDtr(reset);
    }
  }

  Future<void> _pulseReset(_LineMap lines) async {
    final setReset = lines.bootIsDtr ? _link.setRts : _link.setDtr;
    await setReset(!lines.resetAssert);
    await _delay(const Duration(milliseconds: 20));
    await setReset(lines.resetAssert);
  }

  Future<void> _flush() async {
    await _link.purge();
    _parser.clear();
  }

  Future<IspResponse> _txrx(Uint8List packet, int cmd, int timeoutMs) async {
    await _link.write(packet);
    final end = DateTime.now().add(Duration(milliseconds: timeoutMs));
    while (true) {
      final left = end.difference(DateTime.now());
      if (left <= Duration.zero) {
        throw FlashException('sem resposta ao comando ${_hex(cmd)}');
      }
      final chunk = await _link.read(left < _poll ? left : _poll);
      var r = _parser.add(chunk);
      while (r != null) {
        if (r.cmd == cmd) return r;
        r = _parser.add(const []);
      }
    }
  }

  static const _poll = Duration(milliseconds: 20);

  Uint8List? _matchKey(int bootSum, _Cfg cfg, Uint8List seed, int chipId) => [
        if (cfg.uid.length == 8) xorKeyFromUid(cfg.uid, chipId),
        xorKeyFromSeed(seed, cfg.raw[2], chipId),
      ].where((k) => checksum(k) == bootSum).firstOrNull;

  // O verify so compara, entao da para saber se a NVM tem dados sem le-la:
  // se o inicio da pagina de calibracao "confere" com 0xFF, ela esta vazia.
  // As duas paginas de calibracao (o firmware alterna entre elas).
  Future<bool> _nvmBlank(Uint8List key) async {
    final blank = Uint8List(bmcuChunk)..fillRange(0, bmcuChunk, 0xFF);
    for (final address in [bmcuNvmAddress, bmcuNvmAddress + 15 * 256]) {
      final r = await _txrx(verifyPacket(address, xorCrypt(blank, key)), IspCmd.verify, 1800);
      if (!r.ok) return false;
    }
    return true;
  }

  Future<_Cfg> _readCfg() async {
    final r = await _txrx(readCfgPacket(), IspCmd.readCfg, 1200);
    if (!r.ok || r.data.length < 14) {
      throw const FlashException('falha ao ler a configuracao do chip');
    }
    return _Cfg(r.data);
  }

  Future<void> _writeCfg(Uint8List cfg12) async {
    final r = await _txrx(writeCfgPacket(cfg12), IspCmd.writeCfg, 2000);
    if (!r.ok) throw const FlashException('falha ao gravar a configuracao do chip');
  }

  /// Sobrescreve o inicio de cfg12; com [wpr] tambem zera a protecao.
  Uint8List _patchCfg(Uint8List cfg12, List<int> head, {bool wpr = false}) {
    final out = Uint8List.fromList(cfg12)..setRange(0, head.length, head);
    if (wpr) out.fillRange(8, 12, 0xFF);
    return out;
  }
}

/// Resposta do A7: 2 bytes de mascara, 12 de option bytes (RDPR/USER,
/// DATA, WPR), versao do bootloader e os 8 bytes do UID no fim.
class _Cfg {
  _Cfg(this.raw);

  final Uint8List raw;

  Uint8List get cfg12 => Uint8List.fromList(raw.sublist(2, 14));
  Uint8List get uid =>
      raw.length >= 8 ? Uint8List.fromList(raw.sublist(raw.length - 8)) : Uint8List(0);
  bool get readProtected => raw.length > 2 && raw[2] != 0xA5;
  bool get wprCleared => raw.sublist(10, 14).every((b) => b == 0xFF);
  String get wprHex => raw.sublist(10, 14).map(_hex).join();
}

String _hex(int b) => b.toRadixString(16).padLeft(2, '0');
