import 'package:darb_hail/models/saved_place.dart';
import 'package:darb_hail/services/saved_places_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    test('create يولّد معرّفاً غير فارغ', () {
      final place = SavedPlace.create(
        name: 'محطة',
        point: const LatLng(27.5, 41.7),
      );

      expect(place.id, isNotEmpty);
      expect(place.name, 'محطة');
    });
  });

  group('SavedPlacesService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('يعيد قائمة فارغة عند أول تشغيل', () async {
      final service = SavedPlacesService();
      expect(await service.load(), isEmpty);
    });

    test('الإضافة تحفظ على الجهاز وتُظهر الأحدث أولاً', () async {
      final service = SavedPlacesService();
      final first = SavedPlace.create(
        name: 'الأول',
        point: const LatLng(27.5, 41.7),
      );
      final second = SavedPlace.create(
        name: 'الثاني',
        point: const LatLng(27.6, 41.8),
      );

      await service.add(first);
      await service.add(second);

      final reloaded = await SavedPlacesService().load();
      expect(reloaded.map((p) => p.name), ['الثاني', 'الأول']);
    });

    test('الحذف بالمعرّف', () async {
      final service = SavedPlacesService();
      final place = SavedPlace.create(
        name: 'مكان',
        point: const LatLng(27.5, 41.7),
      );

      await service.add(place);
      final remaining = await service.remove(place.id);

      expect(remaining, isEmpty);
      expect(await service.load(), isEmpty);
    });

    test('البيانات التالفة تُتجاهل ولا تُسقط التطبيق', () async {
      SharedPreferences.setMockInitialValues({
        SavedPlacesService.storageKey: '{ليس JSON صالحاً',
      });

      expect(await SavedPlacesService().load(), isEmpty);
    });
  });
}
