import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'BMCU Scanner'**
  String get appTitle;

  /// No description provided for @discoveryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Impressoras na rede'**
  String get discoveryTitle;

  /// No description provided for @discoveryScanning.
  ///
  /// In pt, this message translates to:
  /// **'Procurando impressoras Bambu na rede...'**
  String get discoveryScanning;

  /// No description provided for @discoveryEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma impressora encontrada. Confira se o PC/celular está na mesma rede que a impressora.'**
  String get discoveryEmpty;

  /// No description provided for @discoveryRescan.
  ///
  /// In pt, this message translates to:
  /// **'Procurar de novo'**
  String get discoveryRescan;

  /// No description provided for @discoveryFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível escutar a rede: {detail}'**
  String discoveryFailed(String detail);

  /// No description provided for @discoveryCloudMode.
  ///
  /// In pt, this message translates to:
  /// **'Modo nuvem — ative LAN Only + Developer Mode'**
  String get discoveryCloudMode;

  /// No description provided for @discoveryLanMode.
  ///
  /// In pt, this message translates to:
  /// **'LAN Only'**
  String get discoveryLanMode;

  /// No description provided for @discoveryAddManual.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar pelo IP'**
  String get discoveryAddManual;

  /// No description provided for @manualIp.
  ///
  /// In pt, this message translates to:
  /// **'IP da impressora'**
  String get manualIp;

  /// No description provided for @manualSerial.
  ///
  /// In pt, this message translates to:
  /// **'Número de série'**
  String get manualSerial;

  /// No description provided for @accessCodeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Código de acesso'**
  String get accessCodeTitle;

  /// No description provided for @accessCodeHint.
  ///
  /// In pt, this message translates to:
  /// **'Na tela da impressora: Configurações → WLAN / LAN Only.'**
  String get accessCodeHint;

  /// No description provided for @accessCodeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Código (8 dígitos)'**
  String get accessCodeLabel;

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @scan.
  ///
  /// In pt, this message translates to:
  /// **'Escanear'**
  String get scan;

  /// No description provided for @setupTitle.
  ///
  /// In pt, this message translates to:
  /// **'Antes de escanear'**
  String get setupTitle;

  /// No description provided for @setupSteps.
  ///
  /// In pt, this message translates to:
  /// **'1. Na impressora, ligue LAN Only e Developer Mode.\n2. Reinicie a impressora depois de ligar.\n3. Anote o código de acesso que aparece na mesma tela.'**
  String get setupSteps;

  /// No description provided for @reportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Diagnóstico'**
  String get reportTitle;

  /// No description provided for @reportReading.
  ///
  /// In pt, this message translates to:
  /// **'Lendo a impressora...'**
  String get reportReading;

  /// No description provided for @reportRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar de novo'**
  String get reportRetry;

  /// No description provided for @failureBadCode.
  ///
  /// In pt, this message translates to:
  /// **'Código de acesso recusado. Confira o código na tela da impressora.'**
  String get failureBadCode;

  /// No description provided for @failureUnreachable.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível conectar na impressora. Ligue LAN Only + Developer Mode e reinicie a impressora.'**
  String get failureUnreachable;

  /// No description provided for @failureNoStatus.
  ///
  /// In pt, this message translates to:
  /// **'A impressora conectou mas não mandou o estado. Tente de novo.'**
  String get failureNoStatus;

  /// No description provided for @noBmcu.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum BMCU encontrado nesta impressora.'**
  String get noBmcu;

  /// No description provided for @bmcuTitle.
  ///
  /// In pt, this message translates to:
  /// **'BMCU no AMS {letter}'**
  String bmcuTitle(String letter);

  /// No description provided for @bmcuUpToDate.
  ///
  /// In pt, this message translates to:
  /// **'Firmware em dia ({version})'**
  String bmcuUpToDate(String version);

  /// No description provided for @bmcuOutdated.
  ///
  /// In pt, this message translates to:
  /// **'{installed} instalado — {latest} disponível'**
  String bmcuOutdated(String installed, String latest);

  /// No description provided for @bmcuKnownBugs.
  ///
  /// In pt, this message translates to:
  /// **'Problemas da sua versão que a atualização resolve:'**
  String get bmcuKnownBugs;

  /// No description provided for @bmcuUpdate.
  ///
  /// In pt, this message translates to:
  /// **'Como atualizar'**
  String get bmcuUpdate;

  /// No description provided for @slotEmpty.
  ///
  /// In pt, this message translates to:
  /// **'vazio'**
  String get slotEmpty;

  /// No description provided for @findingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Alertas da impressora'**
  String get findingsTitle;

  /// No description provided for @findingsNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum alerta ativo.'**
  String get findingsNone;

  /// No description provided for @findingExpected.
  ///
  /// In pt, this message translates to:
  /// **'Esperado com BMCU'**
  String get findingExpected;

  /// No description provided for @findingPossible.
  ///
  /// In pt, this message translates to:
  /// **'Possível causa'**
  String get findingPossible;

  /// No description provided for @findingGeneric.
  ///
  /// In pt, this message translates to:
  /// **'Erro de AMS'**
  String get findingGeneric;

  /// No description provided for @findingUnknown.
  ///
  /// In pt, this message translates to:
  /// **'Sem explicação para BMCU ainda'**
  String get findingUnknown;

  /// No description provided for @findingOfficial.
  ///
  /// In pt, this message translates to:
  /// **'Texto da Bambu'**
  String get findingOfficial;

  /// No description provided for @severityInfo.
  ///
  /// In pt, this message translates to:
  /// **'Informativo'**
  String get severityInfo;

  /// No description provided for @severityWarning.
  ///
  /// In pt, this message translates to:
  /// **'Atenção'**
  String get severityWarning;

  /// No description provided for @severityBlocking.
  ///
  /// In pt, this message translates to:
  /// **'Impede imprimir'**
  String get severityBlocking;

  /// No description provided for @findingSources.
  ///
  /// In pt, this message translates to:
  /// **'Relatos:'**
  String get findingSources;

  /// No description provided for @bmcuFlashUsb.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar pelo USB'**
  String get bmcuFlashUsb;

  /// No description provided for @discoveryFlashUsb.
  ///
  /// In pt, this message translates to:
  /// **'Gravar BMCU pelo USB'**
  String get discoveryFlashUsb;

  /// No description provided for @flashTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar BMCU'**
  String get flashTitle;

  /// No description provided for @flashIntro.
  ///
  /// In pt, this message translates to:
  /// **'O app baixa o firmware {version} do projeto oficial, confere o arquivo e grava no BMCU pelo cabo USB.'**
  String flashIntro(String version);

  /// No description provided for @flashIntroNoVersion.
  ///
  /// In pt, this message translates to:
  /// **'O app baixa o firmware mais recente do projeto oficial, confere o arquivo e grava no BMCU pelo cabo USB.'**
  String get flashIntroNoVersion;

  /// No description provided for @variantTitle.
  ///
  /// In pt, this message translates to:
  /// **'Configuração do firmware'**
  String get variantTitle;

  /// No description provided for @variantHint.
  ///
  /// In pt, this message translates to:
  /// **'Escolha a mesma configuração que você usa hoje. O BMCU não informa qual foi gravada, então o app só lembra depois da primeira gravação por aqui.'**
  String get variantHint;

  /// No description provided for @variantFromLast.
  ///
  /// In pt, this message translates to:
  /// **'Mesma configuração da última gravação feita por este aparelho.'**
  String get variantFromLast;

  /// No description provided for @forceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Força de carregamento'**
  String get forceLabel;

  /// No description provided for @forceStandard.
  ///
  /// In pt, this message translates to:
  /// **'Padrão (A1)'**
  String get forceStandard;

  /// No description provided for @forceSoft.
  ///
  /// In pt, this message translates to:
  /// **'Suave (A1)'**
  String get forceSoft;

  /// No description provided for @forceHigh.
  ///
  /// In pt, this message translates to:
  /// **'Forte (P1S/X1)'**
  String get forceHigh;

  /// No description provided for @forceStandardHelp.
  ///
  /// In pt, this message translates to:
  /// **'Para A1 e A1 mini com tubo PTFE curto e reto. Na dúvida, comece por aqui.'**
  String get forceStandardHelp;

  /// No description provided for @forceSoftHelp.
  ///
  /// In pt, this message translates to:
  /// **'Só A1 e A1 mini: menos força, para quando o BMCU estala ou mói o filamento ao carregar. Pode causar recusa de carregamento.'**
  String get forceSoftHelp;

  /// No description provided for @forceHighHelp.
  ///
  /// In pt, this message translates to:
  /// **'Para P1S e caminhos de PTFE longos ou com curvas, ou se o carregamento for recusado.'**
  String get forceHighHelp;

  /// No description provided for @forceMismatch.
  ///
  /// In pt, this message translates to:
  /// **'Esta impressora é {model}: o indicado é “{suggested}”.'**
  String forceMismatch(String model, String suggested);

  /// No description provided for @autoloadLabel.
  ///
  /// In pt, this message translates to:
  /// **'AUTOLOAD'**
  String get autoloadLabel;

  /// No description provided for @autoloadHelp.
  ///
  /// In pt, this message translates to:
  /// **'Puxa o filamento sozinho ao encostar no BMCU. Funciona em qualquer BMCU-370C; sem ele, você empurra até aparecer no tubo.'**
  String get autoloadHelp;

  /// No description provided for @rgbLabel.
  ///
  /// In pt, this message translates to:
  /// **'LED na cor do filamento'**
  String get rgbLabel;

  /// No description provided for @rgbHelp.
  ///
  /// In pt, this message translates to:
  /// **'O LED de cada canal acende na cor do filamento carregado.'**
  String get rgbHelp;

  /// No description provided for @slotLabel.
  ///
  /// In pt, this message translates to:
  /// **'Número do AMS'**
  String get slotLabel;

  /// No description provided for @slotAuto.
  ///
  /// In pt, this message translates to:
  /// **'Automático (recomendado)'**
  String get slotAuto;

  /// No description provided for @retractLabel.
  ///
  /// In pt, this message translates to:
  /// **'Retração'**
  String get retractLabel;

  /// No description provided for @retractHelp.
  ///
  /// In pt, this message translates to:
  /// **'Distância do BMCU até o fim do divisor (splitter) dentro da impressora, com uma pequena folga. Ex.: 9 cm até o divisor → 9,5 cm.'**
  String get retractHelp;

  /// No description provided for @retractMissing.
  ///
  /// In pt, this message translates to:
  /// **'Escolha a retração para continuar.'**
  String get retractMissing;

  /// No description provided for @safetyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Antes de ligar o cabo'**
  String get safetyTitle;

  /// No description provided for @safetySteps.
  ///
  /// In pt, this message translates to:
  /// **'1. Desligue a impressora.\n2. Desconecte o BMCU da impressora.\n3. Ligue o BMCU neste aparelho com um cabo USB OTG.\n\nLigar ou desligar o cabo com a impressora ligada pode queimar o BMCU ou a placa da impressora.'**
  String get safetySteps;

  /// No description provided for @safetyConfirm.
  ///
  /// In pt, this message translates to:
  /// **'A impressora está desligada e o BMCU está ligado só neste aparelho.'**
  String get safetyConfirm;

  /// No description provided for @flashStart.
  ///
  /// In pt, this message translates to:
  /// **'Gravar {version}'**
  String flashStart(String version);

  /// No description provided for @flashStartNoVersion.
  ///
  /// In pt, this message translates to:
  /// **'Gravar firmware'**
  String get flashStartNoVersion;

  /// No description provided for @stageDownloading.
  ///
  /// In pt, this message translates to:
  /// **'Baixando o firmware...'**
  String get stageDownloading;

  /// No description provided for @stageConnecting.
  ///
  /// In pt, this message translates to:
  /// **'Entrando no modo de gravação...'**
  String get stageConnecting;

  /// No description provided for @stageUnlocking.
  ///
  /// In pt, this message translates to:
  /// **'Liberando a gravação...'**
  String get stageUnlocking;

  /// No description provided for @stageErasing.
  ///
  /// In pt, this message translates to:
  /// **'Apagando o firmware antigo...'**
  String get stageErasing;

  /// No description provided for @stageWriting.
  ///
  /// In pt, this message translates to:
  /// **'Gravando...'**
  String get stageWriting;

  /// No description provided for @stageVerifying.
  ///
  /// In pt, this message translates to:
  /// **'Conferindo...'**
  String get stageVerifying;

  /// No description provided for @flashDontUnplug.
  ///
  /// In pt, this message translates to:
  /// **'Não desconecte o cabo nem saia desta tela.'**
  String get flashDontUnplug;

  /// No description provided for @flashDone.
  ///
  /// In pt, this message translates to:
  /// **'BMCU atualizado para {version}'**
  String flashDone(String version);

  /// No description provided for @flashDoneNoVersion.
  ///
  /// In pt, this message translates to:
  /// **'BMCU atualizado'**
  String get flashDoneNoVersion;

  /// No description provided for @flashDoneSteps.
  ///
  /// In pt, this message translates to:
  /// **'1. Desconecte o BMCU deste aparelho e ligue-o na impressora desligada.\n2. Na primeira atualização por este app, a calibração dos buffers costuma ser apagada (o chip vinha protegido). Nas próximas, ela deve ser mantida.\n3. Se os LEDs ficarem vermelhos, os buffers precisam ser calibrados: abra o diagnóstico, ele mostra como.\n\nDepois, escaneie de novo para confirmar a versão.'**
  String get flashDoneSteps;

  /// No description provided for @flashBack.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get flashBack;

  /// No description provided for @flashFailDownload.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível baixar o firmware. Confira a internet e tente de novo.'**
  String get flashFailDownload;

  /// No description provided for @flashFailNoDevice.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum BMCU encontrado no USB. Confira o cabo OTG e se o BMCU acendeu.'**
  String get flashFailNoDevice;

  /// No description provided for @flashFailPermission.
  ///
  /// In pt, this message translates to:
  /// **'O Android não deu permissão para usar o USB. Tente de novo e toque em Permitir.'**
  String get flashFailPermission;

  /// No description provided for @flashFailFlash.
  ///
  /// In pt, this message translates to:
  /// **'A gravação parou no meio. O modo de gravação do BMCU não se apaga, então é só tentar de novo; até lá ele fica sem firmware.'**
  String get flashFailFlash;

  /// No description provided for @flashDetails.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes'**
  String get flashDetails;

  /// No description provided for @reportChangeCode.
  ///
  /// In pt, this message translates to:
  /// **'Trocar código de acesso'**
  String get reportChangeCode;

  /// No description provided for @bmcuFreshTitle.
  ///
  /// In pt, this message translates to:
  /// **'LEDs vermelhos? Calibre os buffers'**
  String get bmcuFreshTitle;

  /// No description provided for @bmcuFreshSteps.
  ///
  /// In pt, this message translates to:
  /// **'Os 4 slots estão com o filamento padrão do firmware, sinal de que a memória do BMCU foi apagada (o BMCU Flasher apaga tudo ao gravar). Isso apaga a calibração dos buffers: até calibrar, os LEDs ficam vermelhos e os motores não giram. Sem calibração salva, o BMCU calibra sozinho ao ligar, mas só se não tiver filamento em nenhum canal.\n\n1. Tire o filamento de todos os canais (passando do sensor do BMCU). Confira se não ficou um pedaço quebrado lá dentro.\n2. Desligue e ligue a impressora sem encostar nos buffers.\n3. Os LEDs piscam amarelo por ~1 s lendo o repouso. Se piscarem vermelho duas vezes, ainda tem filamento ou um buffer mexeu: confira e reinicie.\n4. Quando o LED do canal piscar azul, empurre o buffer até o fim por 1 s e solte.\n5. Quando piscar vermelho, puxe até o fim por 1 s e solte.\n6. Repita nos outros canais (30 s por passo) e deixe tudo solto: duas piscadas verdes indicam que salvou.'**
  String get bmcuFreshSteps;

  /// No description provided for @testFirmwareTitle.
  ///
  /// In pt, this message translates to:
  /// **'Firmware de teste'**
  String get testFirmwareTitle;

  /// No description provided for @testFirmwareBody.
  ///
  /// In pt, this message translates to:
  /// **'Achei um arquivo de teste na pasta do app ({size} bytes, sha256 {sha}). É um build experimental, fora das versões publicadas.'**
  String testFirmwareBody(int size, String sha);

  /// No description provided for @testFirmwareStart.
  ///
  /// In pt, this message translates to:
  /// **'Gravar arquivo de teste'**
  String get testFirmwareStart;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
