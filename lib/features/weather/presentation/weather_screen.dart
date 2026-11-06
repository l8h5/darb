import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/app_config.dart';
import '../../../core/location/location_service.dart';
import '../data/weather_repository.dart';
import '../domain/weather_snapshot.dart';
import 'widgets/weather_content.dart';
import 'widgets/weather_states.dart';

/// الطقس الحالي من Open-Meteo، مع كاش لآخر بيانات ناجحة.
///
/// لا يطلب الموقع تلقائياً: يبدأ بطقس حائل، ولا يطلب إذن الموقع إلا عند
/// الضغط على «طقس موقعي».
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherRepository _repository = WeatherRepository();
  final LocationService _locationService = LocationService();

  WeatherResult? _result;
  bool _loading = true;
  bool _locating = false;
  LatLng _point = AppConfig.hail;
  String _placeLabel = 'حائل';

  @override
  void initState() {
    super.initState();
    _load(_point, _placeLabel);
  }

  Future<void> _load(LatLng point, String label) async {
    setState(() => _loading = true);
    final result = await _repository.fetch(point);
    if (!mounted) return;

    setState(() {
      _point = point;
      _placeLabel = label;
      _result = result;
      _loading = false;
    });
  }

  Future<void> _useMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);

    final position = await _locationService.currentPosition();
    if (!mounted) return;
    setState(() => _locating = false);

    if (!position.isSuccess) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(position.message ?? 'تعذّر تحديد الموقع.')),
        );
      return;
    }

    final current = position.position!;
    await _load(
      LatLng(current.latitude, current.longitude),
      'موقعي الحالي',
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الطقس'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: _loading ? null : () => _load(_point, _placeLabel),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(_point, _placeLabel),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (result?.isStale ?? false) const WeatherStaleBanner(),
            if (_loading && result == null)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (result == null || !result.hasData)
              WeatherErrorState(
                message: result?.message ?? 'لا توجد بيانات طقس.',
                onRetry: () => _load(_point, _placeLabel),
              )
            else
              WeatherContent(
                snapshot: result.snapshot!,
                placeLabel: _placeLabel,
                loading: _loading,
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _locating ? null : _useMyLocation,
              icon: _locating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(_locating ? 'جارٍ التحديد…' : 'طقس موقعي'),
            ),
            const SizedBox(height: 16),
            Text(
              'المصدر: Open-Meteo (بيانات مجانية بلا مفتاح). '
              'لا نعرض تنبيهات سيول أو مخاطر لعدم توفر مصدر رسمي.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
