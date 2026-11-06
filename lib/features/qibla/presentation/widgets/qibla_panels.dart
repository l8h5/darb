import 'package:flutter/material.dart';

import '../../data/compass_math.dart';

/// بطاقة البداية: تشرح الخصوصية قبل طلب الموقع.
class QiblaIntroCard extends StatelessWidget {
  const QiblaIntroCard({
    super.key,
    required this.locating,
    required this.onLocate,
  });

  final bool locating;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.explore_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'أين القبلة؟',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'نحتاج موقعك مرة واحدة لحساب اتجاه القبلة من مكانك. '
              'لن نطلب الموقع إلا عند الضغط على الزر، ولن نتتبعه في الخلفية.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: locating ? null : onLocate,
              icon: locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(locating ? 'جارٍ تحديد الموقع…' : 'استخدم موقعي'),
            ),
          ],
        ),
      ),
    );
  }
}

/// يظهر فقط عندما يكون الجهاز موجّهاً نحو القبلة ضمن 5 درجات.
class QiblaAlignedBanner extends StatelessWidget {
  const QiblaAlignedBanner({
    super.key,
    required this.bearing,
    required this.heading,
  });

  final double bearing;
  final double? heading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = heading;
    final aligned = current != null &&
        CompassMath.shortestDifference(bearing, current).abs() <= 5;

    if (!aligned) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'أنت تواجه اتجاه القبلة الآن.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// رسالة حالة البوصلة: تعمل، أو غير متاحة على هذا الجهاز.
class CompassStateMessage extends StatelessWidget {
  const CompassStateMessage({
    super.key,
    required this.heading,
    required this.unavailable,
  });

  final double? heading;
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (heading != null) {
      return Text(
        'أمسك الجهاز أفقياً وحرّكه على شكل رقم 8 لتحسين دقة البوصلة.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            unavailable ? Icons.sensors_off : Icons.sensors,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              unavailable
                  ? 'بوصلة الجهاز غير متاحة. يظهر اتجاه القبلة بالدرجات، '
                      'ويمكنك توجيه الشمال يدوياً.'
                  : 'جارٍ تشغيل بوصلة الجهاز…',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// صف معلومة: التسمية يميناً والقيمة يساراً.
class QiblaInfoRow extends StatelessWidget {
  const QiblaInfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
            textDirection: TextDirection.ltr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
