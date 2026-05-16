import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/world_boss.dart';
import '../domain/repositories/world_boss_repository.dart';

/// Firestore-backed [WorldBossRepository].
///
/// One snapshot listener on a single document. The 100 ms client-side
/// tick (see `BossCountdownController`) derives a `Duration` locally
/// from the cached end-time, so the user perceives a smooth 10 Hz
/// countdown without spending a single extra read.
final class FirestoreWorldBossRepository implements WorldBossRepository {
  FirestoreWorldBossRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const String _collection = 'events';
  static const String _docId = 'world_boss';

  @override
  Stream<WorldBoss> watch() {
    return _firestore
        .collection(_collection)
        .doc(_docId)
        .snapshots()
        .where(_hasEndTime)
        .map(_mapToEntity);
  }

  bool _hasEndTime(DocumentSnapshot<Map<String, dynamic>> snap) {
    return snap.data()?['boss_end_time'] is Timestamp;
  }

  WorldBoss _mapToEntity(DocumentSnapshot<Map<String, dynamic>> snap) {
    final Timestamp ts = snap.data()!['boss_end_time'] as Timestamp;
    return WorldBoss(endTime: ts.toDate());
  }
}
