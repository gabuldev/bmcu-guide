import 'package:bambu_core/bambu_core.dart';

class DiscoveryStatus {
  const DiscoveryStatus({
    this.printers = const [],
    this.scanning = false,
    this.failureDetail,
  });

  final List<DiscoveredPrinter> printers;
  final bool scanning;

  /// Texto cru de quando nao deu para abrir a porta UDP (outro programa
  /// usando, permissao de rede local negada...).
  final String? failureDetail;

  DiscoveryStatus copyWith({
    List<DiscoveredPrinter>? printers,
    bool? scanning,
    String? failureDetail,
  }) =>
      DiscoveryStatus(
        printers: printers ?? this.printers,
        scanning: scanning ?? this.scanning,
        failureDetail: failureDetail ?? this.failureDetail,
      );
}
