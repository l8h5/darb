import 'dart:async';

import 'package:flutter/material.dart';

import '../../settings/presentation/preferences_scope.dart';
import '../data/trip_recorder.dart';
import '../data/trips_repository.dart';
import '../domain/trip.dart';
import 'trip_detail_screen.dart';
import 'widgets/trip_active_panel.dart';
import 'widgets/trip_history_list.dart';
import 'widgets/trip_status_cards.dart';

/// تبويب الرحلات: تسجيل مسار في المقدمة فقط، وسجل محلي.
class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  late final TripsRepository _repository;
  late final TripRecorder _recorder;

  List<Trip> _trips = const [];
  bool _loading = true;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _repository = TripsRepository();
    _recorder = TripRecorder(repository: _repository);
    _init();
  }

  Future<void> _init() async {
    await _recorder.restore();
    await _reload();
    if (!mounted) return;

    // تحديث المدة المعروضة كل ثانية أثناء التسجيل فقط.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _recorder.isRecording) setState(() {});
    });
  }

  Future<void> _reload() async {
    final trips = await _repository.history();
    if (!mounted) return;
    setState(() {
      _trips = trips;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    unawaited(_repository.close());
    super.dispose();
  }

  Future<void> _start() async {
    final started = await _recorder.start();
    if (!mounted || started) return;
    _showMessage(_recorder.errorMessage ?? 'تعذّر بدء التسجيل.');
  }

  Future<void> _finish() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إنهاء الرحلة؟'),
        content: Text(
          _recorder.pointCount < 2
              ? 'لم تُسجَّل نقاط كافية لرسم مسار. سيُحفظ ما لديك على أي حال.'
              : 'سيُحفظ المسار والمسافة على جهازك، ويمكنك عرضه من السجل.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('متابعة التسجيل'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('إنهاء'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final finished = await _recorder.finish();
    if (!mounted) return;

    await _reload();
    if (!mounted) return;
    _showMessage(
      finished == null ? 'تعذّر إنهاء الرحلة.' : 'تم حفظ الرحلة في سجلك.',
    );
  }

  Future<void> _delete(Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الرحلة؟'),
        content: const Text('سيُحذف المسار ونقاطه من جهازك نهائياً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _repository.delete(trip.id);
    await _reload();
    if (!mounted) return;
    _showMessage('تم حذف الرحلة.');
  }

  void _open(Trip trip) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripDetailScreen(
          trip: trip,
          repository: _repository,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final prefs = PreferencesScope.of(context).preferences;

    return Scaffold(
      appBar: AppBar(title: const Text('رحلاتي')),
      body: ListenableBuilder(
        listenable: _recorder,
        builder: (context, _) {
          final recorder = _recorder;

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                if (recorder.errorMessage != null) ...[
                  TripErrorCard(
                    message: recorder.errorMessage!,
                    onDismiss: recorder.clearError,
                  ),
                  const SizedBox(height: 12),
                ],
                if (recorder.hasActiveTrip)
                  TripActivePanel(
                    recorder: recorder,
                    distanceUnit: prefs.distanceUnit,
                    onPause: recorder.pause,
                    onResume: recorder.resume,
                    onFinish: _finish,
                  )
                else
                  TripStartCard(
                    busy: recorder.busy,
                    onStart: _start,
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'الرحلات السابقة',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (_trips.isNotEmpty)
                      Text(
                        '${_trips.length}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  TripHistoryList(
                    trips: _trips,
                    distanceUnit: prefs.distanceUnit,
                    onOpen: _open,
                    onDelete: _delete,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
