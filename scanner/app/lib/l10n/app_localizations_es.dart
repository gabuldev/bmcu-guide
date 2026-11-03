// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'BMCU Scanner';

  @override
  String get discoveryTitle => 'Impresoras en la red';

  @override
  String get discoveryScanning => 'Buscando impresoras Bambu en la red...';

  @override
  String get discoveryEmpty =>
      'No se encontró ninguna impresora. Comprueba que este dispositivo está en la misma red que la impresora.';

  @override
  String get discoveryRescan => 'Buscar de nuevo';

  @override
  String discoveryFailed(String detail) {
    return 'No se pudo escuchar la red: $detail';
  }

  @override
  String get discoveryCloudMode =>
      'Modo nube — activa LAN Only + Developer Mode';

  @override
  String get discoveryLanMode => 'LAN Only';

  @override
  String get discoveryAddManual => 'Añadir por IP';

  @override
  String get manualIp => 'IP de la impresora';

  @override
  String get manualSerial => 'Número de serie';

  @override
  String get accessCodeTitle => 'Código de acceso';

  @override
  String get accessCodeHint =>
      'En la pantalla de la impresora: Ajustes → WLAN / LAN Only.';

  @override
  String get accessCodeLabel => 'Código (8 dígitos)';

  @override
  String get cancel => 'Cancelar';

  @override
  String get scan => 'Escanear';

  @override
  String get setupTitle => 'Antes de escanear';

  @override
  String get setupSteps =>
      '1. En la impresora, activa LAN Only y Developer Mode.\n2. Reinicia la impresora después de activarlos.\n3. Anota el código de acceso que aparece en la misma pantalla.';

  @override
  String get reportTitle => 'Diagnóstico';

  @override
  String get reportReading => 'Leyendo la impresora...';

  @override
  String get reportRetry => 'Intentar de nuevo';

  @override
  String get failureBadCode =>
      'Código de acceso rechazado. Revisa el código en la pantalla de la impresora.';

  @override
  String get failureUnreachable =>
      'No se pudo conectar con la impresora. Activa LAN Only + Developer Mode y reinicia la impresora.';

  @override
  String get failureNoStatus =>
      'La impresora se conectó pero no envió su estado. Inténtalo de nuevo.';

  @override
  String get noBmcu => 'No se encontró ningún BMCU en esta impresora.';

  @override
  String bmcuTitle(String letter) {
    return 'BMCU en el AMS $letter';
  }

  @override
  String bmcuUpToDate(String version) {
    return 'Firmware al día ($version)';
  }

  @override
  String bmcuOutdated(String installed, String latest) {
    return '$installed instalado — $latest disponible';
  }

  @override
  String get bmcuKnownBugs =>
      'Problemas de tu versión que la actualización resuelve:';

  @override
  String get bmcuUpdate => 'Cómo actualizar';

  @override
  String get slotEmpty => 'vacío';

  @override
  String get findingsTitle => 'Alertas de la impresora';

  @override
  String get findingsNone => 'No hay alertas activas.';

  @override
  String get findingExpected => 'Esperado con BMCU';

  @override
  String get findingPossible => 'Posible causa';

  @override
  String get findingGeneric => 'Error de AMS';

  @override
  String get findingUnknown => 'Aún sin explicación para BMCU';

  @override
  String get findingOfficial => 'Texto de Bambu';

  @override
  String get severityInfo => 'Informativo';

  @override
  String get severityWarning => 'Atención';

  @override
  String get severityBlocking => 'Impide imprimir';

  @override
  String get findingSources => 'Reportes:';

  @override
  String get bmcuFlashUsb => 'Actualizar por USB';

  @override
  String get discoveryFlashUsb => 'Grabar BMCU por USB';

  @override
  String get flashTitle => 'Actualizar BMCU';

  @override
  String flashIntro(String version) {
    return 'La app descarga el firmware $version del proyecto oficial, verifica el archivo y lo graba en el BMCU por el cable USB.';
  }

  @override
  String get flashIntroNoVersion =>
      'La app descarga el firmware más reciente del proyecto oficial, verifica el archivo y lo graba en el BMCU por el cable USB.';

  @override
  String get variantTitle => 'Configuración del firmware';

  @override
  String get variantHint =>
      'Elige la misma configuración que usas hoy. El BMCU no informa cuál se grabó, así que la app solo la recuerda después de la primera grabación desde aquí.';

  @override
  String get variantFromLast =>
      'Misma configuración de la última grabación desde este dispositivo.';

  @override
  String get forceLabel => 'Fuerza de carga';

  @override
  String get forceStandard => 'Estándar (A1)';

  @override
  String get forceSoft => 'Suave (A1)';

  @override
  String get forceHigh => 'Fuerte (P1S/X1)';

  @override
  String get forceStandardHelp =>
      'Para A1 y A1 mini con tubo PTFE corto y recto. Si dudas, empieza aquí.';

  @override
  String get forceSoftHelp =>
      'Solo A1 y A1 mini: menos fuerza, para cuando el BMCU chasquea o muele el filamento al cargar. Puede causar rechazo de carga.';

  @override
  String get forceHighHelp =>
      'Para P1S y recorridos de PTFE largos o con curvas, o si la carga es rechazada.';

  @override
  String forceMismatch(String model, String suggested) {
    return 'Esta impresora es $model: lo indicado es “$suggested”.';
  }

  @override
  String get autoloadLabel => 'AUTOLOAD';

  @override
  String get autoloadHelp =>
      'Introduce el filamento solo al tocar el BMCU. Funciona en cualquier BMCU-370C; sin él, empujas hasta que aparece en el tubo.';

  @override
  String get rgbLabel => 'LED del color del filamento';

  @override
  String get rgbHelp =>
      'El LED de cada canal se enciende del color del filamento cargado.';

  @override
  String get slotLabel => 'Número de AMS';

  @override
  String get slotAuto => 'Automático (recomendado)';

  @override
  String get retractLabel => 'Retracción';

  @override
  String get retractHelp =>
      'Distancia del BMCU al final del divisor (splitter) dentro de la impresora, con un pequeño margen. Ej.: 9 cm hasta el divisor → 9,5 cm.';

  @override
  String get retractMissing => 'Elige la retracción para continuar.';

  @override
  String get safetyTitle => 'Antes de conectar el cable';

  @override
  String get safetySteps =>
      '1. Apaga la impresora.\n2. Desconecta el BMCU de la impresora.\n3. Conecta el BMCU a este dispositivo con un cable USB OTG.\n\nConectar o desconectar con la impresora encendida puede dañar el BMCU o la placa de la impresora.';

  @override
  String get safetyConfirm =>
      'La impresora está apagada y el BMCU está conectado solo a este dispositivo.';

  @override
  String flashStart(String version) {
    return 'Grabar $version';
  }

  @override
  String get flashStartNoVersion => 'Grabar firmware';

  @override
  String get stageDownloading => 'Descargando el firmware...';

  @override
  String get stageConnecting => 'Entrando en modo de grabación...';

  @override
  String get stageUnlocking => 'Desbloqueando la grabación...';

  @override
  String get stageErasing => 'Borrando el firmware anterior...';

  @override
  String get stageWriting => 'Grabando...';

  @override
  String get stageVerifying => 'Verificando...';

  @override
  String get flashDontUnplug =>
      'No desconectes el cable ni salgas de esta pantalla.';

  @override
  String flashDone(String version) {
    return 'BMCU actualizado a $version';
  }

  @override
  String get flashDoneNoVersion => 'BMCU actualizado';

  @override
  String get flashDoneSteps =>
      '1. Desconecta el BMCU de este dispositivo y conéctalo a la impresora apagada.\n2. La primera actualización con esta app suele borrar la calibración de los buffers (el chip venía protegido). Las siguientes deberían mantenerla.\n3. Si los LED quedan rojos, hay que calibrar los buffers: abre el diagnóstico, muestra cómo.\n\nDespués, escanea de nuevo para confirmar la versión.';

  @override
  String get flashBack => 'Volver';

  @override
  String get flashFailDownload =>
      'No se pudo descargar el firmware. Revisa internet e inténtalo de nuevo.';

  @override
  String get flashFailNoDevice =>
      'No se encontró ningún BMCU por USB. Revisa el cable OTG y si el BMCU se encendió.';

  @override
  String get flashFailPermission =>
      'Android no dio permiso para usar el USB. Inténtalo de nuevo y toca Permitir.';

  @override
  String get flashFailFlash =>
      'La grabación se detuvo a mitad. El modo de grabación del BMCU no se borra, así que solo inténtalo de nuevo; hasta entonces queda sin firmware.';

  @override
  String get flashDetails => 'Detalles';

  @override
  String get reportChangeCode => 'Cambiar código de acceso';

  @override
  String get bmcuFreshTitle => '¿LED rojos? Calibra los buffers';

  @override
  String get bmcuFreshSteps =>
      'Los 4 slots tienen el filamento por defecto del firmware, señal de que la memoria del BMCU se borró (BMCU Flasher borra todo al grabar). Eso borra la calibración de los buffers: hasta calibrar, los LED quedan rojos y los motores no giran. Sin calibración guardada, el BMCU calibra solo al encender, pero solo si ningún canal tiene filamento.\n\n1. Saca el filamento de todos los canales (pasando el sensor del BMCU). Revisa que no haya quedado un trozo roto dentro.\n2. Apaga y enciende la impresora sin tocar los buffers.\n3. Los LED parpadean amarillo ~1 s leyendo el reposo. Si parpadean rojo dos veces, aún hay filamento o un buffer se movió: revisa y reinicia.\n4. Cuando el LED del canal parpadee azul, empuja el buffer hasta el fondo 1 s y suelta.\n5. Cuando parpadee rojo, tira hasta el fondo 1 s y suelta.\n6. Repite en los demás canales (30 s por paso) y deja todo suelto: dos parpadeos verdes indican que guardó.';

  @override
  String get testFirmwareTitle => 'Firmware de prueba';

  @override
  String testFirmwareBody(int size, String sha) {
    return 'Encontré un archivo de prueba en la carpeta de la app ($size bytes, sha256 $sha). Es una compilación experimental, fuera de las versiones publicadas.';
  }

  @override
  String get testFirmwareStart => 'Grabar archivo de prueba';
}
