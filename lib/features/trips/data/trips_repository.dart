import '../../spots/data/spots_database.dart';
import '../domain/trip.dart';

/// قراءة وكتابة الرحلات في SQLite.
///
/// كل نقطة تُكتب فور وصولها، حتى لا تفقد الرحلة عند إغلاق التطبيق.
class TripsRepository {
  TripsRepository({SpotsDatabase? database})
      : _database = database ?? SpotsDatabase();

  static const String _trips = 'trips';
  static const String _points = 'trip_points';

  final SpotsDatabase _database;

  /// الرحلات المنتهية، الأحدث أولاً.
  Future<List<Trip>> history() async {
    final db = await _database.database;
    final rows = await db.query(
      _trips,
      where: 'ended_at IS NOT NULL',
      orderBy: 'started_at DESC',
    );
    return rows.map(_tripFromRow).toList(growable: false);
  }

  /// الرحلة المفتوحة إن وُجدت.
  Future<Trip?> active() async {
    final db = await _database.database;
    final rows = await db.query(
      _trips,
      where: 'ended_at IS NULL',
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _tripFromRow(rows.first);
  }

  Future<Trip> create({DateTime? startedAt}) async {
    final now = startedAt ?? DateTime.now();
    final trip = Trip(
      id: Trip.createId(now),
      startedAt: now,
      endedAt: null,
      distanceMeters: 0,
      pointCount: 0,
    );

    final db = await _database.database;
    await db.insert(_trips, _tripToRow(trip));
    return trip;
  }

  /// يضيف نقطة ويحدّث مجاميع الرحلة في معاملة واحدة.
  Future<void> appendPoint({
    required String tripId,
    required TripPoint point,
    required double distanceMeters,
    required int pointCount,
  }) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.insert(_points, _pointToRow(tripId, point));
      await txn.update(
        _trips,
        {
          'distance_m': distanceMeters,
          'point_count': pointCount,
        },
        where: 'id = ?',
        whereArgs: [tripId],
      );
    });
  }

  /// يُنهي الرحلة ويحفظ المجاميع النهائية.
  Future<Trip?> finish({
    required String tripId,
    required double distanceMeters,
    required int pointCount,
    DateTime? endedAt,
  }) async {
    final db = await _database.database;
    await db.update(
      _trips,
      {
        'ended_at': (endedAt ?? DateTime.now()).millisecondsSinceEpoch,
        'distance_m': distanceMeters,
        'point_count': pointCount,
      },
      where: 'id = ?',
      whereArgs: [tripId],
    );
    return tripById(tripId);
  }

  Future<Trip?> tripById(String tripId) async {
    final db = await _database.database;
    final rows = await db.query(
      _trips,
      where: 'id = ?',
      whereArgs: [tripId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _tripFromRow(rows.first);
  }

  /// نقاط المسار بالترتيب الزمني.
  Future<List<TripPoint>> points(String tripId) async {
    final db = await _database.database;
    final rows = await db.query(
      _points,
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'recorded_at ASC, id ASC',
    );
    return rows.map(_pointFromRow).toList(growable: false);
  }

  /// حذف رحلة مع نقاطها.
  Future<void> delete(String tripId) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete(_points, where: 'trip_id = ?', whereArgs: [tripId]);
      await txn.delete(_trips, where: 'id = ?', whereArgs: [tripId]);
    });
  }

  Future<void> close() => _database.close();

  Map<String, Object?> _tripToRow(Trip trip) => {
        'id': trip.id,
        'started_at': trip.startedAt.millisecondsSinceEpoch,
        'ended_at': trip.endedAt?.millisecondsSinceEpoch,
        'distance_m': trip.distanceMeters,
        'point_count': trip.pointCount,
      };

  Map<String, Object?> _pointToRow(String tripId, TripPoint point) => {
        'trip_id': tripId,
        'lat': point.latitude,
        'lng': point.longitude,
        'recorded_at': point.recordedAt.millisecondsSinceEpoch,
        'accuracy_m': point.accuracyMeters,
        'speed_mps': point.speedMps,
        'altitude_m': point.altitudeMeters,
      };

  Trip _tripFromRow(Map<String, Object?> row) {
    final ended = row['ended_at'];
    return Trip(
      id: row['id']! as String,
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['started_at']! as num).toInt(),
      ),
      endedAt: ended is num
          ? DateTime.fromMillisecondsSinceEpoch(ended.toInt())
          : null,
      distanceMeters: (row['distance_m']! as num).toDouble(),
      pointCount: (row['point_count']! as num).toInt(),
    );
  }

  TripPoint _pointFromRow(Map<String, Object?> row) {
    double? optional(Object? value) =>
        value is num ? value.toDouble() : null;

    return TripPoint(
      latitude: (row['lat']! as num).toDouble(),
      longitude: (row['lng']! as num).toDouble(),
      recordedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['recorded_at']! as num).toInt(),
      ),
      accuracyMeters: optional(row['accuracy_m']),
      speedMps: optional(row['speed_mps']),
      altitudeMeters: optional(row['altitude_m']),
    );
  }
}
