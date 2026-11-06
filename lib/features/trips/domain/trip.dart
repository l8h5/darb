import 'package:latlong2/latlong.dart';

/// رحلة مسجّلة محلياً.
///
/// لا يوجد رفع للسيرفر ولا تتبع في الخلفية؛ كل شيء يُحفظ في SQLite على الجهاز.
class Trip {
  const Trip({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.distanceMeters,
    required this.pointCount,
  });

  final String id;
  final DateTime startedAt;

  /// `null` يعني رحلة مفتوحة (لم تُنهَ بعد).
  final DateTime? endedAt;

  final double distanceMeters;
  final int pointCount;

  bool get isActive => endedAt == null;

  Duration get duration {
    final end = endedAt;
    if (end == null) return DateTime.now().difference(startedAt);
    return end.difference(startedAt);
  }

  /// معرّف محلي بسيط؛ الوقت وحده لا يكفي إذا بدأت رحلتان في نفس اللحظة.
  static String createId([DateTime? now]) {
    final stamp = (now ?? DateTime.now()).microsecondsSinceEpoch;
    return 'trip_$stamp';
  }

  Trip copyWith({
    DateTime? endedAt,
    double? distanceMeters,
    int? pointCount,
  }) {
    return Trip(
      id: id,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      pointCount: pointCount ?? this.pointCount,
    );
  }
}

/// نقطة واحدة في مسار الرحلة.
class TripPoint {
  const TripPoint({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.accuracyMeters,
    this.speedMps,
    this.altitudeMeters,
  });

  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  final double? accuracyMeters;
  final double? speedMps;
  final double? altitudeMeters;

  LatLng get point => LatLng(latitude, longitude);
}
