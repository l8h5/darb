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

/// نتيجة طلب إذن الموقع، منفصلة عن نتيجة تحديد الموقع نفسه.
class PermissionResult {
  const PermissionResult.granted()
      : failure = null,
        message = null;

  const PermissionResult.denied(this.failure, this.message);

  final LocationFailure? failure;
  final String? message;

  bool get isGranted => failure == null;
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
  /// يتحقق من خدمة الموقع والإذن، ويطلبه عند الحاجة فقط.
  Future<PermissionResult> ensurePermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const PermissionResult.denied(
          LocationFailure.serviceDisabled,
          'خدمة الموقع مغلقة في الجهاز. افتحها ثم أعد المحاولة.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const PermissionResult.denied(
          LocationFailure.permissionDenied,
          'لم تمنح إذن الموقع. لا يمكن تحديد موقعك بدونه.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return const PermissionResult.denied(
          LocationFailure.permissionDeniedForever,
          'إذن الموقع مرفوض نهائياً. افتح إعدادات التطبيق وامنحه يدوياً.',
        );
      }

      return const PermissionResult.granted();
    } on LocationServiceDisabledException {
      return const PermissionResult.denied(
        LocationFailure.serviceDisabled,
        'خدمة الموقع مغلقة في الجهاز. افتحها ثم أعد المحاولة.',
      );
    } on PermissionDeniedException {
      return const PermissionResult.denied(
        LocationFailure.permissionDenied,
        'لم تمنح إذن الموقع. لا يمكن تحديد موقعك بدونه.',
      );
    } catch (error) {
      return PermissionResult.denied(
        LocationFailure.unknown,
        'تعذّر التحقق من إذن الموقع: $error',
      );
    }
  }

  /// يطلب الإذن عند الحاجة فقط، ثم يعيد موقعاً واحداً بدقة عالية.
  Future<LocationResult> currentPosition() async {
    final permission = await ensurePermission();
    if (!permission.isGranted) {
      return LocationResult.failure(permission.failure, permission.message);
    }

    try {
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

  /// بثّ موقع لتسجيل رحلة في المقدمة فقط.
  ///
  /// المستدعي مسؤول عن إلغاء الاشتراك؛ لا يعمل هذا في الخلفية ولا بعد
  /// إغلاق التطبيق.
  Stream<Position> positionStream({int distanceFilterMeters = 8}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    );
  }

  /// يفتح إعدادات التطبيق (تُستخدم عند رفض الإذن نهائياً).
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// يفتح إعدادات الموقع في الجهاز (تُستخدم عند إغلاق خدمة الموقع).
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
