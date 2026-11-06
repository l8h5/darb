import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../domain/saved_place.dart';
import 'spots_database.dart';

/// تخزين الكشتات محلياً في SQLite.
///
/// لماذا SQLite وليس قائمة JSON؟
///  * البحث والترتيب والتعديل تصبح استعلامات بسيطة، لا إعادة كتابة الملف كله.
///  * البيانات تبقى سليمة حتى لو انقطع التطبيق أثناء الحفظ.
///  * لا سيرفر ولا صلاحيات ولا تكلفة شهرية.
class SavedPlacesRepository {
  SavedPlacesRepository({SpotsDatabase? database})
      : _database = database ?? SpotsDatabase();

  final SpotsDatabase _database;

  /// مفتاح التخزين القديم (JSON). يُقرأ مرة واحدة للترحيل ثم يُحذف.
  static const String legacyStorageKey = 'saved_places_v1';

  static const String _table = 'saved_places';

  bool _migrationChecked = false;

  /// كل الأماكن، الأحدث أولاً.
  Future<List<SavedPlace>> all() async {
    final db = await _database.database;
    await _migrateLegacy(db);

    final rows = await db.query(
      _table,
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  /// يضيف مكاناً (أو يستبدل مكاناً بنفس المعرّف) ويعيد القائمة الجديدة.
  Future<List<SavedPlace>> add(SavedPlace place) async {
    final db = await _database.database;
    await _migrateLegacy(db);

    await db.insert(
      _table,
      _toRow(place),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return all();
  }

  /// يعدّل بيانات مكان قائم (الاسم حالياً) ويعيد القائمة الجديدة.
  Future<List<SavedPlace>> update(SavedPlace place) async {
    final db = await _database.database;
    await _migrateLegacy(db);

    await db.update(
      _table,
      _toRow(place),
      where: 'id = ?',
      whereArgs: [place.id],
    );
    return all();
  }

  /// يحذف مكاناً بالمعرّف ويعيد القائمة الجديدة.
  Future<List<SavedPlace>> remove(String id) async {
    final db = await _database.database;
    await _migrateLegacy(db);

    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
    return all();
  }

  /// يُغلق الملف عند مغادرة الشاشة حتى لا يبقى مفتوحاً في الخلفية.
  Future<void> close() => _database.close();

  /// ترحيل بيانات الإصدار السابق (JSON في `shared_preferences`).
  ///
  /// يُنفَّذ مرة واحدة فقط: بعد نجاح الإدخال يُحذف المفتاح القديم.
  /// يمكن حذف هذه الدالة بعد إصدارين من استقرار التطبيق.
  Future<void> _migrateLegacy(Database db) async {
    if (_migrationChecked) return;
    _migrationChecked = true;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(legacyStorageKey);
    if (raw == null || raw.isEmpty) return;

    final places = _decodeLegacy(raw);
    if (places.isNotEmpty) {
      final batch = db.batch();
      for (final place in places) {
        batch.insert(
          _table,
          _toRow(place),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    }

    // حتى لو كان الملف تالفاً نحذفه؛ لا فائدة من إعادة محاولة فاشلة كل تشغيل.
    await prefs.remove(legacyStorageKey);
  }

  /// يتجاهل السجلات التالفة ويُبقي الصالحة.
  List<SavedPlace> _decodeLegacy(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final places = <SavedPlace>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          places.add(SavedPlace.fromJson(Map<String, dynamic>.from(item)));
        } on FormatException {
          // سجل تالف: نتخطاه.
        }
      }
      return places;
    } on FormatException {
      return const [];
    }
  }

  Map<String, Object?> _toRow(SavedPlace place) => {
        'id': place.id,
        'name': place.name,
        'lat': place.latitude,
        'lng': place.longitude,
        'created_at': place.createdAt.millisecondsSinceEpoch,
      };

  SavedPlace _fromRow(Map<String, Object?> row) => SavedPlace(
        id: row['id']! as String,
        name: row['name']! as String,
        latitude: (row['lat']! as num).toDouble(),
        longitude: (row['lng']! as num).toDouble(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (row['created_at']! as num).toInt(),
        ),
      );
}
