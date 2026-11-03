import 'dart:convert';
import 'dart:io';

import 'package:bambu_core/bambu_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Entrega a tabela de erros mais nova que estiver ao alcance.
///
/// Ordem: a publicada no bmcu-guide, a ultima baixada, a que veio no app.
/// Assim uma explicacao corrigida chega em todo mundo sem versao nova do app,
/// e sem internet o scanner continua funcionando.
class HmsTableRepository {
  HmsTableRepository(this._prefs);

  final SharedPreferences _prefs;
  HmsTable? _loaded;

  static const _remoteUrl =
      'https://raw.githubusercontent.com/gabuldev/bmcu-guide/main/data/hms-bmcu.json';
  static const _cacheKey = 'hms_table_json';

  Future<HmsTable> load() async {
    if (_loaded != null) return _loaded!;
    final remote = await _download();
    if (remote != null) {
      await _prefs.setString(_cacheKey, remote);
      return _loaded = HmsTable.parse(remote);
    }
    final cached = _prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        return _loaded = HmsTable.parse(cached);
      } catch (e) {
        debugPrint('Tabela em cache invalida ($e); usando a do app.');
      }
    }
    return _loaded =
        HmsTable.parse(await rootBundle.loadString('assets/hms-bmcu.json'));
  }

  Future<String?> _download() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.getUrl(Uri.parse(_remoteUrl));
      final response = await request.close().timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final body = await response.transform(utf8.decoder).join();
      HmsTable.parse(body); // so aceita se for uma tabela valida
      return body;
    } catch (e) {
      debugPrint('Tabela remota indisponivel ($e).');
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
