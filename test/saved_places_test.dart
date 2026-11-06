import 'dart:io';

import 'package:darb_hail/features/spots/data/saved_places_repository.dart';
import 'package:darb_hail/features/spots/data/spots_database.dart';
import 'package:darb_hail/features/spots/domain/saved_place.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
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
    tempDir = await Directory.systemTemp.createTemp('darb_hail_test_');
    dbPath = p.join(tempDir.path, 'test.db');
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  SavedPlacesRepository openRepository() => SavedPlacesRepository(
        database: SpotsDatabase(
          factory: databaseFactoryFfi,
          path: dbPath,
        ),
      );

  group('SavedPlace', () {
    test('التحويل إلى JSON ثم القراءة يعيد نفس البيانات', () {
      final place = SavedPlace(
        id: '42',
        name: 'شعيب أبو رضمة',
        latitude: 27.6,
        longitude: 41.9,
        createdAt: DateTime(2026, 11, 4, 20, 30),
      );

      final restored = SavedPlace.fromJson(place.toJson());

      expect(restored.id, place.id);
      expect(restored.name, place.name);
      expect(restored.latitude, place.latitude);
      expect(restored.longitude, place.longitude);
      expect(restored.createdAt, place.createdAt);
      expect(restored.point, const LatLng(27.6, 41.9));
    });

    test('البيانات الناقصة تُرفض', () {
      expect(
        () => SavedPlace.fromJson({'id': '1', 'name': 'ناقص'}),
        throwsFormatException,
      );
    });

    test('copyWith يغيّر الاسم فقط', () {
      final place = SavedPlace.create(
        name: 'الاسم القديم',
        point: const LatLng(27.5, 41.7),
      );

      final renamed = place.copyWith(name: 'الاسم الجديد');

      expect(renamed.id, place.id);
      expect(renamed.name, 'الاسم الجديد');
      expect(renamed.createdAt, place.createdAt);
      expect(renamed.point, place.point);
    });
  });

  group('SavedPlacesRepository (SQLite)', () {
    test('يعيد قائمة فارغة عند أول تشغيل', () async {
      final repository = openRepository();
      expect(await repository.all(), isEmpty);
      await repository.close();
    });

    test('الإضافة تحفظ في الملف وتُظهر الأحدث أولاً', () async {
      final first = SavedPlace.create(
        name: 'الأول',
        point: const LatLng(27.5, 41.7),
        createdAt: DateTime(2026, 1, 1),
      );
      final second = SavedPlace.create(
        name: 'الثاني',
        point: const LatLng(27.6, 41.8),
        createdAt: DateTime(2026, 1, 2),
      );

      final repository = openRepository();
      await repository.add(first);
      await repository.add(second);
      await repository.close();

      // إعادة فتح الملف تحاكي إغلاق التطبيق وتشغيله من جديد.
      final reopened = openRepository();
      final places = await reopened.all();
      await reopened.close();

      expect(places.map((place) => place.name), ['الثاني', 'الأول']);
      expect(places.first.point, const LatLng(27.6, 41.8));
    });

    test('تعديل اسم مكان قائم', () async {
      final repository = openRepository();
      final place = SavedPlace.create(
        name: 'قديم',
        point: const LatLng(27.5, 41.7),
      );
      await repository.add(place);

      final updated = await repository.update(place.copyWith(name: 'جديد'));
      await repository.close();

      expect(updated, hasLength(1));
      expect(updated.single.name, 'جديد');
      expect(updated.single.id, place.id);
    });

    test('الحذف بالمعرّف', () async {
      final repository = openRepository();
      final place = SavedPlace.create(
        name: 'مكان',
        point: const LatLng(27.5, 41.7),
      );

      await repository.add(place);
      final remaining = await repository.remove(place.id);
      await repository.close();

      expect(remaining, isEmpty);
    });

    test('ترحيل بيانات JSON القديمة إلى SQLite مرة واحدة', () async {
      final legacy = SavedPlace(
        id: 'legacy-1',
        name: 'مكان قديم',
        latitude: 27.7,
        longitude: 41.9,
        createdAt: DateTime(2026, 2, 3),
      );
      SharedPreferences.setMockInitialValues({
        SavedPlacesRepository.legacyStorageKey:
            '[${_jsonOf(legacy)}]',
      });

      final repository = openRepository();
      final migrated = await repository.all();
      await repository.close();

      expect(migrated.single.name, 'مكان قديم');
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(SavedPlacesRepository.legacyStorageKey),
        isNull,
      );
    });

    test('البيانات التالفة تُتجاهل ولا تُسقط التطبيق', () async {
      SharedPreferences.setMockInitialValues({
        SavedPlacesRepository.legacyStorageKey: '{ليس JSON صالحاً',
      });

      final repository = openRepository();
      expect(await repository.all(), isEmpty);
      await repository.close();
    });
  });
}

String _jsonOf(SavedPlace place) {
  final json = place.toJson();
  return '{'
      '"id":"${json['id']}",'
      '"name":"${json['name']}",'
      '"lat":${json['lat']},'
      '"lng":${json['lng']},'
      '"createdAt":"${json['createdAt']}"'
      '}';
}
