import 'package:bambu_core/bambu_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/usb_serial_link.dart';
import '../../l10n/app_localizations.dart';
import '../flash/flash_module.dart';
import 'report_controller.dart';
import 'report_status.dart';

/// A tabela usa `pt-BR`; o app, so o codigo da lingua.
String _tableLang(BuildContext context) =>
    switch (Localizations.localeOf(context).languageCode) {
      'pt' => 'pt-BR',
      'es' => 'es',
      _ => 'en',
    };

const _issuesUrl = 'https://github.com/jarczakpawel/BMCU-C-PJARCZAK/issues/';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final printer = context.read<ReportController>().printer;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportTitle),
        actions: [
          IconButton(
            tooltip: l10n.reportRetry,
            onPressed: context.read<ReportController>().read,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<ReportController, ReportStatus>(
          builder: (context, status) => switch (status) {
            ReportLoading() => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(l10n.reportReading),
                  ],
                ),
              ),
            ReportFailure() => _Failure(status: status),
            ReportReady(:final report, :final table) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    printer.model.isEmpty
                        ? printer.name
                        : '${printer.modelName} · ${printer.name}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text('${printer.ip}${printer.firmware == null ? '' : ' · fw ${printer.firmware}'}'),
                  const SizedBox(height: 16),
                  if (report.bmcus.isEmpty) Text(l10n.noBmcu),
                  for (final bmcu in report.bmcus)
                    _BmcuCard(
                      bmcu: bmcu,
                      table: table,
                      printerModel: printer.model.isEmpty ? null : printer.modelName,
                    ),
                  const SizedBox(height: 24),
                  Text(l10n.findingsTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (report.findings.isEmpty) Text(l10n.findingsNone),
                  for (final finding in report.findings)
                    _FindingCard(finding: finding),
                ],
              ),
          },
        ),
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.status});

  final ReportFailure status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = switch (status.reason) {
      ReportFailureReason.badAccessCode => l10n.failureBadCode,
      ReportFailureReason.unreachable => l10n.failureUnreachable,
      ReportFailureReason.noStatus => l10n.failureNoStatus,
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (status.detail != null) ...[
              const SizedBox(height: 8),
              Text(status.detail!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: context.read<ReportController>().read,
              child: Text(l10n.reportRetry),
            ),
            const SizedBox(height: 8),
            // Volta para a busca, que pergunta o codigo de novo.
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.reportChangeCode),
            ),
          ],
        ),
      ),
    );
  }
}

class _BmcuCard extends StatelessWidget {
  const _BmcuCard({required this.bmcu, required this.table, this.printerModel});

  final BmcuUnit bmcu;
  final HmsTable table;
  final String? printerModel;

  Future<void> _flash(BuildContext context) async {
    final flashed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FlashModule(printerModel: printerModel, bmcuSerial: bmcu.serial),
      ),
    );
    // Gravou: a pessoa religa tudo e o botao de atualizar le de novo.
    if (flashed ?? false) {
      if (context.mounted) context.read<ReportController>().read();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lang = _tableLang(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.bmcuTitle(bmcu.letter),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  bmcu.outdated ? Icons.system_update : Icons.check_circle,
                  color: bmcu.outdated ? scheme.tertiary : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(bmcu.outdated
                      ? l10n.bmcuOutdated('${bmcu.version}', '${bmcu.latest}')
                      : l10n.bmcuUpToDate('${bmcu.version}')),
                ),
              ],
            ),
            if (bmcu.looksFreshlyFlashed) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.bmcuFreshTitle,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(color: scheme.onTertiaryContainer)),
                    const SizedBox(height: 4),
                    Text(l10n.bmcuFreshSteps,
                        style: TextStyle(color: scheme.onTertiaryContainer)),
                  ],
                ),
              ),
            ],
            if (bmcu.knownBugs.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(l10n.bmcuKnownBugs),
              for (final bug in bmcu.knownBugs)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text('• ${bug.textFor(lang).title}'),
                ),
            ],
            if (bmcu.outdated) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (UsbSerialLink.supported)
                    FilledButton.icon(
                      onPressed: () => _flash(context),
                      icon: const Icon(Icons.usb),
                      label: Text(l10n.bmcuFlashUsb),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(table.latestUrl)),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(l10n.bmcuUpdate),
                  ),
                ],
              ),
            ],
            if (bmcu.ams != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tray in bmcu.ams!.trays) _TrayChip(tray: tray),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrayChip extends StatelessWidget {
  const _TrayChip({required this.tray});

  final Tray tray;

  @override
  Widget build(BuildContext context) {
    final color = tray.color == null
        ? Colors.transparent
        : Color(int.parse('FF${tray.color!.substring(0, 6)}', radix: 16));
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        child: Text('${tray.id + 1}',
            style: TextStyle(
              fontSize: 11,
              color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
            )),
      ),
      label: Text(tray.type ?? AppLocalizations.of(context).slotEmpty),
    );
  }
}

class _FindingCard extends StatelessWidget {
  const _FindingCard({required this.finding});

  final HmsFinding finding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = _tableLang(context);
    final scheme = Theme.of(context).colorScheme;

    final (label, problem, official, generic) = switch (finding.lookup) {
      HmsKnown(:final problem, :final official) => (
          problem.expected ? l10n.findingExpected : null,
          problem,
          official,
          null,
        ),
      HmsPossible(:final problem, :final official) =>
        (l10n.findingPossible, problem, official, null),
      HmsGenericAms(:final text) =>
        (l10n.findingGeneric, null, null, text[lang] ?? text['en']),
      HmsUnknown() => (l10n.findingUnknown, null, null, null),
    };
    final text = problem?.textFor(lang);
    final color = switch (finding.severity) {
      HmsSeverity.info => scheme.primary,
      HmsSeverity.warning => scheme.tertiary,
      HmsSeverity.blocking => scheme.error,
    };
    final severity = switch (finding.severity) {
      HmsSeverity.info => l10n.severityInfo,
      HmsSeverity.warning => l10n.severityWarning,
      HmsSeverity.blocking => l10n.severityBlocking,
    };

    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(
          finding.severity == HmsSeverity.info
              ? Icons.info_outline
              : Icons.warning_amber,
          color: color,
        ),
        title: Text(text?.title ?? finding.event.display),
        subtitle: Text([
          finding.event.display,
          severity,
          ?label,
        ].join(' · ')),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (text != null) ...[
            Text(text.meaning),
            const SizedBox(height: 8),
            for (final (i, step) in text.steps.indexed)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${i + 1}. $step'),
              ),
          ],
          if (generic != null) Text(generic),
          if (official != null) ...[
            const SizedBox(height: 12),
            Text(l10n.findingOfficial,
                style: Theme.of(context).textTheme.labelMedium),
            Text(official[lang] ?? official['en'] ?? '',
                style: Theme.of(context).textTheme.bodySmall),
          ],
          if (problem != null && problem.sources.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(l10n.findingSources,
                    style: Theme.of(context).textTheme.labelMedium),
                for (final n in problem.sources)
                  InkWell(
                    onTap: () => launchUrl(Uri.parse('$_issuesUrl$n')),
                    child: Text('#$n',
                        style: TextStyle(
                          color: scheme.primary,
                          decoration: TextDecoration.underline,
                        )),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
