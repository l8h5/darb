import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/format/distance_formatter.dart';
import '../../../core/location/location_service.dart';
import '../../settings/domain/user_preferences.dart';
import '../../settings/presentation/preferences_scope.dart';
import '../data/compass_service.dart';
import '../domain/qibla_calculator.dart';
import 'widgets/qibla_dial.dart';
import 'widgets/qibla_panels.dart';

/// اتجاه القبلة من موقع المستخدم.
///
/// * الحساب محلي بحت (لا إنترنت ولا خدمة خارجية).
/// * لا يُطلب الموقع تلقائياً؛ يظهر زر واضح، احتراماً للخصوصية.
/// * بوصلة الجهاز تُقرأ من الحساسات، وتُلغى كل الاشتراكات عند المغادرة.
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  final CompassService _compass = CompassService();
  final LocationService _locationService = LocationService();

  StreamSubscription<double>? _headingSubscription;
  Timer? _sensorTimeout;

  double? _heading;
  bool _sensorUnavailable = false;

  double? _qiblaBearing;
  double? _distanceMeters;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _startCompass();
  }

  void _startCompass() {
    _headingSubscription = _compass.headings.listen(
      (heading) {
        _sensorTimeout?.cancel();
        if (!mounted) return;
        setState(() {
          _heading = heading;
          _sensorUnavailable = false;
        });
      },
      onError: (Object _) {
        if (!mounted) return;
        setState(() => _sensorUnavailable = true);
      },
    );
    _compass.start();

    // بعض الأجهزة لا ترسل أي قراءة بدل إرجاع خطأ؛ نعتبرها غير متاحة بعد
    // مهلة قصيرة حتى لا تبقى الشاشة معلّقة على «جارٍ التهيئة».
    _sensorTimeout = Timer(const Duration(seconds: 3), () {
      if (!mounted || _heading != null) return;
      setState(() => _sensorUnavailable = true);
    });
  }

  @override
  void dispose() {
    _sensorTimeout?.cancel();
    _headingSubscription?.cancel();
    unawaited(_compass.dispose());
    super.dispose();
  }

  Future<void> _locate() async {
    if (_locating) return;
    setState(() => _locating = true);

    final result = await _locationService.currentPosition();
    if (!mounted) return;

    setState(() => _locating = false);

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(result.message ?? 'تعذّر تحديد الموقع.')),
        );
      return;
    }

    final current = result.position!;
    final point = LatLng(current.latitude, current.longitude);
    setState(() {
      _qiblaBearing = QiblaCalculator.bearingFrom(point);
      _distanceMeters = QiblaCalculator.distanceMetersFrom(point);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = PreferencesScope.of(context).preferences;
    final bearing = _qiblaBearing;

    return Scaffold(
      appBar: AppBar(title: const Text('القبلة')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          if (bearing == null)
            QiblaIntroCard(
              locating: _locating,
              onLocate: _locate,
            )
          else ...[
            Center(
              child: QiblaDial(
                headingDegrees: _heading,
                qiblaDegrees: bearing,
              ),
            ),
            const SizedBox(height: 16),
            QiblaAlignedBanner(bearing: bearing, heading: _heading),
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    QiblaInfoRow(
                      label: 'اتجاه القبلة من موقعك',
                      value: '${bearing.round()}° '
                          '(${QiblaCalculator.directionLabel(bearing)})',
                    ),
                    const Divider(),
                    QiblaInfoRow(
                      label: 'المسافة إلى الكعبة',
                      value: _distanceMeters == null
                          ? '—'
                          : DistanceFormatter.format(
                              _distanceMeters!,
                              miles: prefs.distanceUnit == DistanceUnit.miles,
                            ),
                    ),
                    const Divider(),
                    QiblaInfoRow(
                      label: 'اتجاه الجهاز',
                      value: _heading == null
                          ? '—'
                          : '${_heading!.round()}°',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            CompassStateMessage(
              heading: _heading,
              unavailable: _sensorUnavailable,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _locating ? null : _locate,
              icon: _locating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(_locating ? 'جارٍ التحديد…' : 'تحديث موقعي'),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'الحساب يتم على جهازك من إحداثياتك إلى الكعبة، ولا يُرسل موقعك '
            'لأي خادم. البوصلة تعمل بحساسات الجهاز وقد تتأثر بالمعادن '
            'القريبة؛ تحقق من الاتجاه يدوياً عند الشك.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
