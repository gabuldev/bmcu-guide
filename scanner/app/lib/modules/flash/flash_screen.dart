import 'package:bambu_core/bambu_core.dart';
import 'package:bmcu_flash/bmcu_flash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../l10n/app_localizations.dart';
import 'flash_controller.dart';
import 'flash_status.dart';

String _versionLabel(String? latest) =>
    latest == null ? '' : '${BmcuVersion.parse(latest)}';

class FlashScreen extends StatelessWidget {
  const FlashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<FlashController, FlashStatus>(
      builder: (context, status) => PopScope(
        // Sair no meio deixa o BMCU sem firmware ate gravar de novo.
        canPop: !status.busy,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.flashTitle),
            automaticallyImplyLeading: !status.busy,
          ),
          body: SafeArea(
            child: switch (status.step) {
              FlashStep.choose => _Choose(status: status),
              FlashStep.downloading || FlashStep.flashing => _Progress(status: status),
              FlashStep.done => _Done(status: status),
              FlashStep.failed => _Failed(status: status),
            },
          ),
        ),
      ),
    );
  }
}

class _Choose extends StatelessWidget {
  const _Choose({required this.status});

  final FlashStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.read<FlashController>();
    final theme = Theme.of(context);
    final forceHelp = switch (status.force) {
      LoadForce.standard => l10n.forceStandardHelp,
      LoadForce.soft => l10n.forceSoftHelp,
      LoadForce.highForce => l10n.forceHighHelp,
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          status.latest == null
              ? l10n.flashIntroNoVersion
              : l10n.flashIntro(_versionLabel(status.latest)),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.variantTitle, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  status.fromLastFlash ? l10n.variantFromLast : l10n.variantHint,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Text(l10n.forceLabel, style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<LoadForce>(
                  segments: [
                    ButtonSegment(value: LoadForce.standard, label: Text(l10n.forceStandard)),
                    ButtonSegment(value: LoadForce.soft, label: Text(l10n.forceSoft)),
                    ButtonSegment(value: LoadForce.highForce, label: Text(l10n.forceHigh)),
                  ],
                  selected: {status.force},
                  onSelectionChanged: (s) => controller.setForce(s.first),
                ),
                const SizedBox(height: 4),
                Text(forceHelp, style: theme.textTheme.bodySmall),
                if (controller.printerModel case final model?
                    when status.force != LoadForce.suggestedFor(model)) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.forceMismatch(model, switch (LoadForce.suggestedFor(model)) {
                            LoadForce.standard => l10n.forceStandard,
                            LoadForce.soft => l10n.forceSoft,
                            LoadForce.highForce => l10n.forceHigh,
                          }),
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.autoloadLabel),
                  subtitle: Text(l10n.autoloadHelp),
                  value: status.autoload,
                  onChanged: controller.setAutoload,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.rgbLabel),
                  subtitle: Text(l10n.rgbHelp),
                  value: status.rgb,
                  onChanged: controller.setRgb,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<AmsSlot>(
                  initialValue: status.slot,
                  decoration: InputDecoration(labelText: l10n.slotLabel),
                  items: [
                    for (final slot in AmsSlot.values)
                      DropdownMenuItem(
                        value: slot,
                        child: Text(slot == AmsSlot.auto
                            ? l10n.slotAuto
                            : 'AMS ${slot.name.toUpperCase()}'),
                      ),
                  ],
                  onChanged: (v) => controller.setSlot(v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: status.retract,
                  decoration: InputDecoration(
                    labelText: l10n.retractLabel,
                    helperText: l10n.retractHelp,
                    helperMaxLines: 4,
                  ),
                  items: [
                    for (final r in retractLengths.keys)
                      DropdownMenuItem(value: r, child: Text(r)),
                  ],
                  onChanged: (v) => controller.setRetract(v!),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: theme.colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.safetyTitle,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.onErrorContainer)),
                const SizedBox(height: 8),
                Text(l10n.safetySteps,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(l10n.safetyConfirm,
                      style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                  value: status.safetyConfirmed,
                  onChanged: (v) => controller.setSafety(v ?? false),
                ),
              ],
            ),
          ),
        ),
        if (status.testFirmware case final test?) ...[
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.testFirmwareTitle, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(l10n.testFirmwareBody(test.size, test.sha.substring(0, 12))),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: status.canStartTest ? controller.startTest : null,
                    icon: const Icon(Icons.science_outlined),
                    label: Text(l10n.testFirmwareStart),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: status.canStart ? controller.start : null,
          icon: const Icon(Icons.usb),
          label: Text(status.latest == null
              ? l10n.flashStartNoVersion
              : l10n.flashStart(_versionLabel(status.latest))),
        ),
        if (status.retract == null) ...[
          const SizedBox(height: 8),
          Text(l10n.retractMissing,
              textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.status});

  final FlashStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = status.step == FlashStep.downloading
        ? l10n.stageDownloading
        : switch (status.stage) {
            FlashStage.connecting || null => l10n.stageConnecting,
            FlashStage.unlocking => l10n.stageUnlocking,
            FlashStage.erasing => l10n.stageErasing,
            FlashStage.writing => l10n.stageWriting,
            FlashStage.verifying => l10n.stageVerifying,
            FlashStage.done => l10n.stageVerifying,
          };
    final determinate = status.step == FlashStep.downloading ||
        status.stage == FlashStage.writing ||
        status.stage == FlashStage.verifying;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 32),
        Text(label, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        LinearProgressIndicator(value: determinate ? status.fraction : null),
        const SizedBox(height: 8),
        if (determinate) Text('${(status.fraction * 100).round()}%'),
        const SizedBox(height: 24),
        if (status.step == FlashStep.flashing)
          Row(
            children: [
              Icon(Icons.warning_amber, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.flashDontUnplug)),
            ],
          ),
        const SizedBox(height: 24),
        _Log(lines: status.log),
      ],
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.status});

  final FlashStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 64),
        const SizedBox(height: 16),
        Text(
          status.latest == null
              ? l10n.flashDoneNoVersion
              : l10n.flashDone(_versionLabel(status.latest)),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Text(l10n.flashDoneSteps),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.flashBack),
        ),
        const SizedBox(height: 24),
        _Log(lines: status.log),
      ],
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.status});

  final FlashStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final message = switch (status.failure) {
      FlashFailureReason.download => l10n.flashFailDownload,
      FlashFailureReason.noDevice => l10n.flashFailNoDevice,
      FlashFailureReason.permission => l10n.flashFailPermission,
      FlashFailureReason.flash || null => l10n.flashFailFlash,
    };
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.error_outline, color: theme.colorScheme.error, size: 64),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
        if (status.detail != null) ...[
          const SizedBox(height: 8),
          Text(status.detail!,
              textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: context.read<FlashController>().reset,
          child: Text(l10n.reportRetry),
        ),
        const SizedBox(height: 24),
        _Log(lines: status.log),
      ],
    );
  }
}

class _Log extends StatelessWidget {
  const _Log({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(AppLocalizations.of(context).flashDetails),
      children: [
        SelectableText(
          lines.join('\n'),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ],
    );
  }
}
