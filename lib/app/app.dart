import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/config/app_config.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/settings/presentation/preferences_controller.dart';
import '../features/settings/presentation/preferences_scope.dart';
import 'app_theme.dart';
import 'home_shell.dart';

/// جذر التطبيق: اللغة العربية، اتجاه RTL، والسمة العامة.
///
/// [preferences] يُحمَّل قبل `runApp`، ويُشارَك مع كل الشاشات عبر
/// [PreferencesScope] حتى يُطبَّق أي تغيير فوراً.
class DarbHailApp extends StatelessWidget {
  const DarbHailApp({super.key, required this.preferences});

  final PreferencesController preferences;

  @override
  Widget build(BuildContext context) {
    return PreferencesScope(
      controller: preferences,
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light(),
        home: const _RootGate(),
      ),
    );
  }
}

/// يقرر أول شاشة: التهيئة عند أول تشغيل، أو الخريطة بعدها.
///
/// يعتمد على `InheritedNotifier`، فلا تُعاد التهيئة بسبب إعادة بناء
/// Widget عادية؛ فقط عند تغيّر حالة الإكمال فعلياً.
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final controller = PreferencesScope.of(context);

    return controller.preferences.onboardingCompleted
        ? const HomeShell()
        : OnboardingScreen(controller: controller);
  }
}
