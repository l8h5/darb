import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// فتح وإغلاق قاعدة بيانات التطبيق المحلية.
///
/// قاعدة واحدة فقط للتطبيق كله، فيها الأماكن المحفوظة والرحلات. فصلها في
/// صنف مستقل يسمح باستخدام قاعدة في الذاكرة أثناء الاختبارات دون لمس
/// ملفات الجهاز.
class SpotsDatabase {
  SpotsDatabase({DatabaseFactory? factory, this.path})
      : _factory = factory ?? databaseFactory;

  /// اسم ملف قاعدة البيانات داخل مجلد التطبيق الخاص.
  static const String fileName = 'darb_hail.db';

  /// إصدار المخطّط؛ يزيد عند كل تغيير في الجداول.
  ///
  /// * 1: جدول الأماكن المحفوظة.
  /// * 2: جداول الرحلات ونقاط المسار.
  static const int schemaVersion = 2;

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
        onConfigure: (db) async {
          // ضروري لحذف نقاط المسار تلقائياً عند حذف الرحلة.
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await _createSavedPlaces(db);
          await _createTrips(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _createTrips(db);
          }
        },
      ),
    );
  }

  static Future<void> _createSavedPlaces(Database db) async {
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
  }

  static Future<void> _createTrips(Database db) async {
    await db.execute('''
      CREATE TABLE trips (
        id TEXT PRIMARY KEY,
        started_at INTEGER NOT NULL,
        ended_at INTEGER,
        distance_m REAL NOT NULL DEFAULT 0,
        point_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_trips_started_at ON trips(started_at DESC)',
    );
    await db.execute('''
      CREATE TABLE trip_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id TEXT NOT NULL,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        recorded_at INTEGER NOT NULL,
        accuracy_m REAL,
        speed_mps REAL,
        altitude_m REAL,
        FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_trip_points_trip '
      'ON trip_points(trip_id, recorded_at)',
    );
  }

  Future<void> close() async {
    final db = _database;
    _database = null;
    await db?.close();
  }
}
