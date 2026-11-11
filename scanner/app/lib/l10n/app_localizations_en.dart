// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'BMCU Scanner';

  @override
  String get discoveryTitle => 'Printers on the network';

  @override
  String get discoveryScanning =>
      'Looking for Bambu printers on the network...';

  @override
  String get discoveryEmpty =>
      'No printer found. Make sure this device is on the same network as the printer.';

  @override
  String get discoveryRescan => 'Search again';

  @override
  String discoveryFailed(String detail) {
    return 'Could not listen on the network: $detail';
  }

  @override
  String get discoveryCloudMode =>
      'Cloud mode — enable LAN Only + Developer Mode';

  @override
  String get discoveryLanMode => 'LAN Only';

  @override
  String get discoveryAddManual => 'Add by IP';

  @override
  String get manualIp => 'Printer IP';

  @override
  String get manualSerial => 'Serial number';

  @override
  String get accessCodeTitle => 'Access code';

  @override
  String get accessCodeHint =>
      'On the printer screen: Settings → WLAN / LAN Only.';

  @override
  String get accessCodeLabel => 'Code (8 digits)';

  @override
  String get cancel => 'Cancel';

  @override
  String get scan => 'Scan';

  @override
  String get setupTitle => 'Before scanning';

  @override
  String get setupSteps =>
      '1. On the printer, enable LAN Only and Developer Mode.\n2. Restart the printer after enabling them.\n3. Note the access code shown on the same screen.';

  @override
  String get reportTitle => 'Diagnosis';

  @override
  String get reportReading => 'Reading the printer...';

  @override
  String get reportRetry => 'Try again';

  @override
  String get failureBadCode =>
      'Access code rejected. Check the code on the printer screen.';

  @override
  String get failureUnreachable =>
      'Could not connect to the printer. Enable LAN Only + Developer Mode and restart the printer.';

  @override
  String get failureNoStatus =>
      'The printer connected but did not send its status. Try again.';

  @override
  String get noBmcu => 'No BMCU found on this printer.';

  @override
  String bmcuTitle(String letter) {
    return 'BMCU on AMS $letter';
  }

  @override
  String bmcuUpToDate(String version) {
    return 'Firmware up to date ($version)';
  }

  @override
  String bmcuOutdated(String installed, String latest) {
    return '$installed installed — $latest available';
  }

  @override
  String get bmcuKnownBugs => 'Problems in your version that updating fixes:';

  @override
  String get bmcuUpdate => 'How to update';

  @override
  String get slotEmpty => 'empty';

  @override
  String get findingsTitle => 'Printer alerts';

  @override
  String get findingsNone => 'No active alerts.';

  @override
  String get findingExpected => 'Expected with BMCU';

  @override
  String get findingPossible => 'Possible cause';

  @override
  String get findingGeneric => 'AMS error';

  @override
  String get findingUnknown => 'No BMCU explanation yet';

  @override
  String get findingOfficial => 'Bambu\'s text';

  @override
  String get severityInfo => 'Info';

  @override
  String get severityWarning => 'Warning';

  @override
  String get severityBlocking => 'Blocks printing';

  @override
  String get findingSources => 'Reports:';

  @override
  String get bmcuFlashUsb => 'Update over USB';

  @override
  String get discoveryFlashUsb => 'Flash BMCU over USB';

  @override
  String get flashTitle => 'Update BMCU';

  @override
  String flashIntro(String version) {
    return 'The app downloads firmware $version from the official project, checks the file and flashes it to the BMCU over the USB cable.';
  }

  @override
  String get flashIntroNoVersion =>
      'The app downloads the latest firmware from the official project, checks the file and flashes it to the BMCU over the USB cable.';

  @override
  String get variantTitle => 'Firmware settings';

  @override
  String get variantHint =>
      'Pick the same settings you use today. The BMCU does not report which ones were flashed, so the app only remembers after the first flash from here.';

  @override
  String get variantFromLast =>
      'Same settings as the last flash from this device.';

  @override
  String get forceLabel => 'Loading force';

  @override
  String get forceStandard => 'Standard (A1)';

  @override
  String get forceSoft => 'Soft (A1)';

  @override
  String get forceHigh => 'Strong (P1S/X1)';

  @override
  String get forceStandardHelp =>
      'For A1 and A1 mini with a short, straight PTFE tube. If unsure, start here.';

  @override
  String get forceSoftHelp =>
      'A1 and A1 mini only: less force, for when the BMCU clicks or grinds while loading. May cause rejected loads.';

  @override
  String get forceHighHelp =>
      'For P1S and long or curved PTFE paths, or if loading gets rejected.';

  @override
  String forceMismatch(String model, String suggested) {
    return 'This printer is a $model: “$suggested” is recommended.';
  }

  @override
  String get autoloadLabel => 'AUTOLOAD';

  @override
  String get autoloadHelp =>
      'Pulls the filament in by itself when it touches the BMCU. Works on any BMCU-370C; without it, you push until it shows in the tube.';

  @override
  String get rgbLabel => 'LED in filament color';

  @override
  String get rgbHelp =>
      'Each channel LED lights up in the loaded filament color.';

  @override
  String get slotLabel => 'AMS number';

  @override
  String get slotAuto => 'Automatic (recommended)';

  @override
  String get retractLabel => 'Retraction';

  @override
  String get retractHelp =>
      'Distance from the BMCU to the end of the splitter inside the printer, plus a small margin. E.g. 9 cm to the splitter → 9.5 cm.';

  @override
  String get retractMissing => 'Pick the retraction to continue.';

  @override
  String get safetyTitle => 'Before plugging the cable';

  @override
  String get safetySteps =>
      '1. Remove the filament from every channel, past the BMCU sensor.\n2. Turn the printer off.\n3. Disconnect the BMCU from the printer.\n4. Plug the BMCU into this device with a USB OTG cable.\n\nPlugging or unplugging with the printer on can damage the BMCU or the printer mainboard.';

  @override
  String get safetyConfirm =>
      'The printer is off and the BMCU is connected only to this device.';

  @override
  String flashStart(String version) {
    return 'Flash $version';
  }

  @override
  String get flashStartNoVersion => 'Flash firmware';

  @override
  String get stageDownloading => 'Downloading firmware...';

  @override
  String get stageConnecting => 'Entering flash mode...';

  @override
  String get stageUnlocking => 'Unlocking flash...';

  @override
  String get stageErasing => 'Erasing old firmware...';

  @override
  String get stageWriting => 'Writing...';

  @override
  String get stageVerifying => 'Verifying...';

  @override
  String get flashDontUnplug => 'Do not unplug the cable or leave this screen.';

  @override
  String flashDone(String version) {
    return 'BMCU updated to $version';
  }

  @override
  String get flashDoneNoVersion => 'BMCU updated';

  @override
  String get flashDoneSteps =>
      'Calibrate the buffers now, still on this cable and before connecting to the printer. Coming from V10.5 or older, calibration always has to be redone, because V11 stores it in a different format. Without calibration the LEDs stay red, the motors do not turn and the printer may not recognize the BMCU.\n\n1. Make sure no channel has filament.\n2. The LEDs blink yellow while the BMCU reads the rest position. Do not touch the buffers.\n3. When a channel LED blinks blue, push its buffer all the way in for 1 s and release.\n4. When it blinks red, pull it all the way out for 1 s and release.\n5. Repeat on the other channels and leave everything free. Two green blinks mean it was saved.\n\nIf it blinks red twice or a step times out (30 s each), unplug the cable, wait 5 s and plug it back in to start over.\n\nThen, with the printer off, connect the BMCU to it, turn the printer on and scan again to confirm the version.';

  @override
  String get flashBack => 'Back';

  @override
  String get flashFailDownload =>
      'Could not download the firmware. Check your internet and try again.';

  @override
  String get flashFailNoDevice =>
      'No BMCU found on USB. Check the OTG cable and whether the BMCU lit up.';

  @override
  String get flashFailPermission =>
      'Android did not grant USB access. Try again and tap Allow.';

  @override
  String get flashFailFlash =>
      'Flashing stopped halfway. The BMCU flash mode cannot be erased, so just try again; until then it has no firmware.';

  @override
  String get flashDetails => 'Details';

  @override
  String get reportChangeCode => 'Change access code';

  @override
  String get bmcuFreshTitle => 'Red LEDs? Calibrate the buffers';

  @override
  String get bmcuFreshSteps =>
      'All 4 slots show the firmware default filament, a sign the BMCU memory was erased (BMCU Flasher erases everything when flashing). That erases the buffer calibration: until it is calibrated, the LEDs stay red and the motors do not turn. With no saved calibration the BMCU calibrates by itself at power-on, but only if no channel has filament.\n\n1. Remove filament from every channel (past the BMCU sensor). Make sure no broken piece is left inside.\n2. Turn the printer off and on without touching the buffers.\n3. The LEDs blink yellow for ~1 s while reading the rest position. If they blink red twice, filament is still in or a buffer moved: check and restart.\n4. When the channel LED blinks blue, push the buffer all the way in for 1 s and release.\n5. When it blinks red, pull it all the way out for 1 s and release.\n6. Repeat on the other channels (30 s per step) and leave everything released: two green blinks mean it saved.';

  @override
  String get testFirmwareTitle => 'Test firmware';

  @override
  String testFirmwareBody(int size, String sha) {
    return 'Found a test file in the app folder ($size bytes, sha256 $sha). It is an experimental build, not a published release.';
  }

  @override
  String get testFirmwareStart => 'Flash test file';
}
