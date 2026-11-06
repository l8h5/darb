import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

import 'compass_math.dart';

/// بوصلة الجهاز من حساسات الحركة.
///
/// * لا تطلب أي صلاحية ولا ترسل شيئاً للشبكة.
/// * تجمع آخر قراءة تسارع ومجال مغناطيسي ثم تحسب الاتجاه مع تعويض الميل.
/// * كل الاشتراكات تُلغى في [stop] و[dispose].
class CompassService {
  final StreamController<double> _headings =
      StreamController<double>.broadcast();

  StreamSubscription<AccelerometerEvent>? _accelerometer;
  StreamSubscription<MagnetometerEvent>? _magnetometer;

  AccelerometerEvent? _lastAcceleration;
  MagnetometerEvent? _lastMagneticField;

  double? _heading;
  bool _failed = false;

  /// اتجاه أعلى الجهاز بالدرجات (0 = شمال) مع تمهيد بسيط.
  Stream<double> get headings => _headings.stream;

  bool get isRunning => _accelerometer != null;

  void start() {
    if (_accelerometer != null) return;
    _failed = false;
    _heading = null;

    _accelerometer = accelerometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen(
      (event) {
        _lastAcceleration = event;
        _emit();
      },
      onError: (Object _) => _fail(),
      cancelOnError: false,
    );

    _magnetometer = magnetometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen(
      (event) {
        _lastMagneticField = event;
        _emit();
      },
      onError: (Object _) => _fail(),
      cancelOnError: false,
    );
  }

  /// يوقف الاستماع فوراً (عند إخفاء الشاشة أو مغادرتها).
  Future<void> stop() async {
    await _accelerometer?.cancel();
    await _magnetometer?.cancel();
    _accelerometer = null;
    _magnetometer = null;
    _lastAcceleration = null;
    _lastMagneticField = null;
    _heading = null;
  }

  void _emit() {
    if (_failed || _headings.isClosed) return;

    final acceleration = _lastAcceleration;
    final magnetic = _lastMagneticField;
    if (acceleration == null || magnetic == null) return;

    final raw = CompassMath.headingFrom(
      ax: acceleration.x,
      ay: acceleration.y,
      az: acceleration.z,
      mx: magnetic.x,
      my: magnetic.y,
      mz: magnetic.z,
    );
    if (raw == null) return;

    _heading = _heading == null ? raw : CompassMath.smooth(_heading!, raw);
    _headings.add(_heading!);
  }

  void _fail() {
    _failed = true;
    _headings.addError(StateError('البوصلة غير متاحة على هذا الجهاز'));
  }

  Future<void> dispose() async {
    await stop();
    await _headings.close();
  }
}
