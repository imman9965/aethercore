import 'package:cloud_firestore/cloud_firestore.dart';

import 'features/raid/data/firestore_raid_repository.dart';
import 'features/raid/domain/entities/join_outcome.dart';
import 'features/raid/domain/usecases/join_raid.dart';

/// Test-facing facade for the raid feature.
///
/// `test/raid_concurrency_test.dart` instantiates this with a
/// `FakeFirebaseFirestore` and calls `joinRaid({userId})`. We keep that
/// surface stable; the actual logic lives behind the domain/data layers
/// (`JoinRaid` use case -> `FirestoreRaidRepository` -> transaction).
///
/// Application code should depend on `JoinRaid` via the [Injector], not
/// on this facade.
class RaidService {
  RaidService({required FirebaseFirestore firestore})
      : _joinRaid = JoinRaid(
          repository: FirestoreRaidRepository(firestore: firestore),
        );

  final JoinRaid _joinRaid;

  /// Returns `true` iff [userId] was admitted to the raid; `false` for
  /// any other outcome (full, already joined, infrastructure error).
  Future<bool> joinRaid({required String userId}) async {
    final JoinOutcome outcome = await _joinRaid(userId: userId);
    return outcome == JoinOutcome.admitted;
  }
}
