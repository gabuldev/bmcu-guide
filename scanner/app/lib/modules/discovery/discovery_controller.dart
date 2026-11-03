import 'dart:async';

import 'package:bambu_core/bambu_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/access_code_store.dart';
import '../../core/multicast_lock.dart';
import 'discovery_status.dart';

class DiscoveryController extends Cubit<DiscoveryStatus> {
  DiscoveryController(this._codes) : super(const DiscoveryStatus());

  final AccessCodeStore _codes;
  StreamSubscription<DiscoveredPrinter>? _scan;

  /// Escuta os anuncios por 15 s. A impressora anuncia a cada poucos
  /// segundos, entao isso basta para achar todas da rede.
  Future<void> scan() async {
    if (state.scanning) return;
    emit(const DiscoveryStatus(scanning: true));
    await _scan?.cancel();
    await MulticastLock.acquire();
    _scan = PrinterDiscovery.scan().listen(
      (printer) => emit(state.copyWith(printers: [...state.printers, printer])),
      onError: (Object e) {
        MulticastLock.release();
        emit(state.copyWith(scanning: false, failureDetail: '$e'));
      },
      onDone: () {
        MulticastLock.release();
        emit(state.copyWith(scanning: false));
      },
    );
  }

  /// Impressora digitada a mao, para quando o roteador bloqueia os anuncios.
  void addManual(String ip, String serial) {
    emit(state.copyWith(printers: [
      ...state.printers.where((p) => p.serial != serial),
      DiscoveredPrinter(ip: ip, serial: serial, model: '', name: serial),
    ]));
  }

  String? savedCode(String serial) => _codes.read(serial);

  Future<void> saveCode(String serial, String code) =>
      _codes.save(serial, code);

  @override
  Future<void> close() async {
    // Cancelar nao dispara o onDone, entao o lock e solto aqui tambem.
    await _scan?.cancel();
    await MulticastLock.release();
    return super.close();
  }
}
