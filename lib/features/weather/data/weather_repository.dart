import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
import '../domain/weather_snapshot.dart';
import 'open_meteo_parser.dart';

/// جلب الطقس من Open-Meteo (مجاني، بلا مفتاح) مع كاش آخر لقطة ناجحة.
///
/// لا نعرض قيماً من عندنا: إن فشل الاتصال ولا يوجد كاش، ترجع النتيجة
/// فشلاً واضحاً. وإن وُجد كاش نعرضه موسوماً بأنه قديم.
class WeatherRepository {
  WeatherRepository({http.Client? client}) : _client = client ?? http.Client();

  static const String _host = 'api.open-meteo.com';
  static const String _path = '/v1/forecast';
  static const String cacheKey = 'weather_cache_v1';

  final http.Client _client;

  Future<WeatherResult> fetch(LatLng point) async {
    final uri = Uri.https(_host, _path, {
      'latitude': point.latitude.toStringAsFixed(4),
      'longitude': point.longitude.toStringAsFixed(4),
      'current': [
        'temperature_2m',
        'apparent_temperature',
        'relative_humidity_2m',
        'precipitation',
        'weather_code',
        'wind_speed_10m',
        'wind_direction_10m',
      ].join(','),
      'hourly': 'precipitation_probability',
      'forecast_days': '1',
      'timezone': 'auto',
    });

    try {
      final response = await _client
          .get(
            uri,
            headers: const {
              'User-Agent': '${AppConfig.osmUserAgentPackage}/1.0',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw http.ClientException('HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('استجابة طقس غير صالحة');
      }

      final snapshot = OpenMeteoParser.parse(decoded);
      await _saveCache(snapshot);
      return WeatherResult.success(snapshot);
    } on TimeoutException {
      return _cachedOrFailure('انتهت مهلة الاتصال بالطقس.');
    } catch (_) {
      return _cachedOrFailure('تعذّر جلب الطقس. تحقّق من اتصال الإنترنت.');
    }
  }

  Future<WeatherResult> _cachedOrFailure(String message) async {
    final cached = await _loadCache();
    if (cached != null) {
      return WeatherResult.stale(cached, message);
    }
    return WeatherResult.failure(message);
  }

  Future<void> _saveCache(WeatherSnapshot snapshot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, jsonEncode(snapshot.toJson()));
    } catch (_) {
      // فشل الكاش لا يفشل العرض الحالي.
    }
  }

  Future<WeatherSnapshot?> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(cacheKey);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return WeatherSnapshot.tryFromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }
}
