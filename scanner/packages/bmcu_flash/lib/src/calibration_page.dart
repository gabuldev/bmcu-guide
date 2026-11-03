import 'dart:typed_data';

/// Calibracao dos buffers como o firmware guarda em 0x0800F000
/// (Flash_saves.cpp, pagina 'CAL2' de 256 bytes). Tensoes em volts.
class BufferCalibration {
  const BufferCalibration({
    required this.offset,
    required this.vmin,
    required this.vmax,
    required this.keyNone,
    required this.polarity,
    this.validMask = 0x0F,
  });

  /// A partir dos numeros da telemetria: repouso, min e max em mV,
  /// polaridade (1 ou -1) e a tensao do sensor de filamento sem filamento.
  factory BufferCalibration.fromTelemetry({
    required List<int> centerMv,
    required List<int> vminMv,
    required List<int> vmaxMv,
    required List<int> polarity,
    required List<int> keyIdleMv,
    int validMask = 0x0F,
  }) =>
      BufferCalibration(
        offset: [for (final c in centerMv) _f32(1.65) - _f32(c / 1000)],
        vmin: [for (final v in vminMv) v / 1000],
        vmax: [for (final v in vmaxMv) v / 1000],
        keyNone: [for (final k in keyIdleMv) keyNoneFromIdle(k / 1000)],
        polarity: polarity,
        validMask: validMask,
      );

  final List<double> offset;
  final List<double> vmin;
  final List<double> vmax;
  final List<double> keyNone;
  final List<int> polarity;
  final int validMask;

  /// Mesma conta de dm_key_none_threshold_from_idle: centesimos para cima,
  /// mais 0,10 V, entre 0,60 e 1,39 V.
  static double keyNoneFromIdle(double v) {
    var cv = v <= 0 ? 0 : (_f32(_f32(v) * 100) - 0.0001).ceil();
    cv = (cv + 10).clamp(60, 139);
    return _f32(_f32(0.01) * cv);
  }

  static const magic = 0x324C4143; // 'CAL2'

  /// Pagina pronta para gravar. O resto da pagina vai com zeros: o firmware
  /// so confere o CRC, e zero nao depende de como a flash le o apagado.
  Uint8List toPage() {
    final page = ByteData(256);
    var rsv = (validMask & 0x0F) << 8;
    for (var ch = 0; ch < 4; ch++) {
      if (polarity[ch] < 0) rsv |= 1 << ch;
    }
    page
      ..setUint32(0, magic, Endian.little)
      ..setUint16(4, 2, Endian.little)
      ..setUint16(6, 64, Endian.little)
      ..setUint32(8, rsv, Endian.little);
    // NVM256_HDR e packed: magic, ver, len, rsv = 12 bytes.
    var o = 12;
    for (final list in [offset, vmin, vmax, keyNone]) {
      for (final v in list) {
        page.setFloat32(o, v, Endian.little);
        o += 4;
      }
    }
    final bytes = page.buffer.asUint8List();
    page.setUint32(252, stm32Crc(bytes.sublist(0, 252)), Endian.little);
    return bytes;
  }
}

double _f32(double v) => (Float32List(1)..[0] = v)[0];

/// CRC do periferico do CH32/STM32: palavras de 32 bits (little endian na
/// memoria), polinomio 0x04C11DB7, comeca em 0xFFFFFFFF, sem reflexao.
int stm32Crc(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (var i = 0; i + 3 < bytes.length; i += 4) {
    final word = bytes[i] | bytes[i + 1] << 8 | bytes[i + 2] << 16 | bytes[i + 3] << 24;
    crc ^= word;
    for (var b = 0; b < 32; b++) {
      crc = (crc & 0x80000000) != 0 ? ((crc << 1) ^ 0x04C11DB7) & 0xFFFFFFFF : (crc << 1) & 0xFFFFFFFF;
    }
  }
  return crc;
}
