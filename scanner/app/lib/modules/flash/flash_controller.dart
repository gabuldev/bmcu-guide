import 'dart:io';

import 'package:bmcu_flash/bmcu_flash.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/usb_serial_link.dart';
import '../../core/variant_store.dart';
import 'flash_status.dart';

class FlashController extends Cubit<FlashStatus> {
  FlashController(
    this._variants,
    this._firmware, {
    this.printerModel,
    this.bmcuSerial,
  }) : super(_initial(_variants.read(bmcuSerial), printerModel));

  /// Modelo da impressora quando a tela abre pelo diagnostico; null pelo
  /// atalho USB da lista, onde nao da para saber.
  final String? printerModel;

  final VariantStore _variants;
  final FirmwareRepository _firmware;
  final String? bmcuSerial;

  static FlashStatus _initial(FirmwareVariant? saved, String? printerModel) =>
      saved == null
          ? FlashStatus(force: LoadForce.suggestedFor(printerModel ?? ''))
          : FlashStatus(
              force: saved.force,
              autoload: saved.autoload,
              rgb: saved.rgb,
              slot: saved.slot,
              retract: saved.retract,
              fromLastFlash: true,
            );

  Future<void> loadLatest() async {
    try {
      // Espera antes de ler o state: senao o copyWith usa o estado de antes
      // da rede e apaga o que mudou nesse meio tempo.
      final latest = await _firmware.latestVersion();
      emit(state.copyWith(latest: latest));
    } on Object {
      // Sem internet a tela segue sem o numero; o download avisa depois.
    }
  }

  Uint8List? _testBytes;

  /// Pagina de calibracao guardada (test_nvm.bin, ao lado do firmware de
  /// teste). So e gravada se o bootloader tiver apagado a NVM.
  Uint8List? _testNvm;

  /// Com o arquivo test_full_erase na pasta, o teste apaga a flash inteira
  /// e grava test_nvm.bin no lugar (para simular um canal sem calibracao).
  bool _testFullErase = false;

  Future<void> loadTestFirmware() async {
    if (!UsbSerialLink.supported) return;
    try {
      final path = await UsbSerialLink.testFirmwarePath();
      if (path == null) return;
      final file = File(path);
      if (!file.existsSync()) return;
      final bytes = await file.readAsBytes();
      _testBytes = bytes;
      final nvm = File('${file.parent.path}/test_nvm.bin');
      if (nvm.existsSync() && nvm.lengthSync() == 256) _testNvm = await nvm.readAsBytes();
      _testFullErase = _testNvm != null && File('${file.parent.path}/test_full_erase').existsSync();
      emit(state.copyWith(testFirmware: (size: bytes.length, sha: sha256Hex(bytes))));
    } on Object catch (e) {
      // Sem arquivo de teste a tela fica so com o fluxo normal.
      debugPrint('firmware de teste: $e');
    }
  }

  /// Grava o arquivo de teste. Nao salva como variante: na proxima
  /// atualizacao normal o app sugere o que estava antes.
  Future<void> startTest() async {
    final bytes = _testBytes;
    if (bytes == null || !state.canStartTest) return;
    emit(state.copyWith(step: FlashStep.flashing, fraction: 0, log: const []));
    emit(state.copyWith(
        log: [
      'arquivo de teste: ${bytes.length} bytes, sha256 ${state.testFirmware!.sha.substring(0, 12)}',
      if (_testNvm != null) 'calibracao guardada: sha256 ${sha256Hex(_testNvm!).substring(0, 12)}',
      if (_testFullErase) 'modo de teste: apaga tudo e grava a calibracao guardada',
    ]));
    await _flash(bytes, null, nvmRestore: _testNvm, keepSettings: !_testFullErase);
  }

  void setForce(LoadForce v) => emit(state.copyWith(force: v, fromLastFlash: false));
  void setAutoload(bool v) => emit(state.copyWith(autoload: v, fromLastFlash: false));
  void setRgb(bool v) => emit(state.copyWith(rgb: v, fromLastFlash: false));
  void setSlot(AmsSlot v) => emit(state.copyWith(slot: v, fromLastFlash: false));
  void setRetract(String v) => emit(state.copyWith(retract: v, fromLastFlash: false));
  void setSafety(bool v) => emit(state.copyWith(safetyConfirmed: v));

  /// Volta para a escolha mantendo a configuracao, para tentar de novo.
  void reset() => emit(FlashStatus(
        force: state.force,
        autoload: state.autoload,
        rgb: state.rgb,
        slot: state.slot,
        retract: state.retract,
        fromLastFlash: state.fromLastFlash,
        latest: state.latest,
        testFirmware: state.testFirmware,
      ));

  Future<void> start() async {
    final variant = state.variant;
    if (variant == null || !state.canStart) return;
    void log(String line) => emit(state.copyWith(log: [...state.log, line]));

    emit(state.copyWith(step: FlashStep.downloading, fraction: 0, log: const []));
    final Uint8List firmware;
    try {
      log('baixando ${variant.path}');
      firmware = await _firmware.download(
        variant,
        onProgress: (f) => emit(state.copyWith(fraction: f)),
      );
      log('${firmware.length} bytes, sha256 ${sha256Hex(firmware).substring(0, 12)} confere');
    } on Object catch (e) {
      return _fail(FlashFailureReason.download, e);
    }

    await _flash(firmware, variant);
  }

  Future<void> _flash(
    Uint8List firmware,
    FirmwareVariant? variant, {
    Uint8List? nvmRestore,
    bool keepSettings = true,
  }) async {
    void log(String line) => emit(state.copyWith(log: [...state.log, line]));
    final devices = await UsbSerialLink.list();
    // Prefere o CH340 do BMCU se tiver mais de um adaptador ligado.
    final device = devices.where((d) => d.isCh340).firstOrNull ?? devices.firstOrNull;
    if (device == null) return _fail(FlashFailureReason.noDevice, null);

    final UsbSerialLink link;
    try {
      link = await UsbSerialLink.open(device);
    } on PlatformException catch (e) {
      return _fail(
        e.code == 'denied' ? FlashFailureReason.permission : FlashFailureReason.flash,
        e.message,
      );
    }

    emit(state.copyWith(step: FlashStep.flashing, stage: FlashStage.connecting, fraction: 0));
    log('porta ${device.name} (${device.vid.toRadixString(16)}:${device.pid.toRadixString(16)})');
    try {
      await BmcuFlasher(link).flash(
        firmware,
        onProgress: (stage, f) => emit(state.copyWith(stage: stage, fraction: f)),
        onLog: log,
        nvmRestore: nvmRestore,
        keepSettings: keepSettings,
      );
      if (variant != null) await _variants.save(bmcuSerial, variant);
      emit(state.copyWith(step: FlashStep.done, fromLastFlash: variant != null || state.fromLastFlash));
    } on Object catch (e) {
      _fail(FlashFailureReason.flash, e);
    } finally {
      await link.close();
    }
  }

  void _fail(FlashFailureReason reason, Object? error) => emit(state.copyWith(
        step: FlashStep.failed,
        failure: reason,
        detail: error == null
            ? null
            : error is FlashException
                ? error.message
                : '$error',
      ));

  @override
  Future<void> close() {
    _firmware.close();
    return super.close();
  }
}
