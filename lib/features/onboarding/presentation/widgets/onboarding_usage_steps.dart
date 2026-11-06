import 'package:flutter/material.dart';

import '../../../settings/domain/user_preferences.dart';
import 'onboarding_widgets.dart';

/// الشاشة الرابعة: الوحدات وطريقة عرض الإحداثيات.
class UsagePreferencesStep extends StatelessWidget {
  const UsagePreferencesStep({
    super.key,
    required this.coordinateFormat,
    required this.distanceUnit,
    required this.onCoordinateFormatChanged,
    required this.onDistanceUnitChanged,
  });

  final CoordinateFormat coordinateFormat;
  final DistanceUnit distanceUnit;
  final ValueChanged<CoordinateFormat> onCoordinateFormatChanged;
  final ValueChanged<DistanceUnit> onDistanceUnitChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OnboardingStepScroll(
      title: 'تفضيلات الاستخدام',
      subtitle: 'إعدادات صغيرة تجعل القراءة أسهل أثناء الرحلة.',
      children: [
        Text('طريقة عرض الإحداثيات', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        OnboardingSegmentedOptions<CoordinateFormat>(
          values: CoordinateFormat.values,
          selected: coordinateFormat,
          labelOf: (value) => value.label,
          onChanged: onCoordinateFormatChanged,
        ),
        const SizedBox(height: 24),
        Text('وحدة المسافة', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        OnboardingSegmentedOptions<DistanceUnit>(
          values: DistanceUnit.values,
          selected: distanceUnit,
          labelOf: (value) => value.label,
          onChanged: onDistanceUnitChanged,
        ),
        const SizedBox(height: 24),
        Text('اللغة', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        const OnboardingReadOnlyRow(
          icon: Icons.translate,
          text: 'العربية',
          note: 'اللغة الوحيدة المدعومة حالياً',
        ),
      ],
    );
  }
}

/// الشاشة الخامسة: ملخص ثم بدء الاستخدام.
class SummaryStep extends StatelessWidget {
  const SummaryStep({super.key, required this.preferences});

  final UserPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OnboardingStepScroll(
      title: 'كل شيء جاهز',
      subtitle: 'راجع اختياراتك، ويمكنك تغييرها لاحقاً من الإعدادات.',
      children: [
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                OnboardingSummaryRow(
                  label: 'نمط الاستخدام',
                  value: preferences.usageMode.label,
                ),
                OnboardingSummaryRow(
                  label: 'طبقة الخريطة',
                  value: preferences.defaultLayer.label,
                ),
                OnboardingSummaryRow(
                  label: 'وحدة المسافة',
                  value: preferences.distanceUnit.label,
                ),
                OnboardingSummaryRow(
                  label: 'الإحداثيات',
                  value: preferences.coordinateFormat.label,
                ),
                const OnboardingSummaryRow(
                  label: 'اللغة',
                  value: 'العربية',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'لا تُرسل بياناتك إلى أي خادم، ولا يبدأ تتبع الموقع في الخلفية.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
