import 'dart:io';

import 'package:darb_hail/features/spots/data/saved_places_repository.dart';
import 'package:darb_hail/features/spots/data/spots_database.dart';
import 'package:darb_hail/features/trips/data/trip_recorder.dart';
import 'package:darb_hail/features/trips/data/trips_repository.dart';
import 'package:darb_hail/features/trips/domain/trip.dart';
import 'package:darb_hail/features/trips/domain/trip_stats.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String dbPath;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('darb_trips_test_');
    dbPath = p.join(tempDir.path, 'test.db');
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  SpotsDatabase openDatabase() =>
      SpotsDatabase(factory: databaseFactoryFfi, path: dbPath);

  group('TripStats', () {
    final start = DateTime(2026, 11, 6, 9);
    final first = TripPoint(
      latitude: 27.52,
      longitude: 41.72,
      recordedAt: start,
    );
    final second = TripPoint(
      latitude: 27.53,
      longitude: 41.72,
      recordedAt: start.add(const Duration(minutes: 10)),
    );

    test('المسافة بين نقطتين قريبة من القيمة المتوقعة', () {
      final meters = TripStats.distanceBetween(first, second);

      expect(meters, closeTo(1112, 10));
      expect(TripStats.totalDistance([first, second]), closeTo(meters, 0.01));
    });

    test('المدة ومتوسط السرعة', () {
      final duration = TripStats.duration([first, second]);

      expect(duration, const Duration(minutes: 10));
      expect(
        TripStats.averageSpeedKmh(
          distanceMeters: 1112,
          duration: duration,
        ),
        closeTo(6.67, 0.05),
      );
    });

    test('صياغة المدة بالعربية', () {
      expect(TripStats.formatDuration(Duration.zero), '0 دقيقة');
      expect(TripStats.formatDuration(const Duration(minutes: 12)), '12 دقيقة');
      expect(TripStats.formatDuration(const Duration(hours: 1)), 'ساعة');
      expect(TripStats.formatDuration(const Duration(hours: 2)), 'ساعتان');
      expect(
        TripStats.formatDuration(const Duration(hours: 3, minutes: 15)),
        '3 س 15 د',
      );
    });

    test('عدّاد المدة الحيّ بشكل ساعة رقمية', () {
      expect(TripStats.formatClock(Duration.zero), '00:00');
      expect(
        TripStats.formatClock(const Duration(minutes: 5, seconds: 7)),
        '05:07',
      );
      expect(
        TripStats.formatClock(
          const Duration(hours: 1, minutes: 5, seconds: 12),
        ),
        '1:05:12',
      );
    });
  });

  group('TripsRepository', () {
    test('دورة كاملة: إنشاء، نقاط، إنهاء، سجل، حذف', () async {
      final database = openDatabase();
      final repository = TripsRepository(database: database);
      final started = DateTime(2026, 11, 6, 9);

      final trip = await repository.create(startedAt: started);
      expect(trip.isActive, isTrue);
      expect((await repository.active())!.id, trip.id);

      final first = TripPoint(
        latitude: 27.52,
        longitude: 41.72,
        recordedAt: started,
      );
      final second = TripPoint(
        latitude: 27.53,
        longitude: 41.72,
        recordedAt: started.add(const Duration(minutes: 10)),
        altitudeMeters: 950,
      );
      final distance = TripStats.distanceBetween(first, second);

      await repository.appendPoint(
        tripId: trip.id,
        point: first,
        distanceMeters: 0,
        pointCount: 1,
      );
      await repository.appendPoint(
        tripId: trip.id,
        point: second,
        distanceMeters: distance,
        pointCount: 2,
      );

      final points = await repository.points(trip.id);
      expect(points, hasLength(2));
      expect(points.last.altitudeMeters, 950);

      final active = await repository.active();
      expect(active!.pointCount, 2);
      expect(active.distanceMeters, closeTo(distance, 0.01));

      final finished = await repository.finish(
        tripId: trip.id,
        distanceMeters: distance,
        pointCount: 2,
        endedAt: started.add(const Duration(minutes: 15)),
      );
      expect(finished!.endedAt, isNotNull);
      expect(await repository.active(), isNull);

      final history = await repository.history();
      expect(history, hasLength(1));
      expect(history.first.id, trip.id);

      await repository.delete(trip.id);
      expect(await repository.history(), isEmpty);
      expect(await repository.points(trip.id), isEmpty);

      await database.close();
    });

    test('الترقية من الإصدار 1 تحفظ الأماكن القديمة وتضيف الرحلات', () async {
      final legacy = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 1,
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
          },
        ),
      );
      await legacy.insert('saved_places', {
        'id': 'old_1',
        'name': 'مكان قديم',
        'lat': 27.5,
        'lng': 41.7,
        'created_at': DateTime(2026, 1, 1).millisecondsSinceEpoch,
      });
      await legacy.close();

      final database = openDatabase();
      final trips = TripsRepository(database: database);
      final places = SavedPlacesRepository(database: database);

      final trip = await trips.create(startedAt: DateTime(2026, 11, 6));
      expect((await trips.active())!.id, trip.id);

      final saved = await places.all();
      expect(saved, hasLength(1));
      expect(saved.first.name, 'مكان قديم');

      await database.close();
    });
  });

  group('TripRecorder', () {
    test('استعادة رحلة مفتوحة تجعلها متوقفة مؤقتاً وتحفظ مجاميعها', () async {
      final database = openDatabase();
      final repository = TripsRepository(database: database);
      final started = DateTime(2026, 11, 6, 9);

      final trip = await repository.create(startedAt: started);
      final first = TripPoint(
        latitude: 27.52,
        longitude: 41.72,
        recordedAt: started,
      );
      final second = TripPoint(
        latitude: 27.53,
        longitude: 41.72,
        recordedAt: started.add(const Duration(minutes: 10)),
      );
      final distance = TripStats.distanceBetween(first, second);

      await repository.appendPoint(
        tripId: trip.id,
        point: first,
        distanceMeters: 0,
        pointCount: 1,
      );
      await repository.appendPoint(
        tripId: trip.id,
        point: second,
        distanceMeters: distance,
        pointCount: 2,
      );

      final recorder = TripRecorder(repository: repository);
      await recorder.restore();

      expect(recorder.hasActiveTrip, isTrue);
      expect(recorder.isPaused, isTrue);
      expect(recorder.isRecording, isFalse);
      expect(recorder.recovered, isTrue);
      expect(recorder.pointCount, 2);
      expect(recorder.distanceMeters, closeTo(distance, 0.01));

      final finished = await recorder.finish();
      expect(finished, isNotNull);
      expect(await repository.active(), isNull);
      expect(await repository.history(), hasLength(1));

      recorder.dispose();
      await database.close();
    });
  });
}
