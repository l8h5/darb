import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/format/coordinate_formatter.dart';
import '../../../settings/domain/user_preferences.dart';

/// الشريط العلوي: إحداثيات مركز الخريطة، اختصارات التنقل، والإعدادات.
///
/// لا يعرف شيئاً عن الخريطة أو التخزين؛ يستقبل القيم والأحداث فقط.
/// في الوضع البسيط تظهر المعلومات الأساسية فقط، وفي المتقدم تُضاف حالة GPS.
class MapHeader extends StatelessWidget {
  const MapHeader({
    super.key,
    required this.center,
    required this.savedCount,
    required this.coordinateFormat,
    required this.advanced,
    required this.accuracyMeters,
    required this.onFitSaudiArabia,
    required this.onGoToHail,
    required this.onOpenSavedPlaces,
    required this.onOpenSettings,
  });

  final ValueListenable<LatLng> center;
  final int savedCount;
  final CoordinateFormat coordinateFormat;
  final bool advanced;
  final double? accuracyMeters;
  final VoidCallback onFitSaudiArabia;
  final VoidCallback onGoToHail;
  final VoidCallback onOpenSavedPlaces;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مركز الخريطة', style: theme.textTheme.labelSmall),
                  const SizedBox(height: 2),
                  ValueListenableBuilder<LatLng>(
                    valueListenable: center,
                    builder: (context, value, _) {
                      return Text(
                        CoordinateFormatter.format(
                          value,
                          dms: coordinateFormat == CoordinateFormat.dms,
                        ),
                        // الأرقام تُعرض دائماً بالإنجليزية لتسهيل النسخ والقراءة.
                        textDirection: TextDirection.ltr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      );
                    },
                  ),
                  if (advanced) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          accuracyMeters == null
                              ? Icons.gps_not_fixed
                              : Icons.gps_fixed,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          accuracyMeters == null
                              ? 'GPS: لم يُحدَّد الموقع بعد'
                              : 'دقة الموقع ±${accuracyMeters!.round()} م',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: onFitSaudiArabia,
                        icon: const Icon(Icons.public, size: 18),
                        label: const Text('المملكة'),
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: onGoToHail,
                        icon: const Icon(Icons.place_outlined, size: 18),
                        label: const Text('حائل'),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'الأماكن المحفوظة',
                        onPressed: onOpenSavedPlaces,
                        icon: Badge(
                          isLabelVisible: savedCount > 0,
                          label: Text('$savedCount'),
                          child: const Icon(Icons.bookmarks_outlined),
                        ),
                      ),
                      IconButton(
                        tooltip: 'الإعدادات',
                        onPressed: onOpenSettings,
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                  Text(
                    'اضغط مطوّلاً على الخريطة لحفظ مكان',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
