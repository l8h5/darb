import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/app_config.dart';
import '../models/saved_place.dart';
import '../services/location_service.dart';
import '../services/osm_tile_provider.dart';
import '../services/saved_places_service.dart';

/// شاشة الخريطة الأساسية.
///
/// المسؤوليات:
///  * عرض الخريطة على حائل عند الفتح.
///  * عرض إحداثيات مركز الخريطة أثناء التحريك.
///  * تحديد موقع المستخدم عند الضغط على الزر فقط (لا إذن مسبق).
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final OsmTileProvider _tiles = OsmTileProvider();
  final SavedPlacesService _savedPlacesService = SavedPlacesService();

  /// الأماكن المحفوظة على الجهاز، الأحدث أولاً.
  List<SavedPlace> _savedPlaces = const [];

  /// مركز الخريطة الحالي.
  ///
  /// نستخدم [ValueNotifier] بدل `setState` لأن التحريك يُطلق عشرات التحديثات
  /// في الثانية؛ بهذه الطريقة تُحدَّث خانة الإحداثيات وحدها دون إعادة بناء الخريطة.
  final ValueNotifier<LatLng> _center = ValueNotifier<LatLng>(AppConfig.hail);

  LatLng? _myPosition;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPlaces();
  }

  Future<void> _loadSavedPlaces() async {
    final places = await _savedPlacesService.load();
    if (!mounted) return;
    setState(() => _savedPlaces = places);
  }

  @override
  void dispose() {
    _center.dispose();
    _tiles.dispose();
    super.dispose();
  }

  Future<void> _locateMe() async {
    if (_locating) return;
    setState(() => _locating = true);

    final result = await _locationService.currentPosition();
    if (!mounted) return;

    setState(() => _locating = false);

    if (result.isSuccess) {
      final position = result.position!;
      final target = LatLng(position.latitude, position.longitude);
      setState(() => _myPosition = target);
      _mapController.move(target, AppConfig.myLocationZoom);
      return;
    }

    _showLocationMessage(result);
  }

  void _showLocationMessage(LocationResult result) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final needsSettings =
        result.failure == LocationFailure.permissionDeniedForever;
    final needsLocationService =
        result.failure == LocationFailure.serviceDisabled;

    messenger.showSnackBar(
      SnackBar(
        content: Text(result.message ?? 'تعذّر تحديد الموقع.'),
        action: needsSettings
            ? SnackBarAction(
                label: 'الإعدادات',
                onPressed: () => _locationService.openAppSettings(),
              )
            : needsLocationService
                ? SnackBarAction(
                    label: 'تشغيل الموقع',
                    onPressed: () => _locationService.openLocationSettings(),
                  )
                : null,
      ),
    );
  }

  void _goToHail() {
    _mapController.move(AppConfig.hail, AppConfig.hailZoom);
  }

  void _fitSaudiArabia() {
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          AppConfig.saudiSouthWest,
          AppConfig.saudiNorthEast,
        ),
        padding: const EdgeInsets.all(24),
      ),
    );
  }

  /// ضغط مطوّل على الخريطة → طلب اسم → حفظ المكان على الجهاز.
  Future<void> _promptSavePlace(LatLng point) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _SavePlaceDialog(point: point),
    );

    // زر «إلغاء» أو الرجوع يعيد null؛ لا نحفظ شيئاً.
    if (name == null) return;

    final trimmedName = name.trim();
    final place = SavedPlace.create(
      name: trimmedName.isEmpty ? 'مكان محفوظ' : trimmedName,
      point: point,
    );
    final updated = await _savedPlacesService.add(place);
    if (!mounted) return;

    setState(() => _savedPlaces = updated);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('تم حفظ «${place.name}»')),
      );
  }

  void _openSavedPlaces() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return _buildSavedPlacesSheet(sheetContext, setSheetState);
          },
        );
      },
    );
  }

  Widget _buildSavedPlacesSheet(
    BuildContext sheetContext,
    StateSetter setSheetState,
  ) {
    final theme = Theme.of(sheetContext);

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
            if (_savedPlaces.isEmpty)
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
                  maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _savedPlaces.length,
                  itemBuilder: (context, index) {
                    final place = _savedPlaces[index];
                    return ListTile(
                      leading: const Icon(Icons.bookmark, color: Color(0xFFB3261E)),
                      title: Text(place.name),
                      subtitle: Text(
                        '${place.latitude.toStringAsFixed(5)}, '
                        '${place.longitude.toStringAsFixed(5)}',
                        textDirection: TextDirection.ltr,
                      ),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _mapController.move(place.point, AppConfig.savedPlaceZoom);
                      },
                      trailing: IconButton(
                        tooltip: 'حذف',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDeletePlace(
                          place,
                          sheetContext,
                          setSheetState,
                        ),
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

  Future<void> _confirmDeletePlace(
    SavedPlace place,
    BuildContext sheetContext,
    StateSetter setSheetState,
  ) async {
    final confirmed = await showDialog<bool>(
      context: sheetContext,
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

    final updated = await _savedPlacesService.remove(place.id);
    if (!mounted) return;

    setState(() => _savedPlaces = updated);
    setSheetState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: AppConfig.hail,
              initialZoom: AppConfig.hailZoom,
              minZoom: AppConfig.minZoom,
              maxZoom: AppConfig.maxZoom,
              backgroundColor: const Color(0xFFEDE6D6),
              // تعطيل التدوير: يسبب ارتباكاً للمستخدم، ويجب أن تبقى الخريطة
              // شمالية دائماً حتى نضيف البوصلة/القبلة لاحقاً.
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onPositionChanged: (camera, hasGesture) {
                _center.value = camera.center;
              },
              // الضغط المطوّل يحفظ مكاناً — لا يحتاج إنترنت ولا إذن موقع.
              onLongPress: (tapPosition, point) => _promptSavePlace(point),
            ),
            children: [
              TileLayer(
                urlTemplate: AppConfig.osmTileUrl,
                // إلزامي بحسب سياسة OpenStreetMap.
                userAgentPackageName: AppConfig.osmUserAgentPackage,
                tileProvider: _tiles.provider,
                maxNativeZoom: AppConfig.osmMaxNativeZoom,
                maxZoom: AppConfig.maxZoom,
              ),
              if (_myPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _myPosition!,
                      width: 26,
                      height: 26,
                      child: const _MyLocationDot(),
                    ),
                  ],
                ),
              if (_savedPlaces.isNotEmpty)
                MarkerLayer(
                  markers: [
                    for (final place in _savedPlaces)
                      Marker(
                        point: place.point,
                        width: 34,
                        height: 34,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(content: Text(place.name)),
                              );
                          },
                          child: const _SavedPlaceMarker(),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          _buildHeader(context),
          _buildAttribution(context),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _locating ? null : _locateMe,
        icon: _locating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location),
        label: Text(_locating ? 'جارٍ التحديد…' : 'موقعي'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مركز الخريطة',
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 2),
                  ValueListenableBuilder<LatLng>(
                    valueListenable: _center,
                    builder: (context, center, _) {
                      return Text(
                        '${center.latitude.toStringAsFixed(5)}, '
                        '${center.longitude.toStringAsFixed(5)}',
                        // الأرقام تُعرض دائماً بالإنجليزية لتسهيل النسخ والقراءة.
                        textDirection: TextDirection.ltr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: _fitSaudiArabia,
                        icon: const Icon(Icons.public, size: 18),
                        label: const Text('المملكة'),
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: _goToHail,
                        icon: const Icon(Icons.place_outlined, size: 18),
                        label: const Text('حائل'),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'الأماكن المحفوظة',
                        onPressed: _openSavedPlaces,
                        icon: Badge(
                          isLabelVisible: _savedPlaces.isNotEmpty,
                          label: Text('${_savedPlaces.length}'),
                          child: const Icon(Icons.bookmarks_outlined),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'اضغط مطوّلاً على الخريطة لحفظ مكان',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// الإسناد ظاهر دائماً ولا يُخفى خلف زر، كما تشترط سياسة OpenStreetMap.
  Widget _buildAttribution(BuildContext context) {
    return Positioned(
      right: 6,
      bottom: 6,
      child: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              AppConfig.osmAttribution,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}

/// نقطة الموقع الحالي على الخريطة.
class _MyLocationDot extends StatelessWidget {
  const _MyLocationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A73E8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
    );
  }
}

/// دبّوس المكان المحفوظ.
class _SavedPlaceMarker extends StatelessWidget {
  const _SavedPlaceMarker();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.bookmark,
      size: 34,
      color: Color(0xFFB3261E),
      shadows: [
        Shadow(color: Colors.white, blurRadius: 3, offset: Offset(0, 1)),
        Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
      ],
    );
  }
}

/// نافذة تسمية المكان قبل حفظه.
///
/// [TextEditingController] يملكه هذا الـState ويُحرَّر في `dispose`، أي بعد
/// انتهاء حركة إغلاق النافذة. تحريره فور `showDialog` يسبب
/// «A TextEditingController was used after being disposed».
class _SavePlaceDialog extends StatefulWidget {
  const _SavePlaceDialog({required this.point});

  final LatLng point;

  @override
  State<_SavePlaceDialog> createState() => _SavePlaceDialogState();
}

class _SavePlaceDialogState extends State<_SavePlaceDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('حفظ مكان'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.point.latitude.toStringAsFixed(5)}, '
            '${widget.point.longitude.toStringAsFixed(5)}',
            textDirection: TextDirection.ltr,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
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
