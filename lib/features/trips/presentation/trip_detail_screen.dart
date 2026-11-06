import 'package:flutter/material.dart';

import '../../map/data/map_tile_provider.dart';
import '../data/trips_repository.dart';
import '../domain/trip.dart';
import 'widgets/trip_detail_widgets.dart';
import 'widgets/trip_history_list.dart';

/// تفاصيل رحلة محفوظة: المسار على الخريطة والإحصاءات.
class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({
    super.key,
    required this.trip,
    required this.repository,
  });

  final Trip trip;
  final TripsRepository repository;

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final MapTileProvider _tiles = MapTileProvider();

  List<TripPoint>? _points;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final points = await widget.repository.points(widget.trip.id);
    if (!mounted) return;
    setState(() => _points = points);
  }

  @override
  void dispose() {
    _tiles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final points = _points;

    return Scaffold(
      appBar: AppBar(
        title: Text(formatTripDate(widget.trip.startedAt)),
      ),
      body: points == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                if (points.length >= 2)
                  TripTrackMap(points: points, tiles: _tiles)
                else
                  const TripNoTrackMessage(),
                const SizedBox(height: 16),
                TripStatsCard(trip: widget.trip, points: points),
                const SizedBox(height: 12),
                Text(
                  'المصدر: نقاط GPS المسجّلة على هذا الجهاز أثناء الرحلة. '
                  'قد تختلف المسافة قليلاً عن عدّاد السيارة.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
    );
  }
}
