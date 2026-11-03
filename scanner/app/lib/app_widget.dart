import 'package:flutter/material.dart';
import 'package:flutter_injections/flutter_injections.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/access_code_store.dart';
import 'core/hms_table_repository.dart';
import 'core/variant_store.dart';
import 'l10n/app_localizations.dart';
import 'modules/discovery/discovery_module.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return FlutterInjectionsWidget(
      injections: [
        Inject<SharedPreferences>.singleton((_) => prefs),
        Inject<AccessCodeStore>.singleton((i) => AccessCodeStore(prefs)),
        Inject<HmsTableRepository>.singleton(
          (i) => HmsTableRepository(prefs),
        ),
        Inject<VariantStore>.singleton((i) => VariantStore(prefs)),
      ],
      builder: (_) => MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF00AE42),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: const Color(0xFF00AE42),
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        home: const DiscoveryModule(),
      ),
    );
  }
}
