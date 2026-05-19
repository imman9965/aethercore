final class WorldBoss {
  const WorldBoss({required this.endTime, this.bossName = 'Grok'});

  final DateTime endTime;
  final String bossName;

  Duration remainingFrom(DateTime now) {
    final diff = endTime.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get isActive => endTime.isAfter(DateTime.now());
}