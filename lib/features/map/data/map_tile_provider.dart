import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:http/io_client.dart';
import 'package:http/retry.dart';

import '../../../core/config/app_config.dart';

/// مزوّد بلاطات مشترك لكل طبقات الخريطة، بإعدادات اتصال وتخزين مؤقت.
///
/// لماذا لا نستخدم المزوّد الافتراضي كما هو؟
///  * عند التصغير إلى مستوى المملكة يُطلب عشرات البلاطات في لحظة واحدة.
///    الخادم يرى ذلك كضغط فيقطع بعض الاتصالات (`Connection reset by peer`)
///    فتظهر مربعات رمادية. الحد هنا 3 اتصالات متزامنة لكل خادم، مع إعادة
///    محاولة تلقائية 3 مرات.
///  * التخزين المؤقت: flutter_map يحفظ البلاطات التي زارها المستخدم على
///    القرص ويحترم ترويسات `Cache-Control`، فتعمل الخريطة بلا إنترنت في
///    المناطق المزارعة سابقاً. لا يوجد تنزيل جماعي، احتراماً لسياسة OSM.
class MapTileProvider {
  MapTileProvider() {
    _httpClient = HttpClient()
      ..maxConnectionsPerHost = 3
      ..connectionTimeout = const Duration(seconds: 20)
      ..idleTimeout = const Duration(seconds: 20);

    provider = NetworkTileProvider(
      httpClient: RetryClient(IOClient(_httpClient), retries: 3),
      // فشل بلاطة واحدة لا يجب أن يُظهر رسالة خطأ للمستخدم؛
      // تُعرض شفافة ويُعاد طلبها عند أول تحريك.
      silenceExceptions: true,
      cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
        // لا نسمح للصور أن تتجاوز 150 م.ب. على جهاز المستخدم.
        maxCacheSize: AppConfig.tileCacheBytes,
      ),
    );
  }

  late final HttpClient _httpClient;
  late final NetworkTileProvider provider;

  void dispose() {
    provider.dispose();
    _httpClient.close(force: true);
  }
}
