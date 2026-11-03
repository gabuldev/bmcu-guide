import 'dart:io';

import 'package:flutter/services.dart';

/// Segura o multicast lock do Android enquanto a busca roda. Nas outras
/// plataformas nao faz nada.
class MulticastLock {
  static const _channel = MethodChannel('bmcu_scanner/multicast');

  static Future<void> acquire() async {
    if (Platform.isAndroid) await _channel.invokeMethod<void>('acquire');
  }

  static Future<void> release() async {
    if (Platform.isAndroid) await _channel.invokeMethod<void>('release');
  }
}
