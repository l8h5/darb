import 'package:latlong2/latlong.dart';

import 'trip.dart';

/// حسابات المسار والسرعة والمدة، منفصلة عن الحساسات وقاعدة البيانات.
class TripStats {
  const TripStats._();

  static const Distance _distance = Distance();

  /// مسافة بالمتر بين نقطتين على سطح الأرض.
  static double distanceBetween(TripPoint a, TripPoint b) {
    return _distance.as(LengthUnit.Meter, a.point, b.point);
  }

  /// مجموع المسافات بين نقاط متتالية.
  static double totalDistance(List<TripPoint> points) {
    var total = 0.0;
    for (var index = 1; index < points.length; index++) {
      total += distanceBetween(points[index - 1], points[index]);
    }
    return total;
  }

  /// مدة الرحلة من أول نقطة إلى آخر نقطة.
  static Duration duration(List<TripPoint> points) {
    if (points.length < 2) return Duration.zero;
    return points.last.recordedAt.difference(points.first.recordedAt);
  }

  /// متوسط السرعة بالكيلومتر/الساعة (صفر إذا كانت المدة صفراً).
  static double averageSpeedKmh({
    required double distanceMeters,
    required Duration duration,
  }) {
    final seconds = duration.inMilliseconds / 1000;
    if (seconds <= 0 || distanceMeters <= 0) return 0;
    return (distanceMeters / seconds) * 3.6;
  }

  /// مدة بشكل ساعة رقمية للعدّاد الحيّ: «05:12» أو «1:05:12».
  ///
  /// الرقم الرقمي أوضح من صياغة عربية أثناء العدّ التصاعدي كل ثانية.
  static String formatClock(Duration duration) {
    final total = duration.isNegative ? Duration.zero : duration;
    final hours = total.inHours;
    final minutes = total.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = total.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  /// صياغة المدة بالعربية: «ساعتان و15 دقيقة» أو «12 دقيقة».
  static String formatDuration(Duration duration) {
    if (duration <= Duration.zero) return '0 دقيقة';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours == 0) return '$minutes دقيقة';
    if (minutes == 0) {
      return hours == 1 ? 'ساعة' : hours == 2 ? 'ساعتان' : '$hours ساعات';
    }
    return '$hours س $minutes د';
  }
}
