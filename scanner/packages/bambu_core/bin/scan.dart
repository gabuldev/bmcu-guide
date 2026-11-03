import 'dart:io';

import 'package:bambu_core/bambu_core.dart';

/// Scanner pela linha de comando, para testar o nucleo sem o app.
///
///   dart run bin/scan.dart                      # so procura impressoras
///   dart run bin/scan.dart IP SERIAL CODIGO     # le e diagnostica
Future<void> main(List<String> args) async {
  if (args.length < 3) {
    stdout.writeln('Procurando impressoras por 15 s...');
    await for (final p in PrinterDiscovery.scan()) {
      stdout.writeln('${p.modelName} ${p.ip} ${p.serial} fw ${p.firmware} '
          '(${p.connectMode})');
    }
    return;
  }

  final table = HmsTable.parse(
    File(Platform.environment['HMS_TABLE'] ?? 'test/fixtures/hms-bmcu.json')
        .readAsStringSync(),
  );
  final snapshot = await PrinterClient.read(
    ip: args[0],
    serial: args[1],
    accessCode: args[2],
  );
  final report = ScanReport.build(snapshot, table);

  if (report.bmcus.isEmpty) stdout.writeln('Nenhum BMCU encontrado.');
  for (final b in report.bmcus) {
    stdout.writeln('BMCU no AMS ${b.letter}: ${b.version} '
        '${b.outdated ? '(desatualizado, ultima ${b.latest})' : '(em dia)'}');
    for (final bug in b.knownBugs) {
      stdout.writeln('  bug corrigido depois: ${bug.textFor('pt-BR').title}');
    }
  }
  for (final f in report.findings) {
    final text = switch (f.lookup) {
      HmsKnown(:final problem) => problem.textFor('pt-BR').title,
      HmsPossible(:final problem) =>
        'talvez: ${problem.textFor('pt-BR').title}',
      HmsGenericAms(:final text) => text['pt-BR'],
      HmsUnknown() => 'sem explicacao para BMCU',
    };
    stdout.writeln('HMS ${f.event.display} [${f.severity.name}]: $text');
  }
}
