import 'package:latlong2/latlong.dart';

/// مكان يحفظه المستخدم بنفسه من الخريطة (شعيب، محطة، مخيّم…).
///
/// لا يُرسل لأي خادم ولا يحتاج إنترنت؛ التخزين محلي على الجهاز فقط.
class SavedPlace {
  const SavedPlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  /// معرّف فريد محلي؛ يُستخدم للحذف.
  final String id;

  final String name;
  final double latitude;
  final double longitude;

  /// وقت الحفظ؛ تُعرض الأحدث أولاً.
  final DateTime createdAt;

  LatLng get point => LatLng(latitude, longitude);

  /// نسخة معدّلة من المكان مع الحفاظ على المعرّف وتاريخ الإنشاء.
  SavedPlace copyWith({String? name}) => SavedPlace(
        id: id,
        name: name ?? this.name,
        latitude: latitude,
        longitude: longitude,
        createdAt: createdAt,
      );

  /// يُنشئ مكاناً جديداً بمعرّف من الوقت الحالي + عدّاد.
  ///
  /// لا نحتاج مكتبة UUID: المعرّف محلي فقط. لكن الوقت وحده لا يكفي لأن
  /// [DateTime.now] قد يعيد نفس القيمة لمكانين متتاليين، فيُحذف أحدهما
  /// عند الإضافة؛ لذلك نضيف عدّاداً متزايداً.
  factory SavedPlace.create({
    required String name,
    required LatLng point,
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.now();
    return SavedPlace(
      id: '${now.microsecondsSinceEpoch}-${_nextSequence++}',
      name: name,
      latitude: point.latitude,
      longitude: point.longitude,
      createdAt: now,
    );
  }

  static int _nextSequence = 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': latitude,
        'lng': longitude,
        'createdAt': createdAt.toIso8601String(),
      };

  /// يقرأ مكاناً من JSON محفوظ.
  ///
  /// أي بيانات ناقصة أو تالفة تُرفض (`FormatException`) ليتجاهلها التحميل
  /// بدلاً من إسقاط كل القائمة.
  factory SavedPlace.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final lat = json['lat'];
    final lng = json['lng'];
    final createdAtRaw = json['createdAt'];
    final createdAt =
        createdAtRaw is String ? DateTime.tryParse(createdAtRaw) : null;

    if (id is! String ||
        name is! String ||
        lat is! num ||
        lng is! num ||
        createdAt == null) {
      throw const FormatException('بيانات مكان محفوظ غير صالحة');
    }

    return SavedPlace(
      id: id,
      name: name,
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      createdAt: createdAt,
    );
  }
}
