import 'package:flutter/material.dart';

import '../../../map/domain/map_layer.dart';
import '../../../settings/domain/user_preferences.dart';
import 'onboarding_widgets.dart';

/// الشاشة الأولى: تعريف سريع بهوية درب.
class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.terrain,
              size: 56,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'أهلاً بك في درب',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'دربك إلى البر يبدأ من هنا. خصص تجربتك واكتشف الأماكن '
            'والطرق البرية بثقة.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 32),
          const _InfoLine(
            icon: Icons.offline_bolt_outlined,
            text: 'يعمل دون حساب، وبياناتك تبقى على جهازك.',
          ),
          const SizedBox(height: 12),
          const _InfoLine(
            icon: Icons.map_outlined,
            text: 'خرائط مفتوحة المصدر، مع تخزين للمناطق التي زرتها.',
          ),
          const SizedBox(height: 12),
          const _InfoLine(
            icon: Icons.my_location,
            text: 'لا نطلب موقعك إلا عند الضغط على «موقعي».',
          ),
        ],
      ),
    );
  }
}

/// الشاشة الثانية: بسيط أم متقدم.
class UsageModeStep extends StatelessWidget {
  const UsageModeStep({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final UsageMode selected;
  final ValueChanged<UsageMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScroll(
      title: 'كيف تحب استخدام درب؟',
      subtitle: 'يمكنك التبديل بين النمطين في أي وقت من الإعدادات.',
      children: [
        OnboardingChoiceCard(
          icon: Icons.touch_app_outlined,
          title: 'الوضع البسيط',
          description: 'واجهة نظيفة وأدوات أساسية: موقعك، أماكنك '
              'المحفوظة، وطبقات الخريطة عند الحاجة.',
          selected: selected == UsageMode.simple,
          onTap: () => onChanged(UsageMode.simple),
        ),
        OnboardingChoiceCard(
          icon: Icons.explore_outlined,
          title: 'الوضع المتقدم',
          description: 'كل ما في البسيط، مع إحداثيات دقيقة وحالة '
              'GPS وأدوات إضافية أثناء الرحلة.',
          selected: selected == UsageMode.advanced,
          onTap: () => onChanged(UsageMode.advanced),
        ),
      ],
    );
  }
}

/// الشاشة الثالثة: الطبقة الافتراضية للخريطة.
class MapPreferencesStep extends StatelessWidget {
  const MapPreferencesStep({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final MapLayer selected;
  final ValueChanged<MapLayer> onChanged;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScroll(
      title: 'طبقة الخريطة',
      subtitle: 'اختر ما تفتح عليه الخريطة. كل الطبقات مجانية '
          'ولا تحتاج مفتاحاً.',
      children: [
        for (final layer in MapLayer.values)
          OnboardingChoiceCard(
            icon: layer.icon,
            title: layer.label,
            description: switch (layer) {
              MapLayer.streets => 'الطرق والأسماء، الأخف والأوضح للتنقل.',
              MapLayer.terrain => 'خطوط الارتفاع والتضاريس، مفيدة للجبال والأودية.',
              MapLayer.satellite => 'صور فضائية حديثة، مفيدة لتمييز الرمال والشعاب.',
            },
            selected: selected == layer,
            onTap: () => onChanged(layer),
          ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
