import 'package:flutter/foundation.dart';

import '../data/preferences_repository.dart';
import '../domain/user_preferences.dart';

/// المصدر الوحيد لحالة تفضيلات المستخدم في التطبيق.
///
/// لا نضيف حزمة إدارة حالة جديدة: `ChangeNotifier` جزء من Flutter ويكفي
/// لهذه الحالة الصغيرة. الواجهات تستمع عبر `PreferencesScope`.
class PreferencesController extends ChangeNotifier {
  PreferencesController({PreferencesRepository? repository})
      : _repository = repository ?? PreferencesRepository();

  final PreferencesRepository _repository;

  UserPreferences _preferences = const UserPreferences();
  UserPreferences get preferences => _preferences;

  /// تُستدعى مرة واحدة عند تشغيل التطبيق قبل بناء الواجهة.
  Future<void> load() async {
    _preferences = await _repository.load();
    notifyListeners();
  }

  /// يحدّث الحالة فوراً ثم يحاول الحفظ.
  ///
  /// يعيد `false` عند فشل التخزين، لكن التطبيق يكمل بالحالة الجديدة في
  /// الذاكرة حتى لا يمنع عطلاً بسيطاً المستخدم من استخدام التطبيق.
  Future<bool> save(UserPreferences next) async {
    _preferences = next;
    notifyListeners();

    try {
      await _repository.save(next);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// إنهاء التهيئة مع حفظ الاختيارات المختارة.
  Future<bool> completeOnboarding(UserPreferences choices) {
    return save(choices.copyWith(onboardingCompleted: true));
  }

  /// التخطي: يُبقي التفضيلات الحالية/الافتراضية وينهي التهيئة.
  Future<bool> skipOnboarding() {
    return save(_preferences.copyWith(onboardingCompleted: true));
  }

  /// إعادة إظهار التهيئة من الإعدادات دون المساس ببيانات الأماكن.
  Future<bool> restartOnboarding() {
    return save(_preferences.copyWith(onboardingCompleted: false));
  }
}
