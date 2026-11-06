import 'package:flutter/material.dart';

import '../../settings/domain/user_preferences.dart';
import '../../settings/presentation/preferences_controller.dart';
import 'widgets/onboarding_steps.dart';
import 'widgets/onboarding_usage_steps.dart';

/// التهيئة الأولية: خمس خطوات قصيرة قبل أول دخول للخريطة.
///
/// لا تطلب أي صلاحية جهاز؛ الاختيارات تُحفظ محلياً فقط، ويمكن تخطيها
/// أو تعديلها لاحقاً من الإعدادات.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.controller});

  final PreferencesController controller;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _lastPage = 4;

  final PageController _pageController = PageController();

  late UserPreferences _draft = widget.controller.preferences;
  int _page = 0;
  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    setState(() => _page = page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);

    // الحفظ قد يفشل (تخزين ممتلئ مثلاً)؛ لا نمنع الدخول للتطبيق.
    await widget.controller.completeOnboarding(_draft);

    if (mounted) setState(() => _saving = false);
  }

  Future<void> _skip() async {
    if (_saving) return;
    setState(() => _saving = true);
    await widget.controller.skipOnboarding();
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعداد درب'),
        automaticallyImplyLeading: false,
        actions: [
          if (_page < _lastPage)
            TextButton(
              onPressed: _saving ? null : _skip,
              child: const Text('تخطي'),
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (_page + 1) / 5),
        ),
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            const WelcomeStep(),
            UsageModeStep(
              selected: _draft.usageMode,
              onChanged: (mode) => setState(
                () => _draft = _draft.copyWith(usageMode: mode),
              ),
            ),
            MapPreferencesStep(
              selected: _draft.defaultLayer,
              onChanged: (layer) => setState(
                () => _draft = _draft.copyWith(defaultLayer: layer),
              ),
            ),
            UsagePreferencesStep(
              coordinateFormat: _draft.coordinateFormat,
              distanceUnit: _draft.distanceUnit,
              onCoordinateFormatChanged: (format) => setState(
                () => _draft = _draft.copyWith(coordinateFormat: format),
              ),
              onDistanceUnitChanged: (unit) => setState(
                () => _draft = _draft.copyWith(distanceUnit: unit),
              ),
            ),
            SummaryStep(preferences: _draft),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            if (_page > 0)
              IconButton.filledTonal(
                tooltip: 'السابق',
                onPressed: _saving ? null : () => _goTo(_page - 1),
                icon: const Icon(Icons.arrow_forward),
              ),
            if (_page > 0) const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _saving
                    ? null
                    : _page == _lastPage
                        ? _finish
                        : () => _goTo(_page + 1),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  textStyle: theme.textTheme.titleMedium,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        switch (_page) {
                          0 => 'ابدأ',
                          _lastPage => 'ابدأ رحلتك مع درب',
                          _ => 'التالي',
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
