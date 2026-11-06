import 'package:darb_hail/features/onboarding/presentation/onboarding_screen.dart';
import 'package:darb_hail/features/settings/domain/user_preferences.dart';
import 'package:darb_hail/features/settings/presentation/preferences_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('التخطي ينهي التهيئة فوراً', (tester) async {
    final controller = PreferencesController();
    await tester.pumpWidget(
      MaterialApp(home: OnboardingScreen(controller: controller)),
    );

    expect(find.text('أهلاً بك في درب'), findsOneWidget);

    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();

    expect(controller.preferences.onboardingCompleted, isTrue);
  });

  testWidgets('اختيار الوضع المتقدم يُحفظ عند إكمال التهيئة', (tester) async {
    final controller = PreferencesController();
    await tester.pumpWidget(
      MaterialApp(home: OnboardingScreen(controller: controller)),
    );

    await tester.tap(find.text('ابدأ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الوضع المتقدم'));
    await tester.pumpAndSettle();

    // الخطوات المتبقية: الخريطة، الاستخدام، الملخص.
    for (var index = 0; index < 3; index++) {
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('ابدأ رحلتك مع درب'));
    await tester.pumpAndSettle();

    expect(controller.preferences.usageMode, UsageMode.advanced);
    expect(controller.preferences.onboardingCompleted, isTrue);
  });
}
