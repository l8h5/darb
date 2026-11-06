import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/location/location_service.dart';
import '../../map/domain/map_layer.dart';
import '../../map/presentation/widgets/map_layer_sheet.dart';
import '../domain/user_preferences.dart';
import 'preferences_scope.dart';

/// الإعدادات المركزية: كل تغيير يُحفظ فوراً ويُطبّق على الخريطة مباشرة.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _save(
    BuildContext context,
    UserPreferences next,
  ) async {
    final saved = await PreferencesScope.of(context).save(next);
    if (!saved && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('تعذّر حفظ الإعدادات على الجهاز.'),
          ),
        );
    }
  }

  Future<void> _pickLayer(
    BuildContext context,
    UserPreferences prefs,
  ) async {
    final selected = await showModalBottomSheet<MapLayer>(
      context: context,
      showDragHandle: true,
      builder: (_) => MapLayerSheet(selected: prefs.defaultLayer),
    );
    if (selected == null || !context.mounted) return;
    await _save(context, prefs.copyWith(defaultLayer: selected));
  }

  Future<void> _restartOnboarding(
    BuildContext context,
    UserPreferences prefs,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إعادة التهيئة؟'),
        content: const Text(
          'ستظهر شاشات التعريف والاختيارات من جديد. '
          'أماكنك المحفوظة وإعداداتك الحالية لا تُحذف.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('إعادة'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await PreferencesScope.of(context).restartOnboarding();
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = PreferencesScope.of(context);
    final prefs = controller.preferences;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionTitle('نمط الاستخدام'),
          SegmentedButton<UsageMode>(
            showSelectedIcon: false,
            segments: [
              for (final mode in UsageMode.values)
                ButtonSegment(value: mode, label: Text(mode.label)),
            ],
            selected: {prefs.usageMode},
            onSelectionChanged: (selection) {
              _save(
                context,
                prefs.copyWith(usageMode: selection.first),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              prefs.usageMode == UsageMode.advanced
                  ? 'تظهر الإحداثيات وحالة GPS وأزرار الطبقات.'
                  : 'واجهة مبسّطة: الخريطة والموقع والأماكن المحفوظة.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _SectionTitle('الخريطة'),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            child: ListTile(
              leading: Icon(prefs.defaultLayer.icon),
              title: const Text('الطبقة الافتراضية'),
              subtitle: Text(prefs.defaultLayer.label),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => _pickLayer(context, prefs),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'تُخزَّن البلاطات التي زرتها فقط، بحد أقصى 150 م.ب.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle('الوحدات والإحداثيات'),
          Text('وحدة المسافة', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<DistanceUnit>(
            showSelectedIcon: false,
            segments: [
              for (final unit in DistanceUnit.values)
                ButtonSegment(value: unit, label: Text(unit.label)),
            ],
            selected: {prefs.distanceUnit},
            onSelectionChanged: (selection) {
              _save(
                context,
                prefs.copyWith(distanceUnit: selection.first),
              );
            },
          ),
          const SizedBox(height: 16),
          Text('طريقة عرض الإحداثيات', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<CoordinateFormat>(
            showSelectedIcon: false,
            segments: [
              for (final format in CoordinateFormat.values)
                ButtonSegment(value: format, label: Text(format.label)),
            ],
            selected: {prefs.coordinateFormat},
            onSelectionChanged: (selection) {
              _save(
                context,
                prefs.copyWith(coordinateFormat: selection.first),
              );
            },
          ),
          const SizedBox(height: 16),
          _SectionTitle('الموقع والصلاحيات'),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            child: ListTile(
              leading: const Icon(Icons.my_location),
              title: const Text('إذن الموقع'),
              subtitle: const Text(
                'يُطلب عند الضغط على «موقعي» فقط. '
                'لا يوجد تتبع في الخلفية.',
              ),
              trailing: TextButton(
                onPressed: () => LocationService().openAppSettings(),
                child: const Text('الإعدادات'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle('التهيئة'),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            child: ListTile(
              leading: const Icon(Icons.restart_alt),
              title: const Text('إعادة تشغيل التهيئة'),
              subtitle: const Text('عرض شاشات البداية من جديد'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => _restartOnboarding(context, prefs),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle('حول التطبيق'),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            child: const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text(AppConfig.appName),
              subtitle: Text(
                'الإصدار ${AppConfig.appVersion}\n'
                'خرائط مفتوحة المصدر: OpenStreetMap وOpenTopoMap وEOX',
              ),
              isThreeLine: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
