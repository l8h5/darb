import 'package:flutter/material.dart';

import '../../../../core/format/distance_formatter.dart';
import '../../../settings/domain/user_preferences.dart';
import '../../data/trip_recorder.dart';
import '../../domain/trip_stats.dart';

/// لوحة الرحلة الجارية: المدة، المسافة، متوسط السرعة، وأزرار التحكم.
class TripActivePanel extends StatelessWidget {
  const TripActivePanel({
    super.key,
    required this.recorder,
    required this.distanceUnit,
    required this.onPause,
    required this.onResume,
    required this.onFinish,
  });

  final TripRecorder recorder;
  final DistanceUnit distanceUnit;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recording = recorder.isRecording;

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: recording
                        ? theme.colorScheme.error
                        : theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  recording ? 'جارٍ تسجيل الرحلة' : 'التسجيل متوقف مؤقتاً',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (recorder.recovered) ...[
              const SizedBox(height: 8),
              Text(
                'استُعيدت رحلة غير مكتملة من تشغيل سابق. '
                'راجع المسافة ثم اضغط «استكمال» للمتابعة.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'المدة',
                    value: TripStats.formatClock(recorder.elapsed),
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'المسافة',
                    value: DistanceFormatter.format(
                      recorder.distanceMeters,
                      miles: distanceUnit == DistanceUnit.miles,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'متوسط السرعة',
                    value: '${recorder.averageSpeedKmh.round()} كم/س',
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'نقاط المسار',
                    value: '${recorder.pointCount}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: recording
                      ? OutlinedButton.icon(
                          onPressed: recorder.busy ? null : onPause,
                          icon: const Icon(Icons.pause),
                          label: const Text('إيقاف مؤقت'),
                        )
                      : FilledButton.icon(
                          onPressed: recorder.busy ? null : onResume,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('استكمال'),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: recorder.busy ? null : onFinish,
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('إنهاء الرحلة'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
