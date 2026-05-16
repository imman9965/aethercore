/// Snapshot of the World Boss state — just the absolute end-time.
///
/// The 100 ms tick is derived client-side from this; we never poll
/// Firestore at 10 Hz.
final class WorldBoss {
  const WorldBoss({required this.endTime});

  final DateTime endTime;

  Duration remainingFrom(DateTime now) {
    final Duration diff = endTime.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }
}
