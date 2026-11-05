import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_place.dart';

/// تخزين الأماكن المحفوظة محلياً.
///
/// لماذا `shared_preferences` وليس قاعدة بيانات؟
///  * العدد المتوقع صغير (عشرات الأماكن)، فلا نحتاج فهرسة أو استعلامات.
///  * لا تكلفة، ولا صلاحيات إضافية، ويعمل دون إنترنت.
///  * عند الحاجة لاحقاً إلى آلاف المواقع ننتقل إلى SQLite في مهمة مستقلة.
///
/// البيانات تُحفظ كقائمة JSON تحت مفتاح واحد.
class SavedPlacesService {
  static const String storageKey = 'saved_places_v1';

  /// يقرأ القائمة من الجهاز. يعيد قائمة فارغة عند أول تشغيل أو تلف البيانات.
  Future<List<SavedPlace>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final places = <SavedPlace>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          places.add(SavedPlace.fromJson(Map<String, dynamic>.from(item)));
        } on FormatException {
          // نتجاهل السجل التالف ونُبقي بقية الأماكن.
        }
      }
      return places;
    } on FormatException {
      return const [];
    }
  }

  /// يضيف مكاناً في مقدمة القائمة (الأحدث أولاً) ويعيد القائمة الجديدة.
  Future<List<SavedPlace>> add(SavedPlace place) async {
    final places = await load();
    final updated = [place, ...places.where((p) => p.id != place.id)];
    await _write(updated);
    return updated;
  }

  /// يحذف مكاناً بالمعرّف ويعيد القائمة الجديدة.
  Future<List<SavedPlace>> remove(String id) async {
    final places = await load();
    final updated = places.where((p) => p.id != id).toList();
    await _write(updated);
    return updated;
  }

  Future<void> _write(List<SavedPlace> places) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(places.map((p) => p.toJson()).toList()),
    );
  }
}
