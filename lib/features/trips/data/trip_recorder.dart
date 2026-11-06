import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/location/location_service.dart';
import '../domain/trip.dart';
import '../domain/trip_stats.dart';
import 'trips_repository.dart';

/// يدير دورة حياة تسجيل الرحلة: بدء، إيقاف مؤقت، استكمال، إنهاء.
///
/// * يكتب كل نقطة في SQLite فور وصولها، فلا تفسد الرحلة إذا أُغلق التطبيق.
/// * عند إعادة التشغيل تُستعاد الرحلة المفتوحة **متوقفة مؤقتاً** حتى يقرر
///   المستخدم الاستكمال؛ لا يبدأ التتبع تلقائياً.
/// * لا يعمل في الخلفية: الاشتراك يُلغى عند الإيقاف أو مغادرة الشاشة.
class TripRecorder extends ChangeNotifier {
  TripRecorder({
    required this.repository,
    LocationService? locationService,
  }) : _locationService = locationService ?? LocationService();

  /// أقل دقة مقبولة (بالمتر)؛ القراءات الأسوأ تُتجاهل.
  static const double _maxAccuracyMeters = 60;

  /// أقل مسافة بين نقطتين حتى لا يمتلئ المسار بنقاط ثابتة.
  static const double _minSegmentMeters = 5;

  /// قفزة أكبر من هذا في قراءة واحدة تُعدّ خطأ GPS لا حركة حقيقية.
  static const double _maxJumpMeters = 1500;

  final TripsRepository repository;
  final LocationService _locationService;

  StreamSubscription<Position>? _subscription;

  Trip? _trip;
  TripPoint? _lastPoint;
  DateTime? _firstPointAt;
  DateTime? _lastPointAt;

  double _distanceMeters = 0;
  int _pointCount = 0;
  bool _paused = false;
  bool _busy = false;
  bool _recovered = false;
  String? _errorMessage;

  Trip? get trip => _trip;
  bool get hasActiveTrip => _trip != null;
  bool get isPaused => _trip != null && _paused;
  bool get isRecording => _trip != null && !_paused;
  bool get busy => _busy;
  bool get recovered => _recovered;
  String? get errorMessage => _errorMessage;
  double get distanceMeters => _distanceMeters;
  int get pointCount => _pointCount;

  /// المدة بين أول نقطة وآخر نقطة، ولا تحسب فترات الإيقاف المؤقت.
  Duration get elapsed {
    final first = _firstPointAt;
    if (first == null) return Duration.zero;

    final end = _paused ? (_lastPointAt ?? first) : DateTime.now();
    final duration = end.difference(first);
    return duration.isNegative ? Duration.zero : duration;
  }

  double get averageSpeedKmh => TripStats.averageSpeedKmh(
        distanceMeters: _distanceMeters,
        duration: elapsed,
      );

  /// استعادة رحلة مفتوحة بعد إغلاق التطبيق أو إعادة تشغيل الجهاز.
  Future<void> restore() async {
    if (_trip != null) return;

    final active = await repository.active();
    if (active == null) return;

    final points = await repository.points(active.id);
    _trip = active;
    _distanceMeters = active.distanceMeters;
    _pointCount = points.length;
    if (points.isNotEmpty) {
      _firstPointAt = points.first.recordedAt;
      _lastPointAt = points.last.recordedAt;
      _lastPoint = points.last;
    }

    // نفتحها متوقفة حتى لا يبدأ التتبع دون علم المستخدم.
    _paused = true;
    _recovered = true;
    notifyListeners();
  }

  Future<bool> start() async {
    if (_busy || _trip != null) return false;
    _busy = true;
    _errorMessage = null;
    notifyListeners();

    final permission = await _locationService.ensurePermission();
    if (!permission.isGranted) {
      _busy = false;
      _errorMessage = permission.message;
      notifyListeners();
      return false;
    }

    Trip? created;
    try {
      created = await repository.create();
      _trip = created;
      _distanceMeters = 0;
      _pointCount = 0;
      _lastPoint = null;
      _firstPointAt = null;
      _lastPointAt = null;
      _paused = false;
      _recovered = false;
      _subscribe();
      _busy = false;
      notifyListeners();
      return true;
    } catch (error) {
      if (created != null) {
        await repository.delete(created.id);
      }
      _trip = null;
      _busy = false;
      _errorMessage = 'تعذّر بدء تسجيل الرحلة: $error';
      notifyListeners();
      return false;
    }
  }

  Future<void> pause() async {
    if (_trip == null || _paused) return;
    await _subscription?.cancel();
    _subscription = null;
    _paused = true;
    notifyListeners();
  }

  Future<void> resume() async {
    if (_trip == null || !_paused || _busy) return;
    _busy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _subscribe();
      _paused = false;
      _recovered = false;
      _busy = false;
      notifyListeners();
    } catch (error) {
      _busy = false;
      _errorMessage = 'تعذّر استكمال التسجيل: $error';
      notifyListeners();
    }
  }

  /// ينهي الرحلة ويعيدها محفوظة، أو `null` عند الفشل.
  Future<Trip?> finish() async {
    final current = _trip;
    if (current == null || _busy) return null;

    _busy = true;
    notifyListeners();

    await _subscription?.cancel();
    _subscription = null;

    try {
      final finished = await repository.finish(
        tripId: current.id,
        distanceMeters: _distanceMeters,
        pointCount: _pointCount,
      );
      _resetState();
      notifyListeners();
      return finished;
    } catch (error) {
      _busy = false;
      _errorMessage = 'تعذّر إنهاء الرحلة: $error';
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void _subscribe() {
    _subscription = _locationService
        .positionStream(distanceFilterMeters: _minSegmentMeters.round())
        .listen(
          _onPosition,
          onError: _onStreamError,
          cancelOnError: false,
        );
  }

  void _onPosition(Position position) {
    final current = _trip;
    if (current == null || _paused) return;

    final accuracy = position.accuracy;
    if (accuracy > _maxAccuracyMeters) return;

    final point = TripPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      recordedAt: position.timestamp,
      accuracyMeters: accuracy,
      speedMps: position.speed,
      altitudeMeters: position.altitude,
    );

    final last = _lastPoint;
    if (last != null) {
      final segment = TripStats.distanceBetween(last, point);
      if (segment > _maxJumpMeters) return;
      if (segment < _minSegmentMeters) return;
      _distanceMeters += segment;
    }

    _lastPoint = point;
    _pointCount += 1;
    _firstPointAt ??= point.recordedAt;
    _lastPointAt = point.recordedAt;
    notifyListeners();

    unawaited(
      repository
          .appendPoint(
            tripId: current.id,
            point: point,
            distanceMeters: _distanceMeters,
            pointCount: _pointCount,
          )
          .catchError((Object error) {
        _errorMessage = 'تعذّر حفظ نقطة من المسار: $error';
        notifyListeners();
      }),
    );
  }

  void _onStreamError(Object error) {
    _errorMessage = 'انقطع GPS. تحقّق من إذن الموقع أو افتح السماء ثم '
        'استكمل التسجيل. ($error)';
    unawaited(pause());
  }

  void _resetState() {
    _trip = null;
    _lastPoint = null;
    _firstPointAt = null;
    _lastPointAt = null;
    _distanceMeters = 0;
    _pointCount = 0;
    _paused = false;
    _busy = false;
    _recovered = false;
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }
}
