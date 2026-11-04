import 'package:latlong2/latlong.dart';

/// إعدادات ثابتة تخصّ الخريطة والنطاق الجغرافي.
///
/// كل رقم أو رابط يخصّ الخريطة يوضع هنا فقط، حتى لا يتكرر في أكثر من ملف،
/// ويسهل تغييره لاحقاً دون البحث في الواجهة.
class AppConfig {
  const AppConfig._();

  static const String appName = 'درب حائل';

  // ---------------------------------------------------------------------------
  // الخريطة
  // ---------------------------------------------------------------------------

  /// معرّف التطبيق يُرسل في ترويسة User-Agent.
  ///
  /// سياسة OpenStreetMap تُلزم كل تطبيق بمعرّف واضح، وإلا يُحجب.
  /// يجب أن يبقى ثابتاً في كل الإصدارات.
  static const String osmUserAgentPackage = 'sa.darbhail.darb_hail';

  /// مصدر بلاطات OpenStreetMap القياسية.
  ///
  /// مسموح للعرض التفاعلي فقط: لا تنزيل جماعي، ولا جلب مسبق، ولا استخدام دون إنترنت.
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// نص الإسناد الذي يجب أن يبقى ظاهراً على الخريطة دائماً.
  static const String osmAttribution = '© مساهمو OpenStreetMap';

  /// أعلى مستوى تكبير تتوفّر فيه البلاطات فعلياً في المصدر.
  static const int osmMaxNativeZoom = 19;

  // ---------------------------------------------------------------------------
  // النطاق الجغرافي
  // ---------------------------------------------------------------------------

  /// مركز مدينة حائل — نقطة البداية.
  static const LatLng hail = LatLng(27.52, 41.72);

  /// مستوى التكبير الابتدائي (يُظهر حائل وما حولها).
  static const double hailZoom = 11;

  /// زوايا المملكة العربية السعودية (جنوبي غربي، شمالي شرقي).
  static const LatLng saudiSouthWest = LatLng(16.0, 34.4);
  static const LatLng saudiNorthEast = LatLng(32.3, 55.8);

  // ---------------------------------------------------------------------------
  // حدود التكبير
  // ---------------------------------------------------------------------------

  static const double minZoom = 5;
  static const double maxZoom = 18;
  static const double myLocationZoom = 14;

  /// مستوى التقريب عند الانتقال إلى مكان محفوظ.
  static const double savedPlaceZoom = 15;
}
