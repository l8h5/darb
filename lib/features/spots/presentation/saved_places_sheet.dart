import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/format/coordinate_formatter.dart';
import '../../../core/format/distance_formatter.dart';
import '../../settings/domain/user_preferences.dart';
import '../data/saved_places_repository.dart';
import '../domain/saved_place.dart';
import 'place_name_dialog.dart';

/// قائمة الأماكن المحفوظة داخل لوحة سفلية.
///
/// عند اختيار مكان تُغلق اللوحة وتُعاد القيمة إلى شاشة الخريطة لتنتقل إليه.
class SavedPlacesSheet extends StatefulWidget {
  const SavedPlacesSheet({
    super.key,
    required this.places,
    required this.repository,
    required this.coordinateFormat,
    required this.distanceUnit,
    required this.myPosition,
    required this.onChanged,
  });

  final List<SavedPlace> places;

  /// يُستخدم للحذف فقط؛ القراءة تحدث في شاشة الخريطة.
  final SavedPlacesRepository repository;

  final CoordinateFormat coordinateFormat;
  final DistanceUnit distanceUnit;

  /// آخر موقع معروف للمستخدم؛ تُعرض المسافة إن وُجد.
  final LatLng? myPosition;

  /// تُستدعى بعد كل تغيير حتى تبقى نسخة الخريطة محدّثة.
  final ValueChanged<List<SavedPlace>> onChanged;

  @override
  State<SavedPlacesSheet> createState() => _SavedPlacesSheetState();
}

class _SavedPlacesSheetState extends State<SavedPlacesSheet> {
  late List<SavedPlace> _places = widget.places;

  /// تعديل اسم المكان مع إبقاء الإحداثيات كما هي.
  Future<void> _rename(SavedPlace place) async {
    final name = await PlaceNameDialog.show(
      context,
      initialName: place.name,
      title: 'تعديل الاسم',
    );
    if (name == null) return;

    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == place.name) return;

    final updated = await widget.repository.update(place.copyWith(name: trimmed));
    if (!mounted) return;

    setState(() => _places = updated);
    widget.onChanged(updated);
  }

  Future<void> _confirmDelete(SavedPlace place) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف المكان؟'),
        content: Text('سيُحذف «${place.name}» من هذا الجهاز.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final updated = await widget.repository.remove(place.id);
    if (!mounted) return;

    setState(() => _places = updated);
    widget.onChanged(updated);
  }

  String? _distanceLabel(SavedPlace place) {
    final myPosition = widget.myPosition;
    if (myPosition == null) return null;

    final meters = const Distance().as(
      LengthUnit.Meter,
      myPosition,
      place.point,
    );
    return 'يبعد ${DistanceFormatter.format(
      meters,
      miles: widget.distanceUnit == DistanceUnit.miles,
    )}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('الأماكن المحفوظة', style: theme.textTheme.titleMedium),
            ),
            if (_places.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Text(
                  'لا توجد أماكن محفوظة بعد.\n'
                  'اضغط مطوّلاً على أي مكان في الخريطة لحفظه.',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              // `Flexible` داخل Column بلا ارتفاع محدود يسبب انفجار التخطيط
              // (RenderFlex overflow) في لوحة سفلية، لذلك نحدّ الارتفاع صراحةً.
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _places.length,
                  itemBuilder: (context, index) {
                    final place = _places[index];
                    final coordinates = CoordinateFormatter.format(
                      place.point,
                      dms: widget.coordinateFormat == CoordinateFormat.dms,
                    );
                    final distance = _distanceLabel(place);
                    return ListTile(
                      leading: const Icon(
                        Icons.bookmark,
                        color: Color(0xFFB3261E),
                      ),
                      title: Text(place.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coordinates,
                            textDirection: TextDirection.ltr,
                          ),
                          if (distance != null) Text(distance),
                        ],
                      ),
                      isThreeLine: distance != null,
                      onTap: () => Navigator.of(context).pop(place),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'تعديل الاسم',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _rename(place),
                          ),
                          IconButton(
                            tooltip: 'حذف',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmDelete(place),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
