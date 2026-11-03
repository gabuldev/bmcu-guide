import 'dart:convert';
import 'dart:io';

import 'package:bambu_core/bambu_core.dart';
import 'package:bmcu_scanner/core/hms_table_repository.dart';
import 'package:bmcu_scanner/l10n/app_localizations.dart';
import 'package:bmcu_scanner/modules/report/report_controller.dart';
import 'package:bmcu_scanner/modules/report/report_screen.dart';
import 'package:bmcu_scanner/modules/report/report_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller que nao fala com a impressora: a tela recebe o estado pronto.
class _FixedReport extends ReportController {
  _FixedReport(super.tables, super.printer, super.accessCode, ReportStatus s) {
    emit(s);
  }

  @override
  Future<void> read() async {}
}

void main() {
  const printer = DiscoveredPrinter(
    ip: '192.168.1.50',
    serial: '0309AA000000001',
    model: 'N1',
    name: '3DP-030-179',
    firmware: '01.07.00.00',
    connectMode: 'lan',
  );

  Future<void> pump(WidgetTester tester, Locale locale) async {
    // Tela alta: o ListView so constroi o que cabe, e os alertas ficam no fim.
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final table = HmsTable.parse(File('assets/hms-bmcu.json').readAsStringSync());
    final snapshot = PrinterSnapshot.fromJson(jsonDecode(
            File('test/fixtures/a1mini_bmcu_v10_5.json').readAsStringSync())
        as Map<String, dynamic>);
    final report = ScanReport.build(snapshot, table, printerModel: 'A1 mini');
    final controller = _FixedReport(
      HmsTableRepository(await SharedPreferences.getInstance()),
      printer,
      'x',
      ReportReady(report, table),
    );
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<ReportController>.value(
        value: controller,
        child: const ReportScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra BMCU desatualizado e explica o alerta', (tester) async {
    await pump(tester, const Locale('pt'));
    expect(find.text('BMCU no AMS A'), findsOneWidget);
    expect(find.text('V10.5 instalado — v11 disponível'), findsOneWidget);
    expect(find.textContaining('Cor/tipo do filamento volta'), findsOneWidget);
    expect(find.textContaining('P1S: troca de cor'), findsNothing);
    expect(find.text('Aviso de firmware do AMS incompatível'), findsOneWidget);
    expect(find.text('0500_0400_0001_0044 · Informativo · Esperado com BMCU'), findsOneWidget);
    expect(find.text('PETG'), findsNWidgets(2));
  });

  testWidgets('usa o texto da tabela no idioma do app', (tester) async {
    await pump(tester, const Locale('es'));
    expect(find.text('Aviso de firmware del AMS incompatible'), findsOneWidget);
  });
}
