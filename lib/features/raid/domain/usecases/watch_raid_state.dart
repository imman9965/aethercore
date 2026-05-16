import '../entities/raid_state.dart';
import '../repositories/raid_repository.dart';

/// Business operation: observe the live raid headcount.
final class WatchRaidState {
  const WatchRaidState({required RaidRepository repository})
      : _repository = repository;

  final RaidRepository _repository;

  Stream<RaidState> call() => _repository.watch();
}
