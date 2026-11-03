import 'package:bmcu_flash/bmcu_flash.dart';

enum FlashStep { choose, downloading, flashing, done, failed }

/// Por que a gravacao parou. Enum e nao frase: o Cubit nao tem context.
enum FlashFailureReason { download, noDevice, permission, flash }

class FlashStatus {
  const FlashStatus({
    required this.force,
    this.autoload = true,
    this.rgb = true,
    this.slot = AmsSlot.auto,
    this.retract,
    this.fromLastFlash = false,
    this.safetyConfirmed = false,
    this.latest,
    this.step = FlashStep.choose,
    this.stage,
    this.fraction = 0,
    this.failure,
    this.detail,
    this.log = const [],
    this.testFirmware,
  });

  final LoadForce force;
  final bool autoload;
  final bool rgb;
  final AmsSlot slot;

  /// Sem padrao de proposito: depende do tubo de cada um, entao a pessoa
  /// tem que escolher (ou o app lembra da ultima gravacao).
  final String? retract;

  /// A configuracao veio do que foi gravado da ultima vez neste aparelho.
  final bool fromLastFlash;
  final bool safetyConfirmed;

  /// Versao publicada, como o sw_ver ('11.00.00.00'); null ate carregar.
  final String? latest;
  final FlashStep step;
  final FlashStage? stage;
  final double fraction;
  final FlashFailureReason? failure;
  final String? detail;
  final List<String> log;

  /// Firmware de teste achado na pasta do app (tamanho e sha256), para
  /// gravar builds experimentais sem passar pelo GitHub.
  final ({int size, String sha})? testFirmware;

  bool get busy => step == FlashStep.downloading || step == FlashStep.flashing;

  bool get canStart => retract != null && safetyConfirmed && !busy;

  bool get canStartTest => testFirmware != null && safetyConfirmed && !busy;

  FirmwareVariant? get variant => retract == null
      ? null
      : FirmwareVariant(
          force: force, autoload: autoload, rgb: rgb, slot: slot, retract: retract!);

  FlashStatus copyWith({
    LoadForce? force,
    bool? autoload,
    bool? rgb,
    AmsSlot? slot,
    String? retract,
    bool? fromLastFlash,
    bool? safetyConfirmed,
    String? latest,
    FlashStep? step,
    FlashStage? stage,
    double? fraction,
    FlashFailureReason? failure,
    String? detail,
    List<String>? log,
    ({int size, String sha})? testFirmware,
  }) =>
      FlashStatus(
        force: force ?? this.force,
        autoload: autoload ?? this.autoload,
        rgb: rgb ?? this.rgb,
        slot: slot ?? this.slot,
        retract: retract ?? this.retract,
        fromLastFlash: fromLastFlash ?? this.fromLastFlash,
        safetyConfirmed: safetyConfirmed ?? this.safetyConfirmed,
        latest: latest ?? this.latest,
        step: step ?? this.step,
        stage: stage ?? this.stage,
        fraction: fraction ?? this.fraction,
        failure: failure ?? this.failure,
        detail: detail ?? this.detail,
        log: log ?? this.log,
        testFirmware: testFirmware ?? this.testFirmware,
      );
}
