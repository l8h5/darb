import 'package:darb_hail/core/app_config.dart';
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

    test('قالب بلاطات OSM صحيح', () {
      expect(AppConfig.osmTileUrl, startsWith('https://'));
      expect(AppConfig.osmTileUrl, contains('{z}'));
      expect(AppConfig.osmTileUrl, contains('{x}'));
      expect(AppConfig.osmTileUrl, contains('{y}'));
    });

    test('معرّف User-Agent غير فارغ', () {
      expect(AppConfig.osmUserAgentPackage.trim(), isNotEmpty);
    });
  });
}
