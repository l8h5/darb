import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/app_config.dart';
import '../../../spots/domain/saved_place.dart';
import '../../../spots/presentation/saved_place_marker.dart';
import '../../data/map_tile_provider.dart';
import '../../domain/map_layer.dart';
import 'my_location_dot.dart';

/// طبقة الخريطة نفسها، منفصلة عن الشريط العلوي والأزرار.
///
/// تستقبل الحالة والأحداث فقط؛ لا تعرف كيف تُحفظ الأماكن ولا كيف تُقرأ
/// التفضيلات، مما يجعل شاشة الخريطة أقصر وأسهل في الصيانة.
class DarbMapView extends StatelessWidget {
  const DarbMapView({
    super.key,
    required this.mapController,
    required this.tiles,
    required this.layer,
    required this.myPosition,
    required this.savedPlaces,
    required this.onCenterChanged,
    required this.onLongPress,
    required this.onPlaceTap,
  });

  final MapController mapController;
  final MapTileProvider tiles;
  final MapLayer layer;
  final LatLng? myPosition;
  final List<SavedPlace> savedPlaces;
  final ValueChanged<LatLng> onCenterChanged;
  final ValueChanged<LatLng> onLongPress;
  final ValueChanged<SavedPlace> onPlaceTap;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: AppConfig.hail,
        initialZoom: AppConfig.hailZoom,
        minZoom: AppConfig.minZoom,
        maxZoom: AppConfig.maxZoom,
        backgroundColor: const Color(0xFFEDE6D6),
        // تعطيل التدوير: يسبب ارتباكاً للمستخدم، ويجب أن تبقى الخريطة
        // شمالية دائماً حتى نضيف البوصلة/القبلة لاحقاً.
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onPositionChanged: (camera, hasGesture) {
          onCenterChanged(camera.center);
        },
        // الضغط المطوّل يحفظ مكاناً — لا يحتاج إنترنت ولا إذن موقع.
        onLongPress: (tapPosition, point) => onLongPress(point),
      ),
      children: [
        TileLayer(
          // مفتاح مختلف لكل طبقة يمنع ظهور بلاطات الطبقة السابقة أثناء
          // التحميل.
          key: ValueKey(layer),
          urlTemplate: layer.urlTemplate,
          // إلزامي بحسب سياسة OpenStreetMap.
          userAgentPackageName: AppConfig.osmUserAgentPackage,
          tileProvider: tiles.provider,
          maxNativeZoom: layer.maxNativeZoom,
          maxZoom: AppConfig.maxZoom,
        ),
        if (myPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: myPosition!,
                width: 26,
                height: 26,
                child: const MyLocationDot(),
              ),
            ],
          ),
        if (savedPlaces.isNotEmpty)
          MarkerLayer(
            markers: [
              for (final place in savedPlaces)
                Marker(
                  point: place.point,
                  width: 34,
                  height: 34,
                  child: GestureDetector(
                    onTap: () => onPlaceTap(place),
                    child: const SavedPlaceMarker(),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
