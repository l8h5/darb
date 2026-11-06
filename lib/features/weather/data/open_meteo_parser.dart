import '../domain/weather_snapshot.dart';

/// تحويل استجابة Open-Meteo الخام إلى [WeatherSnapshot].
///
/// فصل التحويل عن الشبكة يسمح باختباره بلا إنترنت وبلا انتظار.
class OpenMeteoParser {
  const OpenMeteoParser._();

  static WeatherSnapshot parse(
    Map<String, dynamic> json, {
    DateTime? fetchedAt,
  }) {
    final current = json['current'];
    if (current is! Map) {
      throw const FormatException('لا توجد بيانات حالية');
    }

    final temperature = current['temperature_2m'];
    final apparent = current['apparent_temperature'];
    final humidity = current['relative_humidity_2m'];
    final windSpeed = current['wind_speed_10m'];
    final windDirection = current['wind_direction_10m'];
    final precipitation = current['precipitation'];
    final code = current['weather_code'];
    final time = current['time'];
    final latitude = json['latitude'];
    final longitude = json['longitude'];

    if (temperature is! num ||
        apparent is! num ||
        humidity is! num ||
        windSpeed is! num ||
        windDirection is! num ||
        precipitation is! num ||
        code is! num ||
        time is! String ||
        latitude is! num ||
        longitude is! num) {
      throw const FormatException('حقول طقس ناقصة');
    }

    final observedAt = DateTime.tryParse(time);
    if (observedAt == null) {
      throw const FormatException('وقت طقس غير صالح');
    }

    return WeatherSnapshot(
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      observedAt: observedAt,
      fetchedAt: fetchedAt ?? DateTime.now(),
      temperatureC: temperature.toDouble(),
      apparentC: apparent.toDouble(),
      humidity: humidity.toDouble(),
      windSpeedKmh: windSpeed.toDouble(),
      windDirectionDeg: windDirection.toDouble(),
      precipitationMm: precipitation.toDouble(),
      weatherCode: code.toInt(),
      precipitationProbability: _probabilityForHour(json, observedAt),
    );
  }

  /// احتمالية الهطول للساعة الحالية من مصفوفة `hourly`.
  static int? _probabilityForHour(
    Map<String, dynamic> json,
    DateTime observedAt,
  ) {
    final hourly = json['hourly'];
    if (hourly is! Map) return null;

    final times = hourly['time'];
    final values = hourly['precipitation_probability'];
    if (times is! List || values is! List) return null;

    final target = observedAt.toIso8601String().substring(0, 13);
    for (var index = 0; index < times.length; index++) {
      final time = times[index];
      if (time is String && time.startsWith(target) && index < values.length) {
        final value = values[index];
        return value is num ? value.toInt() : null;
      }
    }
    return null;
  }
}
