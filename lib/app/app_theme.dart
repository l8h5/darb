import 'package:flutter/material.dart';

/// سمة التطبيق الموحّدة.
///
/// كل الألوان تأتي من بذرة واحدة، فتبقى الواجهة متناسقة عند إضافة شاشات جديدة.
class AppTheme {
  const AppTheme._();

  /// لون رملي مستوحى من طبيعة حائل.
  static const Color _seed = Color(0xFF7A5C32);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: _seed),
    );
  }
}
