import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/entities/world_boss.dart';
import '../domain/usecases/watch_world_boss.dart';

/// Drives the 100 ms countdown UI.
///
/// One snapshot listener (via [WatchWorldBoss]) supplies the absolute
/// end-time; a local `Timer.periodic(100ms)` recomputes the remaining
/// duration from `DateTime.now()`. Exposes a [ValueListenable] so the
/// widget can rebuild only its timer text via `ValueListenableBuilder`
/// inside a `RepaintBoundary` — the rest of the screen never sees a
/// 10 Hz frame.
final class BossCountdownController {
  BossCountdownController({required WatchWorldBoss watchWorldBoss})
      : _watchWorldBoss = watchWorldBoss;

  final WatchWorldBoss _watchWorldBoss;

  static const Duration _tickInterval = Duration(milliseconds: 100);

  final ValueNotifier<Duration> _remaining =
      ValueNotifier<Duration>(Duration.zero);

  DateTime? _endTime;
  Timer? _ticker;
  StreamSubscription<WorldBoss>? _subscription;

  /// Live countdown duration. Bind via `ValueListenableBuilder`.
  ValueListenable<Duration> get remaining => _remaining;

  /// Begin streaming the boss state and ticking the local countdown.
  /// Idempotent — subsequent calls are no-ops.
  void start() {
    if (_subscription != null) {
      return;
    }
    _subscription = _watchWorldBoss().listen(_onBoss);
    _ticker = Timer.periodic(_tickInterval, _onTick);
  }

  void _onBoss(WorldBoss boss) {
    _endTime = boss.endTime;
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
    await _subscription?.cancel();
    _subscription = null;
    _remaining.dispose();
  }
}
