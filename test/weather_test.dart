import 'dart:convert';

import 'package:darb_hail/features/weather/data/open_meteo_parser.dart';
import 'package:darb_hail/features/weather/data/weather_repository.dart';
import 'package:darb_hail/features/weather/domain/weather_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const hail = LatLng(27.52, 41.72);

  final payload = <String, dynamic>{
    'latitude': 27.52,
    'longitude': 41.72,
    'current': {
      'time': '2026-11-06T13:00',
      'temperature_2m': 28.4,
      'apparent_temperature': 27.1,
      'relative_humidity_2m': 22,
      'precipitation': 0.0,
      'weather_code': 1,
      'wind_speed_10m': 14.2,
      'wind_direction_10m': 315.0,
    },
    'hourly': {
      'time': ['2026-11-06T12:00', '2026-11-06T13:00'],
      'precipitation_probability': [3, 12],
    },
  };

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OpenMeteoParser', () {
    test('يقرأ الحقول الحالية واحتمال المطر للساعة', () {
      final snapshot = OpenMeteoParser.parse(
        payload,
        fetchedAt: DateTime(2026, 11, 6, 13, 5),
      );

      expect(snapshot.temperatureC, 28.4);
      expect(snapshot.apparentC, 27.1);
      expect(snapshot.humidity, 22);
      expect(snapshot.windSpeedKmh, 14.2);
      expect(snapshot.windDirectionLabel, 'شمال غرب');
      expect(snapshot.precipitationProbability, 12);
      expect(snapshot.condition, WeatherCondition.partlyCloudy);
      expect(snapshot.fetchedAt, DateTime(2026, 11, 6, 13, 5));
    });

    test('الحقول الناقصة ترمي خطأ تنسيق واضح', () {
      expect(
        () => OpenMeteoParser.parse(const {'current': {}}),
        throwsFormatException,
      );
    });

    test('رموز WMO تُحوَّل إلى حالات معروفة', () {
      expect(WeatherCondition.fromCode(0), WeatherCondition.clear);
      expect(WeatherCondition.fromCode(3), WeatherCondition.cloudy);
      expect(WeatherCondition.fromCode(65), WeatherCondition.rain);
      expect(WeatherCondition.fromCode(95), WeatherCondition.thunderstorm);
    });
  });

  group('WeatherSnapshot', () {
    test('JSON ثم استرجاع يحافظ على القيم', () {
      final snapshot = OpenMeteoParser.parse(payload);
      final restored = WeatherSnapshot.tryFromJson(snapshot.toJson());

      expect(restored, isNotNull);
      expect(restored!.temperatureC, snapshot.temperatureC);
      expect(restored.precipitationProbability, 12);
      expect(restored.windDirectionDeg, 315);
    });

    test('JSON تالف يعيد null بدل إسقاط التطبيق', () {
      expect(WeatherSnapshot.tryFromJson(const {'foo': 'bar'}), isNull);
    });
  });

  group('WeatherRepository', () {
    test('النجاح يعيد بيانات حديثة ويحفظ الكاش', () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'api.open-meteo.com');
        return http.Response.bytes(
          utf8.encode(jsonEncode(payload)),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final result = await WeatherRepository(client: client).fetch(hail);

      expect(result.hasData, isTrue);
      expect(result.isStale, isFalse);
      expect(result.snapshot!.temperatureC, 28.4);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(WeatherRepository.cacheKey), isNotNull);
    });

    test('فشل الشبكة مع كاش يعيد بيانات قديمة موسومة', () async {
      final cached = OpenMeteoParser.parse(payload);
      SharedPreferences.setMockInitialValues({
        WeatherRepository.cacheKey: jsonEncode(cached.toJson()),
      });

      final client = MockClient(
        (request) async => throw http.ClientException('offline'),
      );
      final result = await WeatherRepository(client: client).fetch(hail);

      expect(result.hasData, isTrue);
      expect(result.isStale, isTrue);
      expect(result.message, isNotNull);
    });

    test('فشل الشبكة بلا كاش يعيد فشلاً واضحاً', () async {
      final client = MockClient(
        (request) async => throw http.ClientException('offline'),
      );
      final result = await WeatherRepository(client: client).fetch(hail);

      expect(result.hasData, isFalse);
      expect(result.isStale, isFalse);
      expect(result.message, isNotNull);
    });
  });
}
