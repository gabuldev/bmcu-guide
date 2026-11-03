import 'dart:io';

import 'package:bmcu_flash/bmcu_flash.dart';
import 'package:flutter/services.dart';

class UsbDevice {
  const UsbDevice(this.id, this.vid, this.pid, this.name);

  final String id;
  final int vid;
  final int pid;
  final String name;

  /// CH340, o conversor da placa do BMCU-370C.
  bool get isCh340 => vid == 0x1A86 && pid == 0x7523;
}

/// [SerialLink] sobre o canal nativo do Android (usb-serial-for-android).
class UsbSerialLink implements SerialLink {
  UsbSerialLink._();

  static const _channel = MethodChannel('bmcu_scanner/usb');

  /// So o Android tem USB host com driver de CH340 sem instalar nada.
  static bool get supported => Platform.isAndroid;

  static Future<List<UsbDevice>> list() async {
    final raw = await _channel.invokeListMethod<Map<Object?, Object?>>('list') ?? [];
    return [
      for (final d in raw)
        UsbDevice(d['id']! as String, d['vid']! as int, d['pid']! as int,
            d['name']! as String),
    ];
  }

  /// Onde o app procura um firmware de teste (adb push), na pasta do app.
  static Future<String?> testFirmwarePath() =>
      _channel.invokeMethod<String>('testFirmwarePath');

  /// Abre a porta; na primeira vez o Android pergunta se o app pode usar.
  static Future<UsbSerialLink> open(UsbDevice device) async {
    await _channel.invokeMethod<void>('open', {'id': device.id});
    return UsbSerialLink._();
  }

  @override
  Future<void> setBaud(int baud) => _channel.invokeMethod('setBaud', {'baud': baud});

  @override
  Future<void> setDtr(bool value) => _channel.invokeMethod('setDtr', {'value': value});

  @override
  Future<void> setRts(bool value) => _channel.invokeMethod('setRts', {'value': value});

  @override
  Future<void> write(Uint8List data) => _channel.invokeMethod('write', {'data': data});

  @override
  Future<Uint8List> read(Duration timeout) async =>
      await _channel.invokeMethod<Uint8List>('read', {'timeout': timeout.inMilliseconds}) ??
      Uint8List(0);

  @override
  Future<void> purge() => _channel.invokeMethod('purge');

  Future<void> close() => _channel.invokeMethod('close');
}
