import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// حساب اتجاه القبلة محلياً بلا إنترنت وبلا خدمة خارجية.
///
/// الاتجاه هو زاوية البوصلة (0 = شمال، 90 = شرق) من موقع المستخدم إلى
/// الكعبة، محسوباً بمعادلة الدائرة العظمى (initial bearing).
class QiblaCalculator {
  const QiblaCalculator._();

  /// إحداثيات الكعبة المشرفة.
  static const LatLng kaaba = LatLng(21.4225, 39.8262);

  static double _rad(double degrees) => degrees * math.pi / 180;
  static double _deg(double radians) => radians * 180 / math.pi;

  /// اتجاه القبلة بالدرجات من الشمال الحقيقي.
  static double bearingFrom(LatLng from) {
    final lat1 = _rad(from.latitude);
    final lat2 = _rad(kaaba.latitude);
    final deltaLng = _rad(kaaba.longitude - from.longitude);

    final y = math.sin(deltaLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLng);

    // عند الوقوف على الكعبة نفسها لا يوجد اتجاه؛ نعيد صفراً بدل NaN.
    if (x == 0 && y == 0) return 0;

    return _normalize(_deg(math.atan2(y, x)));
  }

  /// المسافة إلى الكعبة بالأمتار.
  static double distanceMetersFrom(LatLng from) {
    return const Distance().as(LengthUnit.Meter, from, kaaba);
  }

  /// وصف عربي مختصر للاتجاه (ثمانية اتجاهات).
  static String directionLabel(double bearing) {
    const labels = [
      'شمال',
      'شمال شرق',
      'شرق',
      'جنوب شرق',
      'جنوب',
      'جنوب غرب',
      'غرب',
      'شمال غرب',
    ];
    final index = (((bearing % 360) + 22.5) ~/ 45) % 8;
    return labels[index];
  }

  static double _normalize(double value) => (value % 360 + 360) % 360;
}
