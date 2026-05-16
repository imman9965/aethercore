import '../entities/join_outcome.dart';
import '../entities/raid_state.dart';

/// Domain-level abstraction over raid persistence.
///
/// Implementations live in the data layer. The domain depends only on
/// this interface — swapping Firestore for a different backend would
/// touch zero domain or presentation code.
abstract interface class RaidRepository {
  /// Atomically claim a slot for [userId]. Implementations MUST use a
  /// transaction so 50 concurrent calls see exactly `max_slots` admits.
  Future<JoinOutcome> tryJoin({required String userId});

  /// Live snapshot of the raid headcount.
  Stream<RaidState> watch();
}
