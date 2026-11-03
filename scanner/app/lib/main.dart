import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AppWidget(prefs: await SharedPreferences.getInstance()));
}
