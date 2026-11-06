import 'package:darb_hail/core/format/coordinate_formatter.dart';
import 'package:darb_hail/core/format/distance_formatter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('CoordinateFormatter', () {
    test('الصيغة العشرية بخمس خانات', () {
      expect(
        CoordinateFormatter.format(
          const LatLng(27.52, 41.72),
          dms: false,
        ),
        '27.52000, 41.72000',
      );
    });

    test('صيغة الدرجات والدقائق والثواني', () {
      expect(
        CoordinateFormatter.format(
          const LatLng(27.52, 41.72),
          dms: true,
        ),
        '27°31\'12.0"N 41°43\'12.0"E',
      );
    });

    test('الاتجاه الجنوبي والغربي', () {
      expect(
        CoordinateFormatter.format(
          const LatLng(-27.52, -41.72),
          dms: true,
        ),
        '27°31\'12.0"S 41°43\'12.0"W',
      );
    });
  });

  group('DistanceFormatter', () {
    test('الكيلومترات والأمتار', () {
      expect(DistanceFormatter.format(550, miles: false), '550 م');
      expect(DistanceFormatter.format(1500, miles: false), '1.5 كم');
    });

    test('الأميال', () {
      expect(DistanceFormatter.format(1609.344, miles: true), '1.0 ميل');
    });

    test('القيم غير الصالحة تُعرض فارغة', () {
      expect(DistanceFormatter.format(double.nan, miles: false), '');
      expect(DistanceFormatter.format(-1, miles: true), '');
    });
  });
}
