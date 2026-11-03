import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Forca de carregamento. Cada uma e uma pasta em firmwares/ no repositorio
/// do firmware (ver which_to_choose_mode.txt).
enum LoadForce {
  standard('standard(A1)'),
  soft('soft_load(A1)'),
  highForce('high_force_load(P1S)');

  const LoadForce(this.folder);

  final String folder;

  /// P1 e X1 tem o tubo PTFE longo e com curvas; o autor recomenda
  /// high_force para eles e standard para o resto.
  static LoadForce suggestedFor(String printerModel) =>
      printerModel.startsWith('P1') || printerModel.startsWith('X1')
          ? highForce
          : standard;
}

/// AMS_AUTO numera os BMCUs sozinho; A a D sao as variantes antigas fixas.
enum AmsSlot { auto, a, b, c, d }

/// Comprimentos de retracao publicados, medidos a partir do fim do
/// splitter do AMS dentro da impressora.
const retractLengths = <String, String>{
  '9.5 cm': '0.095f',
  '10 cm': '0.10f',
  '20 cm': '0.20f',
  '25 cm': '0.25f',
  '30 cm': '0.30f',
  '35 cm': '0.35f',
  '40 cm': '0.40f',
  '45 cm': '0.45f',
  '50 cm': '0.50f',
  '55 cm': '0.55f',
  '60 cm': '0.60f',
  '65 cm': '0.65f',
  '70 cm': '0.70f',
  '75 cm': '0.75f',
  '80 cm': '0.80f',
  '85 cm': '0.85f',
  '90 cm': '0.90f',
};

class FirmwareVariant {
  const FirmwareVariant({
    required this.force,
    required this.autoload,
    required this.rgb,
    required this.slot,
    required this.retract,
  });

  final LoadForce force;
  final bool autoload;
  final bool rgb;
  final AmsSlot slot;

  /// Chave de [retractLengths], por exemplo '9.5 cm'.
  final String retract;

  /// Caminho do .bin dentro de firmwares/, o mesmo usado no manifest.txt.
  String get path {
    final slotDir = slot == AmsSlot.auto ? 'AMS_AUTO' : 'AMS_${slot.name.toUpperCase()}';
    final file = 'ams_${slot.name}_${retractLengths[retract]}.bin';
    return '${force.folder}/${autoload ? 'AUTOLOAD' : 'NO_AUTOLOAD'}/'
        '${rgb ? 'FILAMENT_RGB_ON' : 'FILAMENT_RGB_OFF'}/$slotDir/$file';
  }

  Map<String, Object> toJson() => {
        'force': force.name,
        'autoload': autoload,
        'rgb': rgb,
        'slot': slot.name,
        'retract': retract,
      };

  static FirmwareVariant? fromJson(Map<String, dynamic> json) {
    final retract = json['retract'] as String?;
    if (!retractLengths.containsKey(retract)) return null;
    return FirmwareVariant(
      force: LoadForce.values.byName(json['force'] as String),
      autoload: json['autoload'] as bool,
      rgb: json['rgb'] as bool,
      slot: AmsSlot.values.byName(json['slot'] as String),
      retract: retract!,
    );
  }
}

class ManifestEntry {
  const ManifestEntry(this.sha256, this.crc32, this.size);

  final String sha256;
  final int crc32;
  final int size;

  /// Confere tamanho, CRC32 e SHA-256 como o flasher original.
  bool matches(Uint8List bytes) =>
      bytes.length == size &&
      crc32Of(bytes) == crc32 &&
      sha256Hex(bytes) == sha256;
}

/// manifest.txt: "SHA256 CRC32 TAMANHO CAMINHO" por linha, # comenta.
Map<String, ManifestEntry> parseManifest(String text) {
  final out = <String, ManifestEntry>{};
  for (final raw in const LineSplitter().convert(text)) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final parts = line.split(RegExp(r'\s+'));
    if (parts.length < 4) continue;
    final size = int.tryParse(parts[2]);
    final crc = int.tryParse(parts[1], radix: 16);
    if (size == null || crc == null || parts[0].length != 64) continue;
    out[parts.sublist(3).join(' ')] =
        ManifestEntry(parts[0].toLowerCase(), crc, size);
  }
  return out;
}

String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

int crc32Of(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final b in bytes) {
    crc ^= b;
    for (var k = 0; k < 8; k++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}

class FirmwareDownloadException implements Exception {
  const FirmwareDownloadException(this.message);

  final String message;

  @override
  String toString() => 'FirmwareDownloadException: $message';
}

/// Baixa do repositorio do firmware o mesmo arquivo que o BMCU Flasher
/// baixaria e so devolve se bater com o manifest.
class FirmwareRepository {
  FirmwareRepository({HttpClient? client}) : _client = client ?? HttpClient();

  static const base =
      'https://raw.githubusercontent.com/jarczakpawel/BMCU-C-PJARCZAK/refs/heads/main/';

  final HttpClient _client;

  /// Versao publicada, no formato do sw_ver da impressora ('11.00.00.00').
  Future<String> latestVersion() async =>
      utf8.decode(await _get('${base}version')).trim();

  Future<Uint8List> download(
    FirmwareVariant variant, {
    void Function(double fraction)? onProgress,
  }) async {
    final manifest = parseManifest(utf8.decode(await _get('${base}firmwares/manifest.txt')));
    final entry = manifest[variant.path];
    if (entry == null) {
      throw FirmwareDownloadException('variante nao publicada: ${variant.path}');
    }
    final url = '${base}firmwares/${variant.path.split('/').map(Uri.encodeComponent).join('/')}';
    final bytes = await _get(url, expected: entry.size, onProgress: onProgress);
    if (!entry.matches(bytes)) {
      throw const FirmwareDownloadException('o arquivo baixado nao confere com o manifest');
    }
    return bytes;
  }

  Future<Uint8List> _get(String url,
      {int? expected, void Function(double)? onProgress}) async {
    final request = await _client.getUrl(Uri.parse(url));
    final response = await request.close().timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      await response.drain<void>();
      throw FirmwareDownloadException('HTTP ${response.statusCode} em $url');
    }
    final total = expected ?? response.contentLength;
    final out = BytesBuilder(copy: false);
    await for (final chunk in response.timeout(const Duration(seconds: 30))) {
      out.add(chunk);
      if (total > 0) onProgress?.call((out.length / total).clamp(0, 1));
    }
    return out.takeBytes();
  }

  void close() => _client.close();
}
