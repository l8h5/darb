import 'package:darb_hail/features/map/domain/map_layer.dart';
import 'package:darb_hail/features/settings/data/preferences_repository.dart';
import 'package:darb_hail/features/settings/domain/user_preferences.dart';
import 'package:darb_hail/features/settings/presentation/preferences_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserPreferences', () {
    test('القيم الافتراضية آمنة ووضع بسيط', () {
      const prefs = UserPreferences();

      expect(prefs.onboardingCompleted, isFalse);
      expect(prefs.usageMode, UsageMode.simple);
      expect(prefs.defaultLayer, MapLayer.streets);
      expect(prefs.distanceUnit, DistanceUnit.kilometers);
      expect(prefs.coordinateFormat, CoordinateFormat.decimal);
    });

    test('التحويل إلى JSON ثم القراءة يعيد نفس القيم', () {
      const prefs = UserPreferences(
        onboardingCompleted: true,
        usageMode: UsageMode.advanced,
        defaultLayer: MapLayer.terrain,
        distanceUnit: DistanceUnit.miles,
        coordinateFormat: CoordinateFormat.dms,
      );

      final restored = UserPreferences.fromJson(prefs.toJson());

      expect(restored, prefs);
    });

    test('القيم غير المعروفة ترجع للافتراضي بدل الرفض', () {
      final restored = UserPreferences.fromJson({
        'onboardingCompleted': 'نعم',
        'usageMode': 'turbo',
        'defaultLayer': 'unknown',
        'distanceUnit': 12,
        'coordinateFormat': null,
      });

      expect(restored, const UserPreferences());
    });

    test('copyWith يغيّر الحقل المطلوب فقط', () {
      const prefs = UserPreferences(onboardingCompleted: true);
      final updated = prefs.copyWith(usageMode: UsageMode.advanced);

      expect(updated.usageMode, UsageMode.advanced);
      expect(updated.onboardingCompleted, isTrue);
      expect(updated.defaultLayer, prefs.defaultLayer);
    });
  });

  group('PreferencesRepository', () {
    test('يعيد الافتراضي عند عدم وجود بيانات محفوظة', () async {
      final repository = PreferencesRepository();
      expect(await repository.load(), const UserPreferences());
    });

    test('حفظ التفضيلات ثم قراءتها من جديد', () async {
      final repository = PreferencesRepository();
      const prefs = UserPreferences(
        onboardingCompleted: true,
        usageMode: UsageMode.advanced,
        defaultLayer: MapLayer.satellite,
      );

      await repository.save(prefs);
      final restored = await PreferencesRepository().load();

      expect(restored, prefs);
    });

    test('بيانات تالفة لا تُسقط التطبيق', () async {
      SharedPreferences.setMockInitialValues({
        PreferencesRepository.storageKey: '{ليس JSON صالحاً',
      });

      expect(
        await PreferencesRepository().load(),
        const UserPreferences(),
      );
    });
  });

  group('PreferencesController', () {
    test('إكمال التهيئة يحفظ الاختيارات وحالة الإكمال', () async {
      final controller = PreferencesController();
      const choices = UserPreferences(
        usageMode: UsageMode.advanced,
        defaultLayer: MapLayer.terrain,
      );

      final saved = await controller.completeOnboarding(choices);

      expect(saved, isTrue);
      expect(controller.preferences.onboardingCompleted, isTrue);
      expect(controller.preferences.usageMode, UsageMode.advanced);

      final reloaded = await PreferencesRepository().load();
      expect(reloaded.onboardingCompleted, isTrue);
      expect(reloaded.defaultLayer, MapLayer.terrain);
    });

    test('التخطي ينهي التهيئة ويُبقي القيم الحالية', () async {
      final controller = PreferencesController();
      await controller.save(
        const UserPreferences(usageMode: UsageMode.advanced),
      );

      await controller.skipOnboarding();

      expect(controller.preferences.onboardingCompleted, isTrue);
      expect(controller.preferences.usageMode, UsageMode.advanced);
    });

    test('إعادة التهيئة لا تحذف بقية التفضيلات', () async {
      final controller = PreferencesController();
      await controller.completeOnboarding(
        const UserPreferences(distanceUnit: DistanceUnit.miles),
      );

      await controller.restartOnboarding();

      expect(controller.preferences.onboardingCompleted, isFalse);
      expect(controller.preferences.distanceUnit, DistanceUnit.miles);
    });

    test('فشل التخزين لا يمنع الاستخدام', () async {
      final controller = PreferencesController(
        repository: _FailingRepository(),
      );

      final saved = await controller.save(
        const UserPreferences(usageMode: UsageMode.advanced),
      );

      expect(saved, isFalse);
      expect(controller.preferences.usageMode, UsageMode.advanced);
    });
  });
}

class _FailingRepository extends PreferencesRepository {
  @override
  Future<void> save(UserPreferences preferences) async {
    throw StateError('تخزين غير متاح');
  }
}
