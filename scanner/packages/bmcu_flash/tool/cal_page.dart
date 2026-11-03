// Monta a pagina de calibracao a partir dos numeros da telemetria.
// Uso: dart run tool/cal_page.dart saida.bin centros vmins vmaxs pols sensores
// [mascara]
// (cada lista com 4 valores separados por virgula, em mV; pol = 1 ou -1;
// mascara opcional dos canais validos, ex. 7 = so os canais 1 a 3)
import 'dart:io';

import 'package:bmcu_flash/bmcu_flash.dart';

void main(List<String> args) {
  List<int> ints(String s) => s.split(',').map(int.parse).toList();
  final cal = BufferCalibration.fromTelemetry(
    centerMv: ints(args[1]),
    vminMv: ints(args[2]),
    vmaxMv: ints(args[3]),
    polarity: ints(args[4]),
    keyIdleMv: ints(args[5]),
    validMask: args.length > 6 ? int.parse(args[6]) : 0x0F,
  );
  File(args[0]).writeAsBytesSync(cal.toPage());
  stdout.writeln('${args[0]}: 256 bytes, sha256 ${sha256Hex(cal.toPage()).substring(0, 12)}');
}
