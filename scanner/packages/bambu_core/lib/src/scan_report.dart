import 'hms_table.dart';
import 'snapshot.dart';

/// O diagnostico pronto para a tela: BMCUs encontrados e cada alerta ativo
/// ja explicado pela tabela.
class ScanReport {
  const ScanReport({
    required this.snapshot,
    required this.bmcus,
    required this.findings,
  });

  /// [printerModel] e o nome comercial ([DiscoveredPrinter.modelName]). Sem
  /// ele, os bugs conhecidos aparecem sem filtro de modelo.
  factory ScanReport.build(
    PrinterSnapshot snapshot,
    HmsTable table, {
    String? printerModel,
  }) {
    final bmcus = <BmcuUnit>[];
    for (final module in snapshot.modules) {
      if (!BmcuUnit.matches(module)) continue;
      final index = int.tryParse(module.name.split('/').last) ?? 0;
      final version = BmcuVersion.parse(module.swVer);
      bmcus.add(BmcuUnit(
        index: index,
        serial: module.serial,
        version: version,
        latest: table.latestVersion,
        knownBugs: [
          for (final p in table.bugsFixedAfter(version))
            if (printerModel == null || p.appliesTo(printerModel)) p,
        ],
        ams: snapshot.amsUnits.where((a) => a.id == index).firstOrNull,
      ));
    }
    return ScanReport(
      snapshot: snapshot,
      bmcus: bmcus,
      findings: [
        for (final event in snapshot.hms)
          HmsFinding(event, table.lookup(event.ecode)),
      ],
    );
  }

  final PrinterSnapshot snapshot;
  final List<BmcuUnit> bmcus;
  final List<HmsFinding> findings;

  /// Ha algum AMS na impressora que nao e BMCU (um AMS original, por ex.).
  bool get hasOtherAms => snapshot.modules.any(
        (m) => m.name.startsWith('ams') && !BmcuUnit.matches(m),
      );
}

class BmcuUnit {
  const BmcuUnit({
    required this.index,
    required this.serial,
    required this.version,
    required this.latest,
    required this.knownBugs,
    this.ams,
  });

  /// O BMCU responde como AMS com hw_ver AMS08 e serial gerado a partir do ID
  /// do chip, sempre comecando com 0ea. AMS original nao tem esse prefixo.
  static bool matches(PrinterModule m) =>
      m.name.startsWith('ams/') &&
      m.hwVer == 'AMS08' &&
      m.serial.toLowerCase().startsWith('0ea');

  final int index;
  final String serial;
  final BmcuVersion version;
  final BmcuVersion latest;

  /// Problemas da versao instalada que ja foram corrigidos depois.
  final List<HmsProblem> knownBugs;
  final AmsUnit? ams;

  bool get outdated => version < latest;

  /// Os quatro slots com o filamento padrao do firmware: a memoria do BMCU
  /// foi apagada, o que acontece ao gravar. A calibracao dos buffers fica na
  /// mesma area, entao provavelmente precisa recalibrar (LEDs vermelhos).
  /// A impressora nao informa a calibracao; isto e um indicio, nao certeza.
  bool get looksFreshlyFlashed {
    final trays = ams?.trays ?? const [];
    return trays.length == 4 && trays.every((t) => t.isBmcuDefault);
  }
  String get letter => String.fromCharCode(0x41 + index);
}

class HmsFinding {
  const HmsFinding(this.event, this.lookup);

  final HmsEvent event;
  final HmsLookup lookup;

  HmsSeverity get severity => switch (lookup) {
        HmsKnown(:final problem) || HmsPossible(:final problem) =>
          problem.severity,
        _ => HmsSeverity.warning,
      };
}
