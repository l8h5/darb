import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// أسباب فشل تحديد الموقع، مصنّفة حتى تستطيع الواجهة عرض رسالة مناسبة
/// واقتراح الإجراء الصحيح (فتح إعدادات التطبيق أو إعدادات الموقع).
enum LocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

/// نتيجة محاولة تحديد الموقع: إمّا إحداثيات، أو سبب فشل مع رسالة عربية.
class LocationResult {
  LocationResult.success(this.position)
      : failure = null,
        message = null;

  LocationResult.failure(this.failure, this.message) : position = null;

  final Position? position;
  final LocationFailure? failure;
  final String? message;

  bool get isSuccess => position != null;
}

/// خدمة تحديد الموقع.
///
/// معزولة عن الواجهة عمداً: الواجهة لا تعرف شيئاً عن حزمة geolocator،
/// فإذا تغيّرت الحزمة لاحقاً نعدّل هذا الملف فقط.
class LocationService {
  /// يطلب الإذن عند الحاجة فقط، ثم يعيد موقعاً واحداً بدقة عالية.
  Future<LocationResult> currentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.failure(
          LocationFailure.serviceDisabled,
          'خدمة الموقع مغلقة في الجهاز. افتحها ثم أعد المحاولة.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return LocationResult.failure(
          LocationFailure.permissionDenied,
          'لم تمنح إذن الموقع. لا يمكن تحديد موقعك بدونه.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return LocationResult.failure(
          LocationFailure.permissionDeniedForever,
          'إذن الموقع مرفوض نهائياً. افتح إعدادات التطبيق وامنحه يدوياً.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );
      return LocationResult.success(position);
    } on TimeoutException {
      return LocationResult.failure(
        LocationFailure.timeout,
        'تأخّر تحديد الموقع. جرّب في مكان مكشوف بعيداً عن المباني.',
      );
    } on LocationServiceDisabledException {
      return LocationResult.failure(
        LocationFailure.serviceDisabled,
        'خدمة الموقع مغلقة في الجهاز. افتحها ثم أعد المحاولة.',
      );
    } on PermissionDeniedException {
      return LocationResult.failure(
        LocationFailure.permissionDenied,
        'لم تمنح إذن الموقع. لا يمكن تحديد موقعك بدونه.',
      );
    } catch (error) {
      return LocationResult.failure(
        LocationFailure.unknown,
        'تعذّر تحديد الموقع: $error',
      );
    }
  }

  /// يفتح إعدادات التطبيق (تُستخدم عند رفض الإذن نهائياً).
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// يفتح إعدادات الموقع في الجهاز (تُستخدم عند إغلاق خدمة الموقع).
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
