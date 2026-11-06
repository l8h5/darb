import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// فتح وإغلاق قاعدة بيانات الكشتات المحلية.
///
/// قاعدة واحدة فقط للتطبيق كله. فصلها في صنف مستقل يسمح باستخدام قاعدة
/// في الذاكرة أثناء الاختبارات دون لمس ملفات الجهاز.
class SpotsDatabase {
  SpotsDatabase({DatabaseFactory? factory, this.path})
      : _factory = factory ?? databaseFactory;

  /// اسم ملف قاعدة البيانات داخل مجلد التطبيق الخاص.
  static const String fileName = 'darb_hail.db';

  /// إصدار المخطّط؛ يزيد عند كل تغيير في الجداول.
  static const int schemaVersion = 1;

  final DatabaseFactory _factory;

  /// مسار مخصّص (اختبارات فقط)؛ فارغ يعني ملف التطبيق الافتراضي.
  final String? path;

  Database? _database;

  /// تُفتح مرة واحدة عند أول طلب ثم تُعاد نفس النسخة.
  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    final databasePath =
        path ?? p.join(await _factory.getDatabasesPath(), fileName);

    return _factory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE saved_places (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              lat REAL NOT NULL,
              lng REAL NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_saved_places_created_at '
            'ON saved_places(created_at DESC)',
          );
        },
      ),
    );
  }

  Future<void> close() async {
    final db = _database;
    _database = null;
    await db?.close();
  }
}
