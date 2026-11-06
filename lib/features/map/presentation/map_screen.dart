import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/app_config.dart';
import '../../../core/location/location_service.dart';
import '../../spots/data/saved_places_repository.dart';
import '../../spots/domain/saved_place.dart';
import '../../spots/presentation/place_name_dialog.dart';
import '../../spots/presentation/saved_places_sheet.dart';
import '../../settings/domain/user_preferences.dart';
import '../../settings/presentation/preferences_scope.dart';
import '../../settings/presentation/settings_screen.dart';
import '../data/map_tile_provider.dart';
import '../domain/map_layer.dart';
import 'widgets/map_attribution.dart';
import 'widgets/map_header.dart';
import 'widgets/map_layer_sheet.dart';
import 'widgets/map_view.dart';

/// شاشة الخريطة الأساسية.
///
/// المسؤوليات:
///  * عرض الخريطة على حائل عند الفتح.
///  * عرض إحداثيات مركز الخريطة أثناء التحريك.
///  * تحديد موقع المستخدم عند الضغط على الزر فقط (لا إذن مسبق).
///  * حفظ الأماكن بالضغط المطوّل، والرجوع إليها من القائمة.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final MapTileProvider _tiles = MapTileProvider();
  final SavedPlacesRepository _savedPlacesRepository = SavedPlacesRepository();

  /// الأماكن المحفوظة على الجهاز، الأحدث أولاً.
  List<SavedPlace> _savedPlaces = const [];

  /// مركز الخريطة الحالي.
  ///
  /// نستخدم [ValueNotifier] بدل `setState` لأن التحريك يُطلق عشرات التحديثات
  /// في الثانية؛ بهذه الطريقة تُحدَّث خانة الإحداثيات وحدها دون إعادة بناء الخريطة.
  final ValueNotifier<LatLng> _center = ValueNotifier<LatLng>(AppConfig.hail);

  LatLng? _myPosition;
  double? _accuracyMeters;
  bool _locating = false;

  /// الطبقة المعروضة حالياً.
  MapLayer _layer = MapLayer.streets;

  /// آخر طبقة افتراضية مقروءة من التفضيلات.
  ///
  /// نغيّر [_layer] عند تغيّر الإعداد فقط، لا مع كل إعادة بناء، حتى لا
  /// تُفقد الطبقة التي اختارها المستخدم يدوياً من زر الطبقات.
  MapLayer? _lastDefaultLayer;
  bool _preferencesApplied = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPlaces();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final prefs = PreferencesScope.of(context).preferences;
    if (!_preferencesApplied) {
      _preferencesApplied = true;
      _layer = prefs.defaultLayer;
      _lastDefaultLayer = prefs.defaultLayer;
    } else if (prefs.defaultLayer != _lastDefaultLayer) {
      _lastDefaultLayer = prefs.defaultLayer;
      _layer = prefs.defaultLayer;
    }
  }

  Future<void> _loadSavedPlaces() async {
    final places = await _savedPlacesRepository.all();
    if (!mounted) return;
    setState(() => _savedPlaces = places);
  }

  @override
  void dispose() {
    _center.dispose();
    _tiles.dispose();
    // إغلاق ملف SQLite عند مغادرة الشاشة؛ لا ننتظره لأن `dispose` متزامنة.
    unawaited(_savedPlacesRepository.close());
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
      setState(() {
        _myPosition = target;
        _accuracyMeters = position.accuracy;
      });
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
    final name = await PlaceNameDialog.show(context, point: point);
    if (name == null) return; // إلغاء

    final trimmedName = name.trim();
    final place = SavedPlace.create(
      name: trimmedName.isEmpty ? 'مكان محفوظ' : trimmedName,
      point: point,
    );
    final updated = await _savedPlacesRepository.add(place);
    if (!mounted) return;

    setState(() => _savedPlaces = updated);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('تم حفظ «${place.name}»')),
      );
  }

  /// يبدّل طبقة الخريطة (عادية / تضاريس / أقمار صناعية).
  Future<void> _pickLayer() async {
    final selected = await showModalBottomSheet<MapLayer>(
      context: context,
      showDragHandle: true,
      builder: (_) => MapLayerSheet(selected: _layer),
    );

    if (selected == null || selected == _layer || !mounted) return;
    setState(() => _layer = selected);
  }

  Future<void> _openSavedPlaces() async {
    final prefs = PreferencesScope.of(context).preferences;
    final selected = await showModalBottomSheet<SavedPlace>(
      context: context,
      showDragHandle: true,
      builder: (_) => SavedPlacesSheet(
        places: _savedPlaces,
        repository: _savedPlacesRepository,
        coordinateFormat: prefs.coordinateFormat,
        distanceUnit: prefs.distanceUnit,
        myPosition: _myPosition,
        onChanged: (places) {
          if (mounted) setState(() => _savedPlaces = places);
        },
      ),
    );

    if (selected == null) return;
    _mapController.move(selected.point, AppConfig.savedPlaceZoom);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = PreferencesScope.of(context).preferences;

    return Scaffold(
      body: Stack(
        children: [
          DarbMapView(
            mapController: _mapController,
            tiles: _tiles,
            layer: _layer,
            myPosition: _myPosition,
            savedPlaces: _savedPlaces,
            onCenterChanged: (center) => _center.value = center,
            onLongPress: _promptSavePlace,
            onPlaceTap: (place) => _showPlaceName(place.name),
          ),
          MapHeader(
            center: _center,
            savedCount: _savedPlaces.length,
            coordinateFormat: prefs.coordinateFormat,
            advanced: prefs.usageMode == UsageMode.advanced,
            accuracyMeters: _accuracyMeters,
            onFitSaudiArabia: _fitSaudiArabia,
            onGoToHail: _goToHail,
            onOpenSavedPlaces: _openSavedPlaces,
            onOpenSettings: _openSettings,
          ),
          MapAttribution(text: _layer.attribution),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (prefs.usageMode == UsageMode.advanced) ...[
            FloatingActionButton.small(
              heroTag: 'layers',
              tooltip: 'طبقة الخريطة',
              onPressed: _pickLayer,
              child: Icon(_layer.icon),
            ),
            const SizedBox(height: 8),
          ],
          FloatingActionButton.extended(
            heroTag: 'locate',
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
        ],
      ),
    );
  }

  void _showPlaceName(String name) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(name)));
  }
}
