import 'dart:convert';
import 'dart:io';

import 'package:bambu_core/bambu_core.dart';
import 'package:test/test.dart';

void main() {
  // Captura real de uma A1 mini 01.07.00.00 com BMCU V10.5, feita pelo
  // scanner em 2026-10-28.
  final snapshot = PrinterSnapshot.fromJson(
    jsonDecode(File('test/fixtures/a1mini_bmcu_v10_5.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final table =
      HmsTable.parse(File('test/fixtures/hms-bmcu.json').readAsStringSync());

  group('BMCU recem gravado', () {
    test('reconhece os slots padrao depois de gravar a v11', () {
      final fresh = PrinterSnapshot.fromJson(jsonDecode(
              File('test/fixtures/a1mini_bmcu_v11_fresh.json').readAsStringSync())
          as Map<String, dynamic>);
      final report = ScanReport.build(fresh, table);
      expect(report.bmcus.single.version, const BmcuVersion(11, 0));
      expect(report.bmcus.single.looksFreshlyFlashed, isTrue);
    });

    test('nao avisa quando ha filamento configurado', () {
      final report = ScanReport.build(snapshot, table);
      expect(report.bmcus.single.looksFreshlyFlashed, isFalse);
    });
  });

  group('BmcuVersion', () {
    test('le o sw_ver da impressora', () {
      expect(BmcuVersion.parse('10.50.00.00'), const BmcuVersion(10, 5));
      expect(BmcuVersion.parse('11.00.00.00'), const BmcuVersion(11, 0));
    });

    test('le a codificacao antiga da V6 a V9', () {
      expect(BmcuVersion.parse('90.00.00.00'), const BmcuVersion(9, 0));
      expect(BmcuVersion.parse('70.00.00.00'), const BmcuVersion(7, 0));
    });

    test('compara e escreve como o projeto', () {
      expect(const BmcuVersion(10, 5) < const BmcuVersion(11, 0), isTrue);
      expect('${const BmcuVersion(10, 5)}', 'V10.5');
      expect('${const BmcuVersion(11, 0)}', 'v11');
    });
  });

  group('DiscoveredPrinter', () {
    test('le o anuncio SSDP da impressora', () {
      final p = DiscoveredPrinter.parse('NOTIFY * HTTP/1.1\r\n'
          'Location: 192.168.1.50\r\n'
          'NT: urn:bambulab-com:device:3dprinter:1\r\n'
          'USN: 0309AA000000001\r\n'
          'DevModel.bambu.com: N1\r\n'
          'DevName.bambu.com: 3DP-030-179\r\n'
          'DevConnect.bambu.com: lan\r\n'
          'DevVersion.bambu.com: 01.07.00.00\r\n');
      expect(p!.ip, '192.168.1.50');
      expect(p.serial, '0309AA000000001');
      expect(p.modelName, 'A1 mini');
      expect(p.lanOnly, isTrue);
    });

    test('ignora o que nao e impressora Bambu', () {
      expect(DiscoveredPrinter.parse('NOTIFY * HTTP/1.1\r\nNT: upnp:rootdevice'),
          isNull);
    });
  });

  group('ScanReport', () {
    final report = ScanReport.build(snapshot, table);

    test('acha o BMCU e a versao', () {
      expect(report.bmcus, hasLength(1));
      final bmcu = report.bmcus.single;
      expect(bmcu.letter, 'A');
      expect(bmcu.version, const BmcuVersion(10, 5));
      expect(bmcu.outdated, isTrue);
      expect(bmcu.ams!.trays.where((t) => t.loaded), hasLength(4));
      expect(report.hasOtherAms, isFalse);
    });

    test('aponta os bugs que a atualizacao resolve', () {
      final ids = report.bmcus.single.knownBugs.map((p) => p.id);
      expect(ids, containsAll(['filament-info-reverts', 'unload-fails']));
      expect(ids, isNot(contains('slots-always-loaded'))); // corrigido na 10.3
    });

    test('filtra os bugs pelo modelo da impressora', () {
      final a1mini = ScanReport.build(snapshot, table, printerModel: 'A1 mini');
      final ids = a1mini.bmcus.single.knownBugs.map((p) => p.id);
      expect(ids, contains('filament-info-reverts'));
      expect(ids, isNot(contains('p1s-toolchange-no-retract')));

      final p1s = ScanReport.build(snapshot, table, printerModel: 'P1S');
      expect(p1s.bmcus.single.knownBugs.map((p) => p.id),
          contains('p1s-toolchange-no-retract'));
    });

    test('explica o alerta ativo como esperado', () {
      final finding = report.findings.single;
      expect(finding.event.display, '0500_0400_0001_0044');
      final lookup = finding.lookup as HmsKnown;
      expect(lookup.problem.id, 'ams-firmware-mismatch-warning');
      expect(lookup.problem.expected, isTrue);
      expect(finding.severity, HmsSeverity.info);
    });
  });

  group('HmsTable', () {
    test('codigo com AMS e slot no meio do padrao', () {
      final lookup = table.lookup('0701_2200_0002_0006');
      expect((lookup as HmsKnown).problem.id, 'load-rejected-ptfe-breakage');
    });

    test('codigo curto de erro do dispositivo', () {
      expect((table.lookup('0502409D') as HmsKnown).problem.id,
          'a1-0108-print-start-abort');
    });

    test('codigos marcados como possiveis', () {
      expect(table.lookup('0700600000020001'), isA<HmsPossible>());
    });

    test('erro de AMS fora da tabela cai no generico', () {
      expect(table.lookup('0700800000010003'), isA<HmsGenericAms>());
      expect(table.lookup('0300090000010003'), isA<HmsUnknown>());
    });

    test('reconhece peca que o BMCU nao tem', () {
      expect(table.isNotApplicable('The RFID-tag on AMS A Slot1 cannot be identified.'),
          isTrue);
    });
  });
}
