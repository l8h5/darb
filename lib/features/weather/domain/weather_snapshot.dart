/// حالة الطقس مشتقة من رموز WMO التي يعيدها Open-Meteo.
enum WeatherCondition {
  clear('صحو'),
  partlyCloudy('غائم جزئياً'),
  cloudy('غائم'),
  fog('ضباب'),
  drizzle('رذاذ'),
  rain('مطر'),
  heavyRain('مطر غزير'),
  snow('ثلوج'),
  showers('زخات مطر'),
  thunderstorm('عواصف رعدية'),
  unknown('غير معروف');

  const WeatherCondition(this.label);

  final String label;

  static WeatherCondition fromCode(int code) {
    if (code == 0) return WeatherCondition.clear;
    if (code <= 2) return WeatherCondition.partlyCloudy;
    if (code == 3) return WeatherCondition.cloudy;
    if (code == 45 || code == 48) return WeatherCondition.fog;
    if (code >= 51 && code <= 57) return WeatherCondition.drizzle;
    if (code >= 61 && code <= 65) return WeatherCondition.rain;
    if (code == 66 || code == 67) return WeatherCondition.heavyRain;
    if (code >= 71 && code <= 77) return WeatherCondition.snow;
    if (code >= 80 && code <= 82) return WeatherCondition.showers;
    if (code == 85 || code == 86) return WeatherCondition.snow;
    if (code >= 95) return WeatherCondition.thunderstorm;
    return WeatherCondition.unknown;
  }
}

/// لقطة طقس واحدة من Open-Meteo، مع وقت الجلب لحساب العمر.
class WeatherSnapshot {
  const WeatherSnapshot({
    required this.latitude,
    required this.longitude,
    required this.observedAt,
    required this.fetchedAt,
    required this.temperatureC,
    required this.apparentC,
    required this.humidity,
    required this.windSpeedKmh,
    required this.windDirectionDeg,
    required this.precipitationMm,
    required this.weatherCode,
    this.precipitationProbability,
  });

  final double latitude;
  final double longitude;
  final DateTime observedAt;
  final DateTime fetchedAt;
  final double temperatureC;
  final double apparentC;
  final double humidity;
  final double windSpeedKmh;
  final double windDirectionDeg;
  final double precipitationMm;
  final int? precipitationProbability;
  final int weatherCode;

  WeatherCondition get condition => WeatherCondition.fromCode(weatherCode);

  /// اسم الاتجاه بالعربية (ثمانية اتجاهات).
  String get windDirectionLabel {
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
    final index = (((windDirectionDeg % 360) + 22.5) ~/ 45) % 8;
    return labels[index];
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'observedAt': observedAt.toIso8601String(),
        'fetchedAt': fetchedAt.toIso8601String(),
        'temperatureC': temperatureC,
        'apparentC': apparentC,
        'humidity': humidity,
        'windSpeedKmh': windSpeedKmh,
        'windDirectionDeg': windDirectionDeg,
        'precipitationMm': precipitationMm,
        'weatherCode': weatherCode,
        'precipitationProbability': precipitationProbability,
      };

  /// قراءة دفاعية: أي نقص يعيد `null` بدل إسقاط الشاشة.
  static WeatherSnapshot? tryFromJson(Map<String, dynamic> json) {
    final observed = json['observedAt'];
    final fetched = json['fetchedAt'];
    final temperature = json['temperatureC'];
    final apparent = json['apparentC'];
    final humidity = json['humidity'];
    final windSpeed = json['windSpeedKmh'];
    final windDirection = json['windDirectionDeg'];
    final precipitation = json['precipitationMm'];
    final code = json['weatherCode'];
    final lat = json['latitude'];
    final lng = json['longitude'];

    if (observed is! String ||
        fetched is! String ||
        temperature is! num ||
        apparent is! num ||
        humidity is! num ||
        windSpeed is! num ||
        windDirection is! num ||
        precipitation is! num ||
        code is! num ||
        lat is! num ||
        lng is! num) {
      return null;
    }

    final observedAt = DateTime.tryParse(observed);
    final fetchedAt = DateTime.tryParse(fetched);
    if (observedAt == null || fetchedAt == null) return null;

    final probability = json['precipitationProbability'];

    return WeatherSnapshot(
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      observedAt: observedAt,
      fetchedAt: fetchedAt,
      temperatureC: temperature.toDouble(),
      apparentC: apparent.toDouble(),
      humidity: humidity.toDouble(),
      windSpeedKmh: windSpeed.toDouble(),
      windDirectionDeg: windDirection.toDouble(),
      precipitationMm: precipitation.toDouble(),
      weatherCode: code.toInt(),
      precipitationProbability: probability is num ? probability.toInt() : null,
    );
  }
}

/// نتيجة الجلب: حديثة، أو قديمة من الكاش، أو فشل بلا بيانات.
class WeatherResult {
  const WeatherResult._({
    this.snapshot,
    this.isStale = false,
    this.message,
  });

  factory WeatherResult.success(WeatherSnapshot snapshot) =>
      WeatherResult._(snapshot: snapshot);

  factory WeatherResult.stale(WeatherSnapshot snapshot, String message) =>
      WeatherResult._(snapshot: snapshot, isStale: true, message: message);

  factory WeatherResult.failure(String message) =>
      WeatherResult._(message: message);

  final WeatherSnapshot? snapshot;
  final bool isStale;
  final String? message;

  bool get hasData => snapshot != null;
}
