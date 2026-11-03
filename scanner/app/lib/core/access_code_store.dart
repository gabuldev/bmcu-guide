import 'package:shared_preferences/shared_preferences.dart';

/// Lembra o codigo de acesso de cada impressora, pelo numero de serie.
///
/// Fica so no aparelho. O codigo da acesso de leitura e controle na rede
/// local, entao nunca sai daqui.
class AccessCodeStore {
  AccessCodeStore(this._prefs);

  final SharedPreferences _prefs;

  String? read(String serial) => _prefs.getString('access_code_$serial');

  Future<void> save(String serial, String code) =>
      _prefs.setString('access_code_$serial', code);
}
