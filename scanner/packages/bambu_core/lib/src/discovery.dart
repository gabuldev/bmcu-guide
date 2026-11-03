import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Impressora Bambu anunciada na rede local.
class DiscoveredPrinter {
  const DiscoveredPrinter({
    required this.ip,
    required this.serial,
    required this.model,
    required this.name,
    this.firmware,
    this.connectMode,
  });

  final String ip;
  final String serial;

  /// Codigo interno do modelo, como `N1` (A1 mini). Ver [modelName].
  final String model;
  final String name;
  final String? firmware;

  /// `lan` ou `cloud`. Em `cloud` o MQTT local ainda pode recusar a conexao.
  final String? connectMode;

  bool get lanOnly => connectMode == 'lan';

  /// Nome comercial, quando conhecido. Codigos novos caem no proprio codigo.
  ///
  /// Escrito como a tabela de erros escreve (X1C, nao "X1 Carbon"), porque e
  /// por esse nome que os problemas sao filtrados por modelo.
  String get modelName => _modelNames[model] ?? model;

  static const _modelNames = {
    'N1': 'A1 mini',
    'N2S': 'A1',
    'C11': 'P1P',
    'C12': 'P1S',
    'BL-P001': 'X1C',
    'BL-P002': 'X1',
  };

  /// Le o NOTIFY que a impressora manda. Devolve null para qualquer outra
  /// coisa que apareca na porta.
  static DiscoveredPrinter? parse(String message) {
    final headers = <String, String>{};
    for (final line in const LineSplitter().convert(message)) {
      final i = line.indexOf(':');
      if (i <= 0) continue;
      headers[line.substring(0, i).trim().toLowerCase()] =
          line.substring(i + 1).trim();
    }
    if (!(headers['nt'] ?? '').contains('bambulab-com:device:3dprinter')) {
      return null;
    }
    final ip = headers['location'];
    final serial = headers['usn'];
    if (ip == null || serial == null) return null;
    return DiscoveredPrinter(
      ip: ip,
      serial: serial,
      model: headers['devmodel.bambu.com'] ?? '',
      name: headers['devname.bambu.com'] ?? serial,
      firmware: headers['devversion.bambu.com'],
      connectMode: headers['devconnect.bambu.com'],
    );
  }
}

/// Escuta os anuncios SSDP que as impressoras Bambu mandam na porta UDP 2021.
///
/// So escuta, nao pergunta: a impressora anuncia sozinha a cada poucos
/// segundos, e um M-SEARCH nao acelera nada na pratica. No Android isso exige
/// um multicast lock, que fica a cargo do app.
class PrinterDiscovery {
  static const port = 2021;

  static Stream<DiscoveredPrinter> scan({
    Duration timeout = const Duration(seconds: 15),
  }) async* {
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      port,
      reuseAddress: true,
    );
    final seen = <String>{};
    final timer = Timer(timeout, socket.close);
    try {
      await for (final event in socket) {
        if (event != RawSocketEvent.read) continue;
        final datagram = socket.receive();
        if (datagram == null) continue;
        final printer = DiscoveredPrinter.parse(
          utf8.decode(datagram.data, allowMalformed: true),
        );
        if (printer != null && seen.add(printer.serial)) yield printer;
      }
    } finally {
      timer.cancel();
      socket.close();
    }
  }
}
