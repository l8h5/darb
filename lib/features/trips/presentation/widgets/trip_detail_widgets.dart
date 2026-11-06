import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/format/distance_formatter.dart';
import '../../../map/data/map_tile_provider.dart';
import '../../../map/domain/map_layer.dart';
import '../../../settings/domain/user_preferences.dart';
import '../../../settings/presentation/preferences_scope.dart';
import '../../domain/trip.dart';
import '../../domain/trip_stats.dart';

/// خريطة المسار مع علامتي البداية والنهاية والمساهمة.
class TripTrackMap extends StatelessWidget {
  const TripTrackMap({
    super.key,
    required this.points,
    required this.tiles,
  });

  final List<TripPoint> points;
  final MapTileProvider tiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coordinates = points.map((point) => point.point).toList();
    final bounds = LatLngBounds.fromPoints(coordinates);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 280,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(36),
                ),
                minZoom: AppConfig.minZoom,
                maxZoom: AppConfig.maxZoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: MapLayer.streets.urlTemplate,
                  userAgentPackageName: AppConfig.osmUserAgentPackage,
                  tileProvider: tiles.provider,
                  maxNativeZoom: MapLayer.streets.maxNativeZoom,
                  maxZoom: AppConfig.maxZoom,
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: coordinates,
                      strokeWidth: 5,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: coordinates.first,
                      radius: 7,
                      color: theme.colorScheme.tertiary,
                      borderColor: theme.colorScheme.surface,
                      borderStrokeWidth: 2,
                    ),
                    CircleMarker(
                      point: coordinates.last,
                      radius: 7,
                      color: theme.colorScheme.error,
                      borderColor: theme.colorScheme.surface,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  MapLayer.streets.attribution,
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة إحصاءات الرحلة المحفوظة.
class TripStatsCard extends StatelessWidget {
  const TripStatsCard({
    super.key,
    required this.trip,
    required this.points,
  });

  final Trip trip;
  final List<TripPoint> points;

  @override
  Widget build(BuildContext context) {
    final prefs = PreferencesScope.of(context).preferences;
    final altitudes = points
        .map((point) => point.altitudeMeters)
        .whereType<double>()
        .toList();

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          _Row(
            label: 'المسافة',
            value: DistanceFormatter.format(
              trip.distanceMeters,
              miles: prefs.distanceUnit == DistanceUnit.miles,
            ),
          ),
          const Divider(height: 1),
          _Row(label: 'المدة', value: TripStats.formatDuration(trip.duration)),
          const Divider(height: 1),
          _Row(
            label: 'متوسط السرعة',
            value: '${TripStats.averageSpeedKmh(
              distanceMeters: trip.distanceMeters,
              duration: trip.duration,
            ).round()} كم/س',
          ),
          const Divider(height: 1),
          _Row(label: 'نقاط المسار', value: '${trip.pointCount}'),
          if (altitudes.isNotEmpty) ...[
            const Divider(height: 1),
            _Row(
              label: 'أعلى ارتفاع مسجّل',
              value: '${altitudes.reduce((a, b) => a > b ? a : b).round()} م',
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// رسالة تظهر عندما لا توجد نقاط كافية لرسم مسار.
class TripNoTrackMessage extends StatelessWidget {
  const TripNoTrackMessage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.route_outlined, color: theme.colorScheme.outline),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'لا توجد نقاط كافية لرسم المسار في هذه الرحلة.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
