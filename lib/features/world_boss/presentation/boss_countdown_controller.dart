import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/entities/world_boss.dart';
import '../domain/usecases/watch_world_boss.dart';


final class BossCountdownController {
  BossCountdownController({required WatchWorldBoss watchWorldBoss})
      : _watchWorldBoss = watchWorldBoss;

  final WatchWorldBoss _watchWorldBoss;

  static const Duration _tickInterval = Duration(milliseconds: 100);

  /// If Firestore stays silent for this long after [start], seed a
  /// synthetic end-time so the timer always animates. A real snapshot
  /// arriving later overrides the synthetic value transparently.
  static const Duration _fallbackGrace = Duration(seconds: 3);

  /// Synthetic countdown length when the fallback fires.
  static const Duration _fallbackCountdown = Duration(minutes: 5);

  final ValueNotifier<Duration> _remaining =
      ValueNotifier<Duration>(Duration.zero);

  DateTime? _endTime;
  Timer? _ticker;
  Timer? _fallbackTimer;
  StreamSubscription<WorldBoss>? _subscription;

  /// Live countdown duration. Bind via `ValueListenableBuilder`.
  ValueListenable<Duration> get remaining => _remaining;

  /// Begin streaming the boss state and ticking the local countdown.
  /// Idempotent — subsequent calls are no-ops.
  void start() {
    if (_subscription != null) {
      return;
    }
    debugPrint('[boss] start() — subscribing to events/world_boss');
    _subscription = _watchWorldBoss().listen(
      _onBoss,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[boss] STREAM ERROR: $error');
      },
    );
    _ticker = Timer.periodic(_tickInterval, _onTick);
    // Fallback so the timer always animates even if Firestore is silent.
    _fallbackTimer = Timer(_fallbackGrace, _seedFallbackIfNeeded);
  }

  void _seedFallbackIfNeeded() {
    if (_endTime != null) {
      return;
    }
    final DateTime synthetic = DateTime.now().add(_fallbackCountdown);
    debugPrint(
      '[boss] FALLBACK — no snapshot in ${_fallbackGrace.inSeconds}s, '
      'using synthetic endTime=$synthetic',
    );
    _endTime = synthetic;
    _onTick(_ticker);
  }

  void _onBoss(WorldBoss boss) {
    debugPrint('[boss] snapshot received — endTime=${boss.endTime}');
    _endTime = boss.endTime;
    // Real data wins. Cancel any pending fallback.
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    _onTick(_ticker);
  }

  void _onTick(Timer? _) {
    final DateTime? endTime = _endTime;
    if (endTime == null) {
      return;
    }
    _remaining.value = WorldBoss(endTime: endTime)
        .remainingFrom(DateTime.now());
  }

  /// Tears down the subscription, ticker, and notifier. Must be called
  /// from the host widget's `dispose()`.
  Future<void> dispose() async {
    _ticker?.cancel();
    _ticker = null;
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    _remaining.dispose();
  }
}
