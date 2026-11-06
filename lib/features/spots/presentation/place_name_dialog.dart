import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// نافذة إدخال اسم المكان، تُستخدم للحفظ الجديد وتعديل الاسم معاً.
///
/// يملك هذا الـState وحدة التحكم بالنص ويحرّرها في `dispose`، أي بعد انتهاء
/// حركة إغلاق النافذة. تحريرها فور إغلاق `showDialog` يسبب
/// «A TextEditingController was used after being disposed».
class PlaceNameDialog extends StatefulWidget {
  const PlaceNameDialog({
    super.key,
    this.point,
    this.initialName,
    this.title = 'حفظ مكان',
  });

  /// تُعرض إحداثياته أسفل العنوان عند حفظ مكان جديد.
  final LatLng? point;

  /// الاسم الحالي عند التعديل.
  final String? initialName;

  final String title;

  /// يعيد الاسم المكتوب، أو `null` عند الإلغاء.
  static Future<String?> show(
    BuildContext context, {
    LatLng? point,
    String? initialName,
    String title = 'حفظ مكان',
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => PlaceNameDialog(
        point: point,
        initialName: initialName,
        title: title,
      ),
    );
  }

  @override
  State<PlaceNameDialog> createState() => _PlaceNameDialogState();
}

class _PlaceNameDialogState extends State<PlaceNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final point = widget.point;

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (point != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${point.latitude.toStringAsFixed(5)}, '
                '${point.longitude.toStringAsFixed(5)}',
                textDirection: TextDirection.ltr,
                style: theme.textTheme.bodySmall,
              ),
            ),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            maxLength: 60,
            decoration: const InputDecoration(
              labelText: 'اسم المكان',
              hintText: 'مثال: شعيب أبو رضمة',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
