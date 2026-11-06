import 'package:flutter/material.dart';

/// طبقات الخريطة المتاحة.
///
/// كل الطبقات من مصادر مفتوحة ولا تحتاج مفتاح API ولا اشتراكاً:
///  * OSM: الخريطة العادية.
///  * OpenTopoMap: خطوط الارتفاع والتضاريس (CC-BY-SA).
///  * Sentinel-2 cloudless: صور أقمار صناعية (CC BY 4.0) عبر EOX.
///
/// سياسة OSM تمنع التنزيل الجماعي، لذلك لا يوجد زر «تنزيل المنطقة»؛
/// ما يزوره المستخدم فقط يُخزَّن مؤقتاً على الجهاز.
enum MapLayer {
  streets(
    label: 'عادية',
    icon: Icons.map_outlined,
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '© مساهمو OpenStreetMap',
    maxNativeZoom: 19,
  ),
  terrain(
    label: 'تضاريس',
    icon: Icons.terrain_outlined,
    urlTemplate: 'https://tile.opentopomap.org/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap contributors, SRTM | © OpenTopoMap (CC-BY-SA)',
    maxNativeZoom: 17,
  ),
  satellite(
    label: 'أقمار صناعية',
    icon: Icons.satellite_alt_outlined,
    urlTemplate:
        'https://tiles.maps.eox.at/wmts/1.0.0/s2cloudless-2020_3857/default/g/{z}/{y}/{x}.jpg',
    attribution: 'Sentinel-2 cloudless © EOX IT Services (CC BY 4.0)',
    maxNativeZoom: 16,
  );

  const MapLayer({
    required this.label,
    required this.icon,
    required this.urlTemplate,
    required this.attribution,
    required this.maxNativeZoom,
  });

  final String label;
  final IconData icon;
  final String urlTemplate;
  final String attribution;

  /// أعلى مستوى تكبير تتوفّر فيه البلاطات فعلياً في المصدر.
  final int maxNativeZoom;
}
