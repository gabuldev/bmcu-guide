import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_injections/flutter_injections.dart';

import '../../core/access_code_store.dart';
import 'discovery_controller.dart';
import 'discovery_screen.dart';

class DiscoveryModule extends FlutterModule {
  const DiscoveryModule({super.key});

  @override
  List<Inject<Object>> get injections => [
        Inject<DiscoveryController>.lazySingleton(
          (i) => DiscoveryController(i.find<AccessCodeStore>()),
        ),
      ];

  @override
  Widget get child => BlocProvider(
        create: (_) => FlutterInjections.get<DiscoveryController>(),
        child: const DiscoveryScreen(),
      );
}
