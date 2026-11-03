import 'package:bmcu_flash/bmcu_flash.dart';

/// Baixa uma variante e confere com o manifest, para testar sem o app.
Future<void> main() async {
  final repo = FirmwareRepository();
  const v = FirmwareVariant(
      force: LoadForce.standard, autoload: true, rgb: true, slot: AmsSlot.auto, retract: '9.5 cm');
  print('versao publicada: ${await repo.latestVersion()}');
  final bytes = await repo.download(v);
  print('${v.path}: ${bytes.length} bytes, sha ${sha256Hex(bytes).substring(0, 12)}');
  repo.close();
}
