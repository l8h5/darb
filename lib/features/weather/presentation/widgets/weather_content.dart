import 'package:flutter/material.dart';

import '../../domain/weather_snapshot.dart';

/// بطاقة الطقس الحالي والإحصاءات الأربع.
class WeatherContent extends StatelessWidget {
  const WeatherContent({
    super.key,
    required this.snapshot,
    required this.placeLabel,
    required this.loading,
  });

  final WeatherSnapshot snapshot;
  final String placeLabel;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  weatherIcon(snapshot.condition),
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${snapshot.temperatureC.round()}°',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        snapshot.condition.label,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$placeLabel • آخر تحديث '
                        '${timeLabel(snapshot.fetchedAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatCard(
                  width: width,
                  icon: Icons.thermostat,
                  label: 'الإحساس',
                  value: '${snapshot.apparentC.round()}°',
                ),
                _StatCard(
                  width: width,
                  icon: Icons.water_drop_outlined,
                  label: 'الرطوبة',
                  value: '${snapshot.humidity.round()}%',
                ),
                _StatCard(
                  width: width,
                  icon: Icons.air,
                  label: 'الرياح',
                  value: '${snapshot.windSpeedKmh.round()} كم/س '
                      '(${snapshot.windDirectionLabel})',
                ),
                _StatCard(
                  width: width,
                  icon: Icons.umbrella_outlined,
                  label: 'احتمال المطر',
                  value: snapshot.precipitationProbability == null
                      ? 'غير متاح'
                      : '${snapshot.precipitationProbability}%',
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(label, style: theme.textTheme.labelMedium),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData weatherIcon(WeatherCondition condition) {
  return switch (condition) {
    WeatherCondition.clear => Icons.wb_sunny_outlined,
    WeatherCondition.partlyCloudy => Icons.wb_cloudy_outlined,
    WeatherCondition.cloudy => Icons.cloud_outlined,
    WeatherCondition.fog => Icons.foggy,
    WeatherCondition.drizzle => Icons.grain,
    WeatherCondition.rain => Icons.water_drop,
    WeatherCondition.heavyRain => Icons.thunderstorm_outlined,
    WeatherCondition.snow => Icons.ac_unit,
    WeatherCondition.showers => Icons.umbrella,
    WeatherCondition.thunderstorm => Icons.flash_on,
    WeatherCondition.unknown => Icons.help_outline,
  };
}

String timeLabel(DateTime time) {
  final local = time.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
