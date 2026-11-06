/// كتابة المسافة بالوحدة التي اختارها المستخدم.
class DistanceFormatter {
  const DistanceFormatter._();

  static const double _metersPerMile = 1609.344;

  static String format(double meters, {required bool miles}) {
    if (meters.isNaN || meters.isInfinite || meters < 0) return '';

    if (!miles) {
      if (meters < 1000) return '${meters.round()} م';
      return '${(meters / 1000).toStringAsFixed(1)} كم';
    }

    if (meters < _metersPerMile / 10) return '${meters.round()} م';
    return '${(meters / _metersPerMile).toStringAsFixed(1)} ميل';
  }
}
