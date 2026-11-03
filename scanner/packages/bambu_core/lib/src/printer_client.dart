import 'dart:async';

import 'mqtt_lite.dart';
import 'snapshot.dart';

/// Le o estado da impressora pelo MQTT local. So leitura: manda `pushall` e
/// `get_version`, nunca um comando que mexa na maquina.
class PrinterClient {
  /// Exige LAN Only + Developer Mode na impressora. Sem isso a porta 8883
  /// pode nem abrir, ou recusar o codigo de acesso.
  static Future<PrinterSnapshot> read({
    required String ip,
    required String serial,
    required String accessCode,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final client = await MqttLite.connect(
      host: ip,
      username: 'bblp',
      password: accessCode,
    );
    try {
      final got = <String, dynamic>{};
      final done = Completer<void>();
      final sub = client.messages.listen((message) {
        final json = message.json;
        if (json == null) return;
        final info = json['info'];
        if (info is Map && info['command'] == 'get_version') {
          got['info'] = info;
        }
        // A impressora manda pushes parciais o tempo todo; so o pushall
        // completo traz o bloco `ams` inteiro.
        final print = json['print'];
        if (print is Map &&
            print['command'] == 'push_status' &&
            print.containsKey('ams')) {
          got['print'] = print;
        }
        if (got.containsKey('info') && got.containsKey('print')) {
          if (!done.isCompleted) done.complete();
        }
      });

      client.subscribe('device/$serial/report');
      final request = 'device/$serial/request';
      client.publish(request, {
        'pushing': {'sequence_id': '1', 'command': 'pushall'},
      });
      client.publish(request, {
        'info': {'sequence_id': '2', 'command': 'get_version'},
      });

      await done.future.timeout(timeout, onTimeout: () {});
      await sub.cancel();
      if (!got.containsKey('print')) throw const PrinterNoStatus();
      return PrinterSnapshot.fromJson(got);
    } finally {
      await client.close();
    }
  }
}

/// Conectou, mas a impressora nao mandou o status no tempo esperado.
class PrinterNoStatus implements Exception {
  const PrinterNoStatus();
}
