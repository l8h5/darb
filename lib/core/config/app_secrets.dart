/// مفاتيح الخدمات الخارجية، تُحقن وقت البناء ولا تُكتب في الكود.
///
/// لا تُضمَّن القيم داخل التطبيق كملف أصول يمكن فكّه؛ بل تُمرَّر إلى المترجم:
///
/// ```powershell
/// flutter run --dart-define-from-file=.env
/// flutter build apk --dart-define-from-file=.env
/// ```
///
/// ملف `.env` مُستثنى من Git، ويُحفظ نموذجه في `.env.example`.
///
/// ملاحظة: الخدمات الحالية (OpenStreetMap وOpenTopoMap وEOX وOpen-Meteo)
/// لا تحتاج أي مفتاح، لذلك تكون القيم فارغة في الإصدار الحالي.
class AppSecrets {
  const AppSecrets._();

  /// مفتاح خدمة الطقس، إن انتقلنا لاحقاً إلى مزوّد يحتاجه.
  static const String weatherApiKey =
      String.fromEnvironment('WEATHER_API_KEY');

  /// مفتاح مزوّد بلاطات تجاري، إن استُخدم مستقبلاً.
  static const String tileProviderKey =
      String.fromEnvironment('TILE_PROVIDER_KEY');

  static bool get hasWeatherApiKey => weatherApiKey.isNotEmpty;
  static bool get hasTileProviderKey => tileProviderKey.isNotEmpty;
}
