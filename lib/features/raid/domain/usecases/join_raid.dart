import '../entities/join_outcome.dart';
import '../repositories/raid_repository.dart';

/// Business operation: try to claim a raid slot.
///
/// Thin orchestrator over [RaidRepository.tryJoin]. The atomic-cap rule
/// lives in the repository because it's intrinsically coupled to the
/// transaction primitive; the use case is the named entry point that
/// the presentation layer holds a reference to (so the widget never
/// imports a repository directly).
final class JoinRaid {
  const JoinRaid({required RaidRepository repository})
      : _repository = repository;

  final RaidRepository _repository;

  Future<JoinOutcome> call({required String userId}) {
    return _repository.tryJoin(userId: userId);
  }
}
