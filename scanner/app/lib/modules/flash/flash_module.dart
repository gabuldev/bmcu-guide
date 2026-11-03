import 'package:bmcu_flash/bmcu_flash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_injections/flutter_injections.dart';

import '../../core/variant_store.dart';
import 'flash_controller.dart';
import 'flash_screen.dart';

class FlashModule extends FlutterModule {
  const FlashModule({super.key, this.printerModel, this.bmcuSerial});

  /// Nome do modelo (ex. 'A1 mini'), para sugerir a forca de carregamento.
  final String? printerModel;
  final String? bmcuSerial;

  @override
  List<Inject<Object>> get injections => [
        Inject<FlashController>.lazySingleton(
          (i) => FlashController(
            i.find<VariantStore>(),
            FirmwareRepository(),
            printerModel: printerModel ?? i.find<VariantStore>().lastPrinterModel,
            bmcuSerial: bmcuSerial,
          ),
        ),
      ];

  @override
  Widget get child => BlocProvider(
        create: (_) => FlutterInjections.get<FlashController>()..loadLatest()
          ..loadTestFirmware(),
        child: const FlashScreen(),
      );
}
