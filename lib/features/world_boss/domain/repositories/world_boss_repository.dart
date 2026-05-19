import '../entities/world_boss.dart';

/// Domain-level abstraction over the World Boss event source.
abstract interface class WorldBossRepository {
  /// Live stream of the boss state. Emits whenever the end-time changes.
  Stream<WorldBoss> watch();
}