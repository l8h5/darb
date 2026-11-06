import 'package:flutter/material.dart';

import 'app/app.dart';
import 'features/settings/presentation/preferences_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // التفضيلات تُحمَّل قبل أول إطار حتى لا تظهر التهيئة لمن أكملها سابقاً.
  final preferences = PreferencesController();
  await preferences.load();

  runApp(DarbHailApp(preferences: preferences));
}
