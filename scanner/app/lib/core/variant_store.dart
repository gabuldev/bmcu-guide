import 'dart:convert';

import 'package:bmcu_flash/bmcu_flash.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lembra a variante gravada em cada BMCU. Nao da para ler isso do BMCU,
/// entao na proxima atualizacao o app sugere o que foi usado da ultima vez.
class VariantStore {
  VariantStore(this._prefs);

  final SharedPreferences _prefs;

  String _key(String? bmcuSerial) => 'variant_${bmcuSerial ?? 'last'}';

  FirmwareVariant? read(String? bmcuSerial) {
    final raw = _prefs.getString(_key(bmcuSerial)) ?? _prefs.getString(_key(null));
    if (raw == null) return null;
    try {
      return FirmwareVariant.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  /// Ultima impressora aberta. O atalho USB grava com o BMCU fora da
  /// impressora, entao usa isso para sugerir a forca e avisar se nao bate.
  String? get lastPrinterModel => _prefs.getString('printer_model_last');

  Future<void> rememberPrinter(String model) =>
      _prefs.setString('printer_model_last', model);

  Future<void> save(String? bmcuSerial, FirmwareVariant variant) async {
    final raw = jsonEncode(variant.toJson());
    await _prefs.setString(_key(null), raw);
    if (bmcuSerial != null) await _prefs.setString(_key(bmcuSerial), raw);
  }
}
