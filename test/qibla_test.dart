import 'package:darb_hail/features/qibla/data/compass_math.dart';
import 'package:darb_hail/features/qibla/domain/qibla_calculator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('QiblaCalculator', () {
    test('اتجاه القبلة من حائل جنوبي غربي', () {
      final bearing = QiblaCalculator.bearingFrom(
        const LatLng(27.52, 41.72),
      );

      expect(bearing, closeTo(196.2, 1.0));
      expect(QiblaCalculator.directionLabel(bearing), 'جنوب');
    });

    test('من شمال الكعبة الاتجاه جنوباً', () {
      final bearing = QiblaCalculator.bearingFrom(
        const LatLng(30.4225, 39.8262),
      );

      expect(bearing, closeTo(180, 0.001));
    });

    test('من جنوب الكعبة الاتجاه شمالاً', () {
      final bearing = QiblaCalculator.bearingFrom(
        const LatLng(11.4225, 39.8262),
      );

      expect(bearing, closeTo(0, 0.001));
    });

    test('عند الكعبة نفسها لا يوجد اتجاه ولا NaN', () {
      final bearing = QiblaCalculator.bearingFrom(QiblaCalculator.kaaba);

      expect(bearing, 0);
      expect(bearing.isNaN, isFalse);
    });

    test('مسافة حائل إلى الكعبة في النطاق المتوقع', () {
      final meters = QiblaCalculator.distanceMetersFrom(
        const LatLng(27.52, 41.72),
      );

      expect(meters, greaterThan(650000));
      expect(meters, lessThan(760000));
    });

    test('وصف الاتجاهات الثمانية', () {
      expect(QiblaCalculator.directionLabel(0), 'شمال');
      expect(QiblaCalculator.directionLabel(90), 'شرق');
      expect(QiblaCalculator.directionLabel(180), 'جنوب');
      expect(QiblaCalculator.directionLabel(270), 'غرب');
      expect(QiblaCalculator.directionLabel(359), 'شمال');
    });
  });

  group('CompassMath', () {
    test('الجهاز مسطح وأعلاه نحو الشمال', () {
      final heading = CompassMath.headingFrom(
        ax: 0,
        ay: 0,
        az: 9.8,
        mx: 0,
        my: 30,
        mz: -20,
      );

      expect(heading, closeTo(0, 0.001));
    });

    test('الجهاز مسطح وأعلاه نحو الشرق', () {
      final heading = CompassMath.headingFrom(
        ax: 0,
        ay: 0,
        az: 9.8,
        mx: -30,
        my: 0,
        mz: -20,
      );

      expect(heading, closeTo(90, 0.001));
    });

    test('قراءة صفرية لا تعطي NaN', () {
      final heading = CompassMath.headingFrom(
        ax: 0,
        ay: 0,
        az: 0,
        mx: 0,
        my: 0,
        mz: 0,
      );

      expect(heading, isNull);
    });

    test('التمهيد لا يقفز بين 359 و0', () {
      final smoothed = CompassMath.smooth(359, 1);

      expect(smoothed, anyOf(lessThan(2), greaterThan(358)));
    });

    test('أقصر فرق بين زاويتين', () {
      expect(CompassMath.shortestDifference(10, 350), closeTo(20, 0.001));
      expect(CompassMath.shortestDifference(350, 10), closeTo(-20, 0.001));
      expect(CompassMath.shortestDifference(180, 0), closeTo(180, 0.001));
    });
  });
}
