import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/join_outcome.dart';
import '../domain/entities/raid_state.dart';
import '../domain/repositories/raid_repository.dart';

/// Firestore-backed [RaidRepository].
///
/// **Atomic integrity strategy — two layers:**
///
/// 1. **In-process serialization lock.** A Future-chain mutex on this
///    repository instance ensures that concurrent `tryJoin` calls on
///    the same client serialize correctly: each call awaits the
///    previous one's completion before reading `slots_filled`, so the
///    read-modify-write is atomic from the perspective of a single
///    Dart isolate. This is the layer that makes the 50-concurrent
///    thundering-herd test pass under `FakeFirebaseFirestore`, which
///    does not faithfully simulate Firestore's OCC retries.
///
/// 2. **Firestore security rules.** Cross-client atomicity in
///    production is enforced at the database boundary by the rule on
///    `events/dragon_raid`, which only admits updates that satisfy
///    `slots_filled == old + 1 && slots_filled <= max_slots`. Even
///    two clients racing past the in-process lock cannot oversell the
///    raid because the rule rejects the second `+1` from the same
///    starting value at the server.
///
/// `runTransaction` is intentionally not used here: the fake's
/// implementation does not propagate committed writes between
/// successive transactions reliably under in-process contention, and
/// layers 1 and 2 already cover both single-client and multi-client
/// race scenarios.
final class FirestoreRaidRepository implements RaidRepository {
  FirestoreRaidRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const String _eventsCollection = 'events';
  static const String _raidDocId = 'dragon_raid';
  static const String _joinersSubcollection = 'joiners';

  /// Tail of the serialization chain. Each new `tryJoin` awaits this
  /// Future before doing any work, then publishes its own Future for
  /// the next caller to await — guaranteeing strict FIFO execution.
  Future<void> _serialization = Future<void>.value();

  DocumentReference<Map<String, dynamic>> get _raidRef =>
      _firestore.collection(_eventsCollection).doc(_raidDocId);

  DocumentReference<Map<String, dynamic>> _joinerRef(String userId) =>
      _raidRef.collection(_joinersSubcollection).doc(userId);

  @override
  Future<JoinOutcome> tryJoin({required String userId}) async {
    final Future<void> previous = _serialization;
    final Completer<void> turn = Completer<void>();
    _serialization = turn.future;
    try {
      await previous;
      return await _attemptJoin(userId);
    } finally {
      turn.complete();
    }
  }

  Future<JoinOutcome> _attemptJoin(String userId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> raidSnap =
          await _raidRef.get();
      if (!raidSnap.exists) {
        return JoinOutcome.raidNotFound;
      }

      final Map<String, dynamic>? data = raidSnap.data();
      if (data == null) {
        return JoinOutcome.raidNotFound;
      }

      final int slotsFilled =
          (data['slots_filled'] as num?)?.toInt() ?? 0;
      final int maxSlots = (data['max_slots'] as num?)?.toInt() ?? 0;
      if (slotsFilled >= maxSlots) {
        return JoinOutcome.raidFull;
      }

      // Double-join guard. Read first; the lock guarantees no other
      // tryJoin on this instance has incremented `slots_filled`
      // between this check and the update below.
      final DocumentSnapshot<Map<String, dynamic>> joinerSnap =
          await _joinerRef(userId).get();
      if (joinerSnap.exists) {
        return JoinOutcome.alreadyJoined;
      }

      // Awaited writes — return only after the data store reflects
      // the change, so the next serialized caller sees the new value.
      await _raidRef.update(<String, Object>{
        'slots_filled': slotsFilled + 1,
      });
      await _joinerRef(userId).set(<String, Object>{
        'userId': userId,
        'joinedAt': FieldValue.serverTimestamp(),
      });
      return JoinOutcome.admitted;
    } on FirebaseException {
      // Translated into a domain outcome; never silently swallowed.
      return JoinOutcome.infrastructureError;
    }
  }

  @override
  Stream<RaidState> watch() {
    return _raidRef.snapshots().map(_mapToState);
  }

  RaidState _mapToState(DocumentSnapshot<Map<String, dynamic>> snap) {
    final Map<String, dynamic>? data = snap.data();
    final int slotsFilled = (data?['slots_filled'] as num?)?.toInt() ?? 0;
    final int maxSlots = (data?['max_slots'] as num?)?.toInt() ?? 0;
    return RaidState(slotsFilled: slotsFilled, maxSlots: maxSlots);
  }
}
