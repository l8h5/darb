import 'package:flutter/material.dart';

import '../../domain/map_layer.dart';

/// لوحة اختيار طبقة الخريطة.
class MapLayerSheet extends StatelessWidget {
  const MapLayerSheet({super.key, required this.selected});

  final MapLayer selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('طبقة الخريطة', style: theme.textTheme.titleMedium),
          ),
          for (final layer in MapLayer.values)
            ListTile(
              leading: Icon(layer.icon),
              title: Text(layer.label),
              subtitle: layer == MapLayer.streets
                  ? null
                  : Text(
                      'تُخزَّن المناطق التي زرتها فقط',
                      style: theme.textTheme.bodySmall,
                    ),
              trailing: layer == selected
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(layer),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
