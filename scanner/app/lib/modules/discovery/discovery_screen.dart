import 'package:bambu_core/bambu_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_injections/flutter_injections.dart';

import '../../core/usb_serial_link.dart';
import '../../core/variant_store.dart';
import '../../l10n/app_localizations.dart';
import '../flash/flash_module.dart';
import '../report/report_module.dart';
import 'discovery_controller.dart';
import 'discovery_status.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  @override
  void initState() {
    super.initState();
    // Procura assim que abre: quem abriu o app quer ver a impressora.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DiscoveryController>().scan(),
    );
  }

  /// Com codigo salvo vai direto para o diagnostico; so pergunta na
  /// primeira vez, quando [askCode] ou quando a impressora recusou o codigo.
  Future<void> _open(DiscoveredPrinter printer, {bool askCode = false}) async {
    final controller = context.read<DiscoveryController>();
    if (printer.model.isNotEmpty) {
      FlutterInjections.get<VariantStore>().rememberPrinter(printer.modelName);
    }
    final saved = controller.savedCode(printer.serial);
    var code = askCode ? null : saved;
    if (code == null) {
      code = await showDialog<String>(
        context: context,
        builder: (_) => _AccessCodeDialog(initial: saved),
      );
      if (code == null || !mounted) return;
      await controller.saveCode(printer.serial, code);
      if (!mounted) return;
    }
    final changeCode = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => ReportModule(printer: printer, accessCode: code!),
    ));
    if ((changeCode ?? false) && mounted) await _open(printer, askCode: true);
  }

  Future<void> _addManual() async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _ManualDialog(),
    );
    if (result == null || !mounted) return;
    context.read<DiscoveryController>().addManual(result.$1, result.$2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.discoveryTitle),
        actions: [
          if (UsbSerialLink.supported)
            IconButton(
              tooltip: l10n.discoveryFlashUsb,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const FlashModule()),
              ),
              icon: const Icon(Icons.usb),
            ),
          IconButton(
            tooltip: l10n.discoveryAddManual,
            onPressed: _addManual,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<DiscoveryController, DiscoveryStatus>(
          builder: (context, status) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _SetupCard(),
              const SizedBox(height: 16),
              if (status.scanning) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(l10n.discoveryScanning),
              ],
              if (status.failureDetail != null)
                Text(
                  l10n.discoveryFailed(status.failureDetail!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (!status.scanning && status.printers.isEmpty)
                Text(l10n.discoveryEmpty),
              for (final p in status.printers)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.print_outlined),
                    title: Text(p.model.isEmpty ? p.name : '${p.modelName} · ${p.name}'),
                    subtitle: Text([
                      p.ip,
                      if (p.firmware != null) 'fw ${p.firmware}',
                      if (p.connectMode != null)
                        p.lanOnly ? l10n.discoveryLanMode : l10n.discoveryCloudMode,
                    ].join(' · ')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(p),
                    // Toque longo troca o codigo (ex.: depois de gerar outro).
                    onLongPress: () => _open(p, askCode: true),
                  ),
                ),
              if (!status.scanning)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    onPressed: context.read<DiscoveryController>().scan,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.discoveryRescan),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// O passo a passo que travou o primeiro teste: sem reiniciar depois de ligar
/// o LAN Only, a impressora anuncia mas nao aceita conexao.
class _SetupCard extends StatelessWidget {
  const _SetupCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.setupTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l10n.setupSteps),
          ],
        ),
      ),
    );
  }
}

class _AccessCodeDialog extends StatefulWidget {
  const _AccessCodeDialog({this.initial});

  final String? initial;

  @override
  State<_AccessCodeDialog> createState() => _AccessCodeDialogState();
}

class _AccessCodeDialogState extends State<_AccessCodeDialog> {
  late final _code = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _code.text.trim();
    if (code.isNotEmpty) Navigator.pop(context, code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.accessCodeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.accessCodeHint),
          const SizedBox(height: 12),
          TextField(
            controller: _code,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.accessCodeLabel),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.scan)),
      ],
    );
  }
}

class _ManualDialog extends StatefulWidget {
  const _ManualDialog();

  @override
  State<_ManualDialog> createState() => _ManualDialogState();
}

class _ManualDialogState extends State<_ManualDialog> {
  final _ip = TextEditingController();
  final _serial = TextEditingController();

  @override
  void dispose() {
    _ip.dispose();
    _serial.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.discoveryAddManual),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ip,
            decoration: InputDecoration(labelText: l10n.manualIp),
          ),
          TextField(
            controller: _serial,
            decoration: InputDecoration(labelText: l10n.manualSerial),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final ip = _ip.text.trim(), serial = _serial.text.trim();
            if (ip.isNotEmpty && serial.isNotEmpty) {
              Navigator.pop(context, (ip, serial));
            }
          },
          child: Text(l10n.discoveryAddManual),
        ),
      ],
    );
  }
}
