import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/user_preferences.dart';

/// قراءة وكتابة تفضيلات المستخدم في التخزين المحلي.
///
/// `shared_preferences` كانت موجودة في المشروع أصلاً (لترحيل الأماكن القديمة)،
/// لذلك لا نضيف قاعدة بيانات جديدة لبيانات صغيرة كهذه.
class PreferencesRepository {
  /// مفتاح واحد يحتوي كل التفضيلات كـ JSON، مما يسهّل الترحيل مستقبلاً.
  static const String storageKey = 'user_preferences_v1';

  Future<UserPreferences> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.isEmpty) return const UserPreferences();

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const UserPreferences();

      return UserPreferences.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      // تخزين تالف أو غير متاح: الافتراضي هو الأمان.
      return const UserPreferences();
    }
  }

  Future<void> save(UserPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      storageKey,
      jsonEncode(preferences.toJson()),
    );
    if (!saved) {
      throw StateError('تعذّر حفظ التفضيلات');
    }
  }
}
