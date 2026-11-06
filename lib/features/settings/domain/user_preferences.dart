import '../../map/domain/map_layer.dart';

/// نمط الاستخدام: واجهة مبسّطة أو أدوات ملاحة إضافية.
///
/// النمط لا يغيّر المحرّك ولا البيانات؛ يغيّر ما يُعرض فقط.
enum UsageMode {
  simple('بسيط'),
  advanced('متقدم');

  const UsageMode(this.label);

  final String label;
}

/// وحدة المسافة المعروضة في الواجهة.
enum DistanceUnit {
  kilometers('كم'),
  miles('ميل');

  const DistanceUnit(this.label);

  final String label;
}

/// طريقة كتابة الإحداثيات.
enum CoordinateFormat {
  decimal('عشري'),
  dms('درجات دقائق ثوان');

  const CoordinateFormat(this.label);

  final String label;
}

/// تفضيلات المستخدم المحلية.
///
/// تُحفظ في `shared_preferences` (الآلية الموجودة أصلاً في المشروع)،
/// وليست قاعدة بيانات جديدة. كل الحقول لها قيم افتراضية آمنة، لذلك
/// تشغيل التطبيق لا يعتمد على وجود بيانات محفوظة.
///
/// التوافق المستقبلي: يُحفظ رقم [schemaVersion] مع البيانات، وعند إضافة
/// حقول جديدة تُقرأ القيم الناقصة من الافتراضي بدل رفض الملف كله.
class UserPreferences {
  const UserPreferences({
    this.onboardingCompleted = false,
    this.usageMode = UsageMode.simple,
    this.defaultLayer = MapLayer.streets,
    this.distanceUnit = DistanceUnit.kilometers,
    this.coordinateFormat = CoordinateFormat.decimal,
  });

  static const int schemaVersion = 1;

  final bool onboardingCompleted;
  final UsageMode usageMode;
  final MapLayer defaultLayer;
  final DistanceUnit distanceUnit;
  final CoordinateFormat coordinateFormat;

  UserPreferences copyWith({
    bool? onboardingCompleted,
    UsageMode? usageMode,
    MapLayer? defaultLayer,
    DistanceUnit? distanceUnit,
    CoordinateFormat? coordinateFormat,
  }) {
    return UserPreferences(
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      usageMode: usageMode ?? this.usageMode,
      defaultLayer: defaultLayer ?? this.defaultLayer,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      coordinateFormat: coordinateFormat ?? this.coordinateFormat,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': schemaVersion,
        'onboardingCompleted': onboardingCompleted,
        'usageMode': usageMode.name,
        'defaultLayer': defaultLayer.name,
        'distanceUnit': distanceUnit.name,
        'coordinateFormat': coordinateFormat.name,
      };

  /// يقرأ التفضيلات ويتجاهل أي قيمة غير معروفة.
  ///
  /// لا يرمي استثناءً أبداً: ملف تالف أو من إصدار أحدث يعني الرجوع
  /// للافتراضي، لا منع تشغيل التطبيق.
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      onboardingCompleted: json['onboardingCompleted'] is bool
          ? json['onboardingCompleted'] as bool
          : false,
      usageMode: _byName(UsageMode.values, json['usageMode'],
          UsageMode.simple),
      defaultLayer: _byName(MapLayer.values, json['defaultLayer'],
          MapLayer.streets),
      distanceUnit: _byName(DistanceUnit.values, json['distanceUnit'],
          DistanceUnit.kilometers),
      coordinateFormat: _byName(CoordinateFormat.values,
          json['coordinateFormat'], CoordinateFormat.decimal),
    );
  }

  static T _byName<T extends Enum>(
    List<T> values,
    Object? raw,
    T fallback,
  ) {
    if (raw is String) {
      for (final value in values) {
        if (value.name == raw) return value;
      }
    }
    return fallback;
  }

  @override
  bool operator ==(Object other) =>
      other is UserPreferences &&
      other.onboardingCompleted == onboardingCompleted &&
      other.usageMode == usageMode &&
      other.defaultLayer == defaultLayer &&
      other.distanceUnit == distanceUnit &&
      other.coordinateFormat == coordinateFormat;

  @override
  int get hashCode => Object.hash(
        onboardingCompleted,
        usageMode,
        defaultLayer,
        distanceUnit,
        coordinateFormat,
      );
}
