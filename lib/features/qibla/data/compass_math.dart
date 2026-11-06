import 'dart:math' as math;

/// رياضيات البوصلة، منفصلة عن الحساسات حتى تُختبر بلا جهاز.
class CompassMath {
  const CompassMath._();

  /// يحسب اتجاه أعلى الجهاز (0 = شمال) من قراءتي مقياس التسارع والمجال
  /// المغناطيسي، مع تعويض ميل الجهاز.
  ///
  /// يعيد `null` إذا كانت القراءات غير صالحة (أصفار أو متجهات متوازية).
  static double? headingFrom({
    required double ax,
    required double ay,
    required double az,
    required double mx,
    required double my,
    required double mz,
  }) {
    final normA = math.sqrt(ax * ax + ay * ay + az * az);
    if (normA == 0) return null;

    final ux = ax / normA;
    final uy = ay / normA;
    final uz = az / normA;

    // الشرق = حاصل ضرب المجال المغناطيسي في تسارع الجاذبية.
    var ex = my * uz - mz * uy;
    var ey = mz * ux - mx * uz;
    var ez = mx * uy - my * ux;
    final normE = math.sqrt(ex * ex + ey * ey + ez * ez);
    if (normE == 0) return null;

    ex /= normE;
    ey /= normE;
    ez /= normE;

    // الشمال = تسارع الجاذبية × الشرق (المركبة z غير لازمة للاتجاه).
    final ny = uz * ex - ux * ez;

    final horizontal = math.sqrt(ex * ex + ey * ey);
    if (horizontal < 0.15) return null;

    final heading = math.atan2(ey, ny) * 180 / math.pi;
    if (heading.isNaN || heading.isInfinite) return null;

    return normalize(heading);
  }

  /// يبقي الزاوية بين 0 و360.
  static double normalize(double degrees) => (degrees % 360 + 360) % 360;

  /// تمهيد دائري بسيط يمنع اهتزاز المؤشر عند العتبة بين 359 و0.
  static double smooth(double previous, double next, {double factor = 0.2}) {
    final a = previous * math.pi / 180;
    final b = next * math.pi / 180;
    final x = (1 - factor) * math.cos(a) + factor * math.cos(b);
    final y = (1 - factor) * math.sin(a) + factor * math.sin(b);
    return normalize(math.atan2(y, x) * 180 / math.pi);
  }

  /// الفرق الأقصر بين زاويتين (سالب أو موجب)، مفيد لمعرفة التسامح.
  static double shortestDifference(double a, double b) {
    final diff = normalize(a - b);
    return diff > 180 ? diff - 360 : diff;
  }
}
