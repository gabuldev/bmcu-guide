import 'package:bambu_core/bambu_core.dart';

/// Por que a leitura falhou. Enum e nao frase: o Cubit nao tem context.
enum ReportFailureReason { badAccessCode, unreachable, noStatus }

sealed class ReportStatus {
  const ReportStatus();
}

class ReportLoading extends ReportStatus {
  const ReportLoading();
}

class ReportReady extends ReportStatus {
  const ReportReady(this.report, this.table);

  final ScanReport report;
  final HmsTable table;
}

class ReportFailure extends ReportStatus {
  const ReportFailure(this.reason, {this.detail});

  final ReportFailureReason reason;

  /// Texto cru, para quem for depurar. A tela mostra discreto.
  final String? detail;
}
