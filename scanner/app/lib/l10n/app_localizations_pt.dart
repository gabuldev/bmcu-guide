// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'BMCU Scanner';

  @override
  String get discoveryTitle => 'Impressoras na rede';

  @override
  String get discoveryScanning => 'Procurando impressoras Bambu na rede...';

  @override
  String get discoveryEmpty =>
      'Nenhuma impressora encontrada. Confira se o PC/celular está na mesma rede que a impressora.';

  @override
  String get discoveryRescan => 'Procurar de novo';

  @override
  String discoveryFailed(String detail) {
    return 'Não foi possível escutar a rede: $detail';
  }

  @override
  String get discoveryCloudMode =>
      'Modo nuvem — ative LAN Only + Developer Mode';

  @override
  String get discoveryLanMode => 'LAN Only';

  @override
  String get discoveryAddManual => 'Adicionar pelo IP';

  @override
  String get manualIp => 'IP da impressora';

  @override
  String get manualSerial => 'Número de série';

  @override
  String get accessCodeTitle => 'Código de acesso';

  @override
  String get accessCodeHint =>
      'Na tela da impressora: Configurações → WLAN / LAN Only.';

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
      '1. Na impressora, ligue LAN Only e Developer Mode.\n2. Reinicie a impressora depois de ligar.\n3. Anote o código de acesso que aparece na mesma tela.';

  @override
  String get reportTitle => 'Diagnóstico';

  @override
  String get reportReading => 'Lendo a impressora...';

  @override
  String get reportRetry => 'Tentar de novo';

  @override
  String get failureBadCode =>
      'Código de acesso recusado. Confira o código na tela da impressora.';

  @override
  String get failureUnreachable =>
      'Não foi possível conectar na impressora. Ligue LAN Only + Developer Mode e reinicie a impressora.';

  @override
  String get failureNoStatus =>
      'A impressora conectou mas não mandou o estado. Tente de novo.';

  @override
  String get noBmcu => 'Nenhum BMCU encontrado nesta impressora.';

  @override
  String bmcuTitle(String letter) {
    return 'BMCU no AMS $letter';
  }

  @override
  String bmcuUpToDate(String version) {
    return 'Firmware em dia ($version)';
  }

  @override
  String bmcuOutdated(String installed, String latest) {
    return '$installed instalado — $latest disponível';
  }

  @override
  String get bmcuKnownBugs =>
      'Problemas da sua versão que a atualização resolve:';

  @override
  String get bmcuUpdate => 'Como atualizar';

  @override
  String get slotEmpty => 'vazio';

  @override
  String get findingsTitle => 'Alertas da impressora';

  @override
  String get findingsNone => 'Nenhum alerta ativo.';

  @override
  String get findingExpected => 'Esperado com BMCU';

  @override
  String get findingPossible => 'Possível causa';

  @override
  String get findingGeneric => 'Erro de AMS';

  @override
  String get findingUnknown => 'Sem explicação para BMCU ainda';

  @override
  String get findingOfficial => 'Texto da Bambu';

  @override
  String get severityInfo => 'Informativo';

  @override
  String get severityWarning => 'Atenção';

  @override
  String get severityBlocking => 'Impede imprimir';

  @override
  String get findingSources => 'Relatos:';

  @override
  String get bmcuFlashUsb => 'Atualizar pelo USB';

  @override
  String get discoveryFlashUsb => 'Gravar BMCU pelo USB';

  @override
  String get flashTitle => 'Atualizar BMCU';

  @override
  String flashIntro(String version) {
    return 'O app baixa o firmware $version do projeto oficial, confere o arquivo e grava no BMCU pelo cabo USB.';
  }

  @override
  String get flashIntroNoVersion =>
      'O app baixa o firmware mais recente do projeto oficial, confere o arquivo e grava no BMCU pelo cabo USB.';

  @override
  String get variantTitle => 'Configuração do firmware';

  @override
  String get variantHint =>
      'Escolha a mesma configuração que você usa hoje. O BMCU não informa qual foi gravada, então o app só lembra depois da primeira gravação por aqui.';

  @override
  String get variantFromLast =>
      'Mesma configuração da última gravação feita por este aparelho.';

  @override
  String get forceLabel => 'Força de carregamento';

  @override
  String get forceStandard => 'Padrão (A1)';

  @override
  String get forceSoft => 'Suave (A1)';

  @override
  String get forceHigh => 'Forte (P1S/X1)';

  @override
  String get forceStandardHelp =>
      'Para A1 e A1 mini com tubo PTFE curto e reto. Na dúvida, comece por aqui.';

  @override
  String get forceSoftHelp =>
      'Só A1 e A1 mini: menos força, para quando o BMCU estala ou mói o filamento ao carregar. Pode causar recusa de carregamento.';

  @override
  String get forceHighHelp =>
      'Para P1S e caminhos de PTFE longos ou com curvas, ou se o carregamento for recusado.';

  @override
  String forceMismatch(String model, String suggested) {
    return 'Esta impressora é $model: o indicado é “$suggested”.';
  }

  @override
  String get autoloadLabel => 'AUTOLOAD';

  @override
  String get autoloadHelp =>
      'Puxa o filamento sozinho ao encostar no BMCU. Funciona em qualquer BMCU-370C; sem ele, você empurra até aparecer no tubo.';

  @override
  String get rgbLabel => 'LED na cor do filamento';

  @override
  String get rgbHelp =>
      'O LED de cada canal acende na cor do filamento carregado.';

  @override
  String get slotLabel => 'Número do AMS';

  @override
  String get slotAuto => 'Automático (recomendado)';

  @override
  String get retractLabel => 'Retração';

  @override
  String get retractHelp =>
      'Distância do BMCU até o fim do divisor (splitter) dentro da impressora, com uma pequena folga. Ex.: 9 cm até o divisor → 9,5 cm.';

  @override
  String get retractMissing => 'Escolha a retração para continuar.';

  @override
  String get safetyTitle => 'Antes de ligar o cabo';

  @override
  String get safetySteps =>
      '1. Tire o filamento de todos os canais, até passar o sensor do BMCU.\n2. Desligue a impressora.\n3. Desconecte o BMCU da impressora.\n4. Ligue o BMCU neste aparelho com um cabo USB OTG.\n\nLigar ou desligar o cabo com a impressora ligada pode queimar o BMCU ou a placa da impressora.';

  @override
  String get safetyConfirm =>
      'A impressora está desligada e o BMCU está ligado só neste aparelho.';

  @override
  String flashStart(String version) {
    return 'Gravar $version';
  }

  @override
  String get flashStartNoVersion => 'Gravar firmware';

  @override
  String get stageDownloading => 'Baixando o firmware...';

  @override
  String get stageConnecting => 'Entrando no modo de gravação...';

  @override
  String get stageUnlocking => 'Liberando a gravação...';

  @override
  String get stageErasing => 'Apagando o firmware antigo...';

  @override
  String get stageWriting => 'Gravando...';

  @override
  String get stageVerifying => 'Conferindo...';

  @override
  String get flashDontUnplug => 'Não desconecte o cabo nem saia desta tela.';

  @override
  String flashDone(String version) {
    return 'BMCU atualizado para $version';
  }

  @override
  String get flashDoneNoVersion => 'BMCU atualizado';

  @override
  String get flashDoneSteps =>
      'Calibre os buffers agora, ainda neste cabo e antes de ligar na impressora. Vindo do V10.5 ou anterior, a calibração sempre precisa ser refeita, porque o V11 a salva em outro formato. Sem calibração, os LEDs ficam vermelhos, os motores não giram e a impressora pode não reconhecer o BMCU.\n\n1. Confira que não tem filamento em nenhum canal.\n2. Os LEDs piscam amarelo enquanto o BMCU lê o repouso. Não encoste nos buffers.\n3. Quando o LED do canal piscar azul, empurre o buffer até o fim por 1 s e solte.\n4. Quando piscar vermelho, puxe até o fim por 1 s e solte.\n5. Repita nos outros canais e deixe tudo solto. Duas piscadas verdes indicam que salvou.\n\nSe piscar vermelho duas vezes ou passar o tempo (30 s por passo), desconecte o cabo, espere 5 s e conecte de novo para recomeçar.\n\nDepois, com a impressora desligada, ligue o BMCU nela, ligue a impressora e escaneie de novo para confirmar a versão.';

  @override
  String get flashBack => 'Voltar';

  @override
  String get flashFailDownload =>
      'Não foi possível baixar o firmware. Confira a internet e tente de novo.';

  @override
  String get flashFailNoDevice =>
      'Nenhum BMCU encontrado no USB. Confira o cabo OTG e se o BMCU acendeu.';

  @override
  String get flashFailPermission =>
      'O Android não deu permissão para usar o USB. Tente de novo e toque em Permitir.';

  @override
  String get flashFailFlash =>
      'A gravação parou no meio. O modo de gravação do BMCU não se apaga, então é só tentar de novo; até lá ele fica sem firmware.';

  @override
  String get flashDetails => 'Detalhes';

  @override
  String get reportChangeCode => 'Trocar código de acesso';

  @override
  String get bmcuFreshTitle => 'LEDs vermelhos? Calibre os buffers';

  @override
  String get bmcuFreshSteps =>
      'Os 4 slots estão com o filamento padrão do firmware, sinal de que a memória do BMCU foi apagada (o BMCU Flasher apaga tudo ao gravar). Isso apaga a calibração dos buffers: até calibrar, os LEDs ficam vermelhos e os motores não giram. Sem calibração salva, o BMCU calibra sozinho ao ligar, mas só se não tiver filamento em nenhum canal.\n\n1. Tire o filamento de todos os canais (passando do sensor do BMCU). Confira se não ficou um pedaço quebrado lá dentro.\n2. Desligue e ligue a impressora sem encostar nos buffers.\n3. Os LEDs piscam amarelo por ~1 s lendo o repouso. Se piscarem vermelho duas vezes, ainda tem filamento ou um buffer mexeu: confira e reinicie.\n4. Quando o LED do canal piscar azul, empurre o buffer até o fim por 1 s e solte.\n5. Quando piscar vermelho, puxe até o fim por 1 s e solte.\n6. Repita nos outros canais (30 s por passo) e deixe tudo solto: duas piscadas verdes indicam que salvou.';

  @override
  String get testFirmwareTitle => 'Firmware de teste';

  @override
  String testFirmwareBody(int size, String sha) {
    return 'Achei um arquivo de teste na pasta do app ($size bytes, sha256 $sha). É um build experimental, fora das versões publicadas.';
  }

  @override
  String get testFirmwareStart => 'Gravar arquivo de teste';
}
