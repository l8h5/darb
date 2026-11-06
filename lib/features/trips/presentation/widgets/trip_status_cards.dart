import 'package:flutter/material.dart';

/// بطاقة بدء رحلة جديدة، مع توضيح أن التتبع في المقدمة فقط.
class TripStartCard extends StatelessWidget {
  const TripStartCard({
    super.key,
    required this.busy,
    required this.onStart,
  });

  final bool busy;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.route_outlined,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'سجّل مسار رحلتك',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'تُسجَّل المسافة والمدة ومتوسط السرعة أثناء فتح التطبيق فقط. '
              'لا يوجد تتبع في الخلفية، ويُطلب إذن الموقع عند البدء.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: busy ? null : onStart,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(busy ? 'جارٍ البدء…' : 'بدء رحلة جديدة'),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة خطأ قابلة للإغلاق (GPS أو حفظ النقاط).
class TripErrorCard extends StatelessWidget {
  const TripErrorCard({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            IconButton(
              tooltip: 'إغلاق',
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
