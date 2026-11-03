import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Cliente MQTT 3.1.1 minimo: conectar, assinar e publicar com QoS 0.
///
/// Escrito aqui em vez de usar um pacote porque o scanner so precisa dessas
/// tres operacoes, e manter o nucleo sem dependencias deixa ele rodar igual
/// no app, nos testes e na linha de comando.
class MqttLite {
  MqttLite._(this._socket);

  final SecureSocket _socket;
  final _messages = StreamController<MqttMessage>.broadcast();
  final _buffer = BytesBuilder();
  Completer<int>? _connack;

  Stream<MqttMessage> get messages => _messages.stream;

  /// Conecta com TLS. A impressora usa certificado proprio, entao a cadeia
  /// nao e validada - a autenticacao de verdade e o codigo de acesso.
  static Future<MqttLite> connect({
    required String host,
    required String username,
    required String password,
    int port = 8883,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final socket = await SecureSocket.connect(
      host,
      port,
      timeout: timeout,
      onBadCertificate: (_) => true,
    );
    final client = MqttLite._(socket);
    socket.listen(
      client._onData,
      onError: client._messages.addError,
      onDone: client._messages.close,
    );

    client._connack = Completer<int>();
    client._send(0x10, [
      ..._string('MQTT'),
      4, // protocolo 3.1.1
      0xC2, // usuario + senha + clean session
      0, 60, // keep alive
      ..._string('bmcu-scanner-${DateTime.now().millisecondsSinceEpoch}'),
      ..._string(username),
      ..._string(password),
    ]);
    final code = await client._connack!.future.timeout(timeout);
    if (code != 0) {
      await client.close();
      throw MqttRefused(code);
    }
    return client;
  }

  void subscribe(String topic) =>
      _send(0x82, [0, 1, ..._string(topic), 0]);

  void publish(String topic, Object payload) =>
      _send(0x30, [..._string(topic), ...utf8.encode(jsonEncode(payload))]);

  Future<void> close() async {
    try {
      _send(0xE0, const []);
    } catch (_) {}
    await _socket.close();
  }

  void _send(int type, List<int> body) {
    _socket.add([type, ..._length(body.length), ...body]);
  }

  void _onData(Uint8List data) {
    _buffer.add(data);
    var bytes = _buffer.takeBytes();
    while (true) {
      final packet = _readPacket(bytes);
      if (packet == null) break;
      _handle(packet.type, packet.body);
      bytes = bytes.sublist(packet.size);
    }
    _buffer.add(bytes);
  }

  void _handle(int type, Uint8List body) {
    switch (type >> 4) {
      case 2: // CONNACK
        _connack?.complete(body.length > 1 ? body[1] : 0xFF);
      case 3: // PUBLISH (QoS 0, que e o que a impressora manda)
        final topicLength = (body[0] << 8) | body[1];
        final topic = utf8.decode(body.sublist(2, 2 + topicLength));
        final payload = body.sublist(2 + topicLength);
        _messages.add(MqttMessage(topic, payload));
    }
  }

  static ({int type, Uint8List body, int size})? _readPacket(Uint8List b) {
    if (b.length < 2) return null;
    var multiplier = 1, length = 0, i = 1;
    while (true) {
      if (i >= b.length) return null;
      final digit = b[i++];
      length += (digit & 0x7F) * multiplier;
      multiplier *= 128;
      if (digit & 0x80 == 0) break;
    }
    if (b.length < i + length) return null;
    return (type: b[0], body: b.sublist(i, i + length), size: i + length);
  }

  static List<int> _string(String s) {
    final bytes = utf8.encode(s);
    return [bytes.length >> 8, bytes.length & 0xFF, ...bytes];
  }

  static List<int> _length(int n) {
    final out = <int>[];
    do {
      var digit = n % 128;
      n ~/= 128;
      if (n > 0) digit |= 0x80;
      out.add(digit);
    } while (n > 0);
    return out;
  }
}

class MqttMessage {
  const MqttMessage(this.topic, this.payload);

  final String topic;
  final Uint8List payload;

  Map<String, dynamic>? get json {
    try {
      final value = jsonDecode(utf8.decode(payload));
      return value is Map<String, dynamic> ? value : null;
    } catch (_) {
      return null;
    }
  }
}

/// A impressora recusou a conexao. Codigos 4 e 5 sao usuario/senha: na
/// pratica, codigo de acesso errado.
class MqttRefused implements Exception {
  const MqttRefused(this.code);

  final int code;

  bool get badAccessCode => code == 4 || code == 5;

  @override
  String toString() => 'MqttRefused($code)';
}
