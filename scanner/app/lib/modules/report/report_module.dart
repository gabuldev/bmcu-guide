import 'package:bambu_core/bambu_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_injections/flutter_injections.dart';

import '../../core/hms_table_repository.dart';
import 'report_controller.dart';
import 'report_screen.dart';

class ReportModule extends FlutterModule {
  const ReportModule({
    super.key,
    required this.printer,
    required this.accessCode,
  });

  final DiscoveredPrinter printer;
  final String accessCode;

  @override
  List<Inject<Object>> get injections => [
        Inject<ReportController>.lazySingleton(
          (i) => ReportController(
            i.find<HmsTableRepository>(),
            printer,
            accessCode,
          ),
        ),
      ];

  @override
  Widget get child => BlocProvider(
        create: (_) => FlutterInjections.get<ReportController>()..read(),
        child: const ReportScreen(),
      );
}
