import '../entities/world_boss.dart';
import '../repositories/world_boss_repository.dart';

/// Business operation: observe the World Boss event.
final class WatchWorldBoss {
  const WatchWorldBoss({required WorldBossRepository repository})
      : _repository = repository;

  final WorldBossRepository _repository;

  Stream<WorldBoss> call() => _repository.watch();
}