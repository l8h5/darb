import 'package:darb_hail/core/config/app_config.dart';
import 'package:darb_hail/features/map/domain/map_layer.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('مركز حائل يقع داخل حدود المملكة', () {
      final ksa = LatLngBounds(
        AppConfig.saudiSouthWest,
        AppConfig.saudiNorthEast,
      );

      expect(ksa.contains(AppConfig.hail), isTrue);
    });

    test('مستوى التكبير الابتدائي داخل الحدود المسموحة', () {
      expect(
        AppConfig.hailZoom,
        inInclusiveRange(AppConfig.minZoom, AppConfig.maxZoom),
      );
      expect(
        AppConfig.myLocationZoom,
        inInclusiveRange(AppConfig.minZoom, AppConfig.maxZoom),
      );
    });

    test('قوالب بلاطات الطبقات صحيحة', () {
      for (final layer in MapLayer.values) {
        expect(layer.urlTemplate, startsWith('https://'));
        expect(layer.urlTemplate, contains('{z}'));
        expect(layer.urlTemplate, contains('{x}'));
        expect(layer.urlTemplate, contains('{y}'));
        expect(layer.attribution.trim(), isNotEmpty);
        // قد يكون أعلى من maxZoom لأن الخريطة تمدّ آخر مستوى متاح.
        expect(
          layer.maxNativeZoom,
          greaterThanOrEqualTo(AppConfig.minZoom.toInt()),
        );
      }
    });

    test('معرّف User-Agent غير فارغ', () {
      expect(AppConfig.osmUserAgentPackage.trim(), isNotEmpty);
    });
  });
}
