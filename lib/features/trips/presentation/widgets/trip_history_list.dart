import 'package:flutter/material.dart';

import '../../../../core/format/distance_formatter.dart';
import '../../../settings/domain/user_preferences.dart';
import '../../domain/trip.dart';
import '../../domain/trip_stats.dart';

/// قائمة الرحلات المنتهية مع المسافة والمدة.
class TripHistoryList extends StatelessWidget {
  const TripHistoryList({
    super.key,
    required this.trips,
    required this.distanceUnit,
    required this.onOpen,
    required this.onDelete,
  });

  final List<Trip> trips;
  final DistanceUnit distanceUnit;
  final ValueChanged<Trip> onOpen;
  final ValueChanged<Trip> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (trips.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(
              Icons.route_outlined,
              size: 40,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              'لا توجد رحلات محفوظة بعد.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ابدأ رحلة وسيُسجَّل مسارك على جهازك.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          for (var index = 0; index < trips.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            _TripTile(
              trip: trips[index],
              distanceUnit: distanceUnit,
              onOpen: () => onOpen(trips[index]),
              onDelete: () => onDelete(trips[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _TripTile extends StatelessWidget {
  const _TripTile({
    required this.trip,
    required this.distanceUnit,
    required this.onOpen,
    required this.onDelete,
  });

  final Trip trip;
  final DistanceUnit distanceUnit;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = TripStats.formatDuration(trip.duration);

    return ListTile(
      leading: const Icon(Icons.terrain),
      title: Text(formatTripDate(trip.startedAt)),
      subtitle: Text(
        '${DistanceFormatter.format(
          trip.distanceMeters,
          miles: distanceUnit == DistanceUnit.miles,
        )} • $duration • ${trip.pointCount} نقطة',
      ),
      trailing: IconButton(
        tooltip: 'حذف الرحلة',
        onPressed: onDelete,
        icon: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.error,
        ),
      ),
      onTap: onOpen,
    );
  }
}

/// تاريخ عربي مختصر بلا مكتبة إضافية.
String formatTripDate(DateTime date) {
  const months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  final local = date.toLocal();
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}
