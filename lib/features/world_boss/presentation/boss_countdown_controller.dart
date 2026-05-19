import 'dart:async';
import '../domain/entities/world_boss.dart';
import '../domain/usecases/watch_world_boss.dart';

/// Stream-based boss countdown controller — strictly Firebase-backed.
///
/// Pipeline:
///   Firestore stream (events/world_boss) ─► _endTime cache
///   Timer.periodic(100 ms) ─► emits (endTime − now()) on `remaining`
///   `StreamBuilder<Duration>` rebuilds the digits at 10 Hz
///
/// No synthetic fallback. Until Firestore delivers a valid
/// `boss_end_time`, the stream emits nothing and the UI shows the
/// `StreamBuilder`'s `initialData` (00:00.0). This matches the
/// Project Aether brief — the timer is Firestore-driven.
final class BossCountdownController {
  BossCountdownController({required WatchWorldBoss watchWorldBoss})
      : _watchWorldBoss = watchWorldBoss;

  final WatchWorldBoss _watchWorldBoss;

  static const Duration _tick = Duration(milliseconds: 100);

  final StreamController<Duration> _remainingCtrl =
      StreamController<Duration>.broadcast();

  DateTime? _endTime;
  Timer? _ticker;
  StreamSubscription<WorldBoss>? _sub;

  /// Live countdown stream. Emits `firebase_end_time − DateTime.now()`
  /// at 10 Hz once the repository has delivered a valid `WorldBoss`.
  /// Clamped at `Duration.zero` once the boss-end moment has passed.
  Stream<Duration> get remaining => _remainingCtrl.stream;

  /// Begin streaming the boss state and ticking the local countdown.
  /// Idempotent — subsequent calls are no-ops.
  ///
  /// The 100 ms ticker is created lazily on the first boss snapshot
  /// (see [_onBossUpdate]) rather than here. Observable behaviour is
  /// unchanged because [_emit] already short-circuits while
  /// `_endTime == null`, but we no longer burn 10 wake-ups per second
  /// between app start and the first Firestore delivery.
  void start() {
    if (_sub != null) return;

    // Print('[boss] start() — subscribing to events/world_boss');

    _sub = _watchWorldBoss().listen(
      _onBossUpdate,
      // onError: (Object e, StackTrace s) =>
      //     debugPrint('[boss] STREAM ERROR: $e'),
    );
  }

  void _onBossUpdate(WorldBoss boss) {
    // debugPrint(
    //   '[boss] snapshot received — ${boss.bossName} endTime=${boss.endTime}',
    // );
    _endTime = boss.endTime;
    // Lazy ticker start: only spin up the periodic timer once we
    // actually have an end-time to count down to. `??=` keeps this
    // idempotent across subsequent snapshots (boss reset, new event).
    _ticker ??= Timer.periodic(_tick, (_) => _emit());
    _emit();
  }

  /// Computes `firebase_end_time − DateTime.now()` and pushes onto the
  /// stream. No-op while no end-time is known yet — UI sticks at
  /// initialData (00:00.0) until Firestore delivers.
  void _emit() {
    final DateTime? endTime = _endTime;
    if (endTime == null) return;

    final Duration diff = endTime.difference(DateTime.now());
    final Duration value = diff.isNegative ? Duration.zero : diff;
    if (!_remainingCtrl.isClosed) {
      _remainingCtrl.add(value);
    }
  }

  /// Tears down the subscription, ticker, and stream.
  /// Must be called from the host widget's `dispose()`.
  Future<void> dispose() async {
    _ticker?.cancel();
    _ticker = null;
    await _sub?.cancel();
    _sub = null;
    await _remainingCtrl.close();
  }
}
