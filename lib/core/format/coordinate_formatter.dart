import 'package:latlong2/latlong.dart';

/// كتابة الإحداثيات بالطريقة التي اختارها المستخدم.
///
/// لا يعتمد على ميزة معيّنة، بل على خيار منطقي بسيط، حتى يبقى `core`
/// مستقلاً عن طبقات الميزات.
class CoordinateFormatter {
  const CoordinateFormatter._();

  static String format(LatLng point, {required bool dms}) {
    if (!dms) {
      return '${point.latitude.toStringAsFixed(5)}, '
          '${point.longitude.toStringAsFixed(5)}';
    }
    return '${_dms(point.latitude, 'N', 'S')} '
        '${_dms(point.longitude, 'E', 'W')}';
  }

  /// مثال: 27°31'12.0"N
  static String _dms(double value, String positive, String negative) {
    final hemisphere = value >= 0 ? positive : negative;
    final absolute = value.abs();
    final degrees = absolute.floor();
    final minutesTotal = (absolute - degrees) * 60;
    final minutes = minutesTotal.floor();
    final seconds = (minutesTotal - minutes) * 60;

    return "$degrees°${minutes.toString().padLeft(2, '0')}'"
        '${seconds.toStringAsFixed(1).padLeft(4, '0')}"$hemisphere';
  }
}
