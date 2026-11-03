import 'package:bambu_core/bambu_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/hms_table_repository.dart';
import 'report_status.dart';

class ReportController extends Cubit<ReportStatus> {
  ReportController(this._tables, this.printer, this._accessCode)
      : super(const ReportLoading());

  final HmsTableRepository _tables;
  final DiscoveredPrinter printer;
  final String _accessCode;

  Future<void> read() async {
    emit(const ReportLoading());
    try {
      final table = await _tables.load();
      final snapshot = await PrinterClient.read(
        ip: printer.ip,
        serial: printer.serial,
        accessCode: _accessCode,
      );
      emit(ReportReady(
        ScanReport.build(
          snapshot,
          table,
          printerModel: printer.model.isEmpty ? null : printer.modelName,
        ),
        table,
      ));
    } on MqttRefused catch (e) {
      emit(ReportFailure(
        e.badAccessCode
            ? ReportFailureReason.badAccessCode
            : ReportFailureReason.unreachable,
        detail: '$e',
      ));
    } on PrinterNoStatus {
      emit(const ReportFailure(ReportFailureReason.noStatus));
    } catch (e) {
      // Porta fechada, sem rota, TLS recusado: para a pessoa, tudo e "nao
      // conectou", e a correcao e a mesma (LAN Only + reiniciar).
      emit(ReportFailure(ReportFailureReason.unreachable, detail: '$e'));
    }
  }
}
