import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:http/io_client.dart';
import 'package:http/retry.dart';

/// مزوّد بلاطات OpenStreetMap بإعدادات اتصال مهذّبة.
///
/// لماذا لا نستخدم المزوّد الافتراضي؟
///  * عند التصغير إلى مستوى المملكة يُطلب عشرات البلاطات في لحظة واحدة.
///    الخادم يرى ذلك كضغط فيقطع بعض الاتصالات (`Connection reset by peer`)
///    فتظهر مربعات رمادية.
///  * الحد هنا 3 اتصالات متزامنة لكل خادم، مع إعادة محاولة تلقائية 3 مرات.
///
/// سياسة OSM تمنع التنزيل الجماعي؛ هذا الحد يحترمها أيضاً.
class OsmTileProvider {
  OsmTileProvider() {
    _httpClient = HttpClient()
      ..maxConnectionsPerHost = 3
      ..connectionTimeout = const Duration(seconds: 20)
      ..idleTimeout = const Duration(seconds: 20);

    provider = NetworkTileProvider(
      httpClient: RetryClient(IOClient(_httpClient), retries: 3),
      // فشل بلاطة واحدة لا يجب أن يُظهر رسالة خطأ للمستخدم؛
      // تُعرض شفافة ويُعاد طلبها عند أول تحريك.
      silenceExceptions: true,
    );
  }

  late final HttpClient _httpClient;
  late final NetworkTileProvider provider;

  void dispose() {
    provider.dispose();
    _httpClient.close(force: true);
  }
}
