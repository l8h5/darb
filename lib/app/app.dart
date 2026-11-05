import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_config.dart';
import 'screens/map_screen.dart';

void main() {
  runApp(const DarbHailApp());
}

/// جذر التطبيق: اللغة العربية، اتجاه RTL، والسمة العامة.
class DarbHailApp extends StatelessWidget {
  const DarbHailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7A5C32),
        ),
      ),
      home: const MapScreen(),
    );
  }
}
