import 'package:flutter/widgets.dart';

import 'preferences_controller.dart';

/// يجعل [PreferencesController] متاحاً لكل الشاشات دون تمرير معاملات يدوياً.
///
/// `InheritedNotifier` يعيد بناء الواجهات التابعة تلقائياً عند تغيّر
/// التفضيلات، فينتقل التغيير إلى الخريطة فوراً دون إعادة تشغيل.
class PreferencesScope extends InheritedNotifier<PreferencesController> {
  const PreferencesScope({
    super.key,
    required PreferencesController controller,
    required super.child,
  }) : super(notifier: controller);

  static PreferencesController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<PreferencesScope>();
    assert(scope != null, 'PreferencesScope غير موجود فوق هذه الشاشة');
    return scope!.notifier!;
  }
}
