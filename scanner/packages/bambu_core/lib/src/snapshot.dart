/// O que a impressora respondeu ao `get_version` e ao `pushall`.
///
/// Guarda o JSON cru junto: o scanner le poucos campos, mas um relatorio
/// enviado por alguem com problema vale mais com tudo o que veio.
class PrinterSnapshot {
  const PrinterSnapshot({
    required this.modules,
    required this.amsUnits,
    required this.hms,
    required this.raw,
  });

  final List<PrinterModule> modules;
  final List<AmsUnit> amsUnits;
  final List<HmsEvent> hms;
  final Map<String, dynamic> raw;

  /// Monta a partir das mensagens `info` (get_version) e `print` (pushall),
  /// no formato salvo pelo scanner: `{"info": {...}, "print": {...}}`.
  factory PrinterSnapshot.fromJson(Map<String, dynamic> json) {
    final info = _map(json['info']);
    final print = _map(json['print']);
    final ams = _map(print['ams']);
    return PrinterSnapshot(
      modules: [
        for (final m in _list(info['module'])) PrinterModule.fromJson(_map(m)),
      ],
      amsUnits: [
        for (final a in _list(ams['ams'])) AmsUnit.fromJson(_map(a)),
      ],
      hms: [for (final h in _list(print['hms'])) HmsEvent.fromJson(_map(h))],
      raw: json,
    );
  }
}

class PrinterModule {
  const PrinterModule({
    required this.name,
    required this.swVer,
    required this.hwVer,
    required this.serial,
  });

  factory PrinterModule.fromJson(Map<String, dynamic> json) => PrinterModule(
        name: '${json['name'] ?? ''}',
        swVer: '${json['sw_ver'] ?? ''}',
        hwVer: '${json['hw_ver'] ?? ''}',
        serial: '${json['sn'] ?? ''}',
      );

  final String name;
  final String swVer;
  final String hwVer;
  final String serial;
}

class AmsUnit {
  const AmsUnit({
    required this.id,
    required this.temperature,
    required this.trays,
  });

  factory AmsUnit.fromJson(Map<String, dynamic> json) => AmsUnit(
        id: int.tryParse('${json['id']}') ?? 0,
        temperature: double.tryParse('${json['temp']}'),
        trays: [for (final t in _list(json['tray'])) Tray.fromJson(_map(t))],
      );

  /// 0 = AMS A, 1 = AMS B...
  final int id;
  final double? temperature;
  final List<Tray> trays;

  String get letter => String.fromCharCode(0x41 + id);
}

class Tray {
  const Tray({required this.id, this.type, this.color, this.infoIdx});

  factory Tray.fromJson(Map<String, dynamic> json) {
    final type = '${json['tray_type'] ?? ''}';
    final color = '${json['tray_color'] ?? ''}';
    return Tray(
      id: int.tryParse('${json['id']}') ?? 0,
      type: type.isEmpty ? null : type,
      color: color.length >= 6 ? color : null,
      infoIdx: json['tray_info_idx'] as String?,
    );
  }

  final int id;

  /// Null quando o slot esta vazio.
  final String? type;

  /// RRGGBBAA, como a impressora manda.
  final String? color;

  /// Perfil de filamento da Bambu (GFG00 = PETG generico).
  final String? infoIdx;

  /// O que o firmware do BMCU anuncia quando nao tem nada salvo no slot
  /// (valores padrao de ams.h): PETG generico branco.
  bool get isBmcuDefault =>
      type == 'PETG' && infoIdx == 'GFG00' && color?.toUpperCase() == 'FFFFFFFF';

  bool get loaded => type != null;
}

/// Um alerta HMS ativo. A impressora manda o codigo partido em dois inteiros;
/// [code] junta no formato de 16 digitos que a Bambu e a tabela usam.
class HmsEvent {
  const HmsEvent({required this.attr, required this.code});

  factory HmsEvent.fromJson(Map<String, dynamic> json) => HmsEvent(
        attr: (json['attr'] as num?)?.toInt() ?? 0,
        code: (json['code'] as num?)?.toInt() ?? 0,
      );

  final int attr;
  final int code;

  String get ecode =>
      '${_hex(attr >> 16)}${_hex(attr & 0xFFFF)}${_hex(code >> 16)}${_hex(code & 0xFFFF)}';

  /// Formato da wiki e da tela da impressora: 0500_0400_0001_0044.
  String get display {
    final e = ecode;
    return '${e.substring(0, 4)}_${e.substring(4, 8)}_'
        '${e.substring(8, 12)}_${e.substring(12)}';
  }

  static String _hex(int v) => v.toRadixString(16).toUpperCase().padLeft(4, '0');
}

Map<String, dynamic> _map(Object? v) =>
    v is Map<String, dynamic> ? v : const {};

List<Object?> _list(Object? v) => v is List ? v : const [];
