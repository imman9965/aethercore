import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/entities/join_outcome.dart';
import '../domain/entities/raid_state.dart';
import '../domain/repositories/raid_repository.dart';

final class FirestoreRaidRepository implements RaidRepository {
  FirestoreRaidRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const String _eventsCollection = 'events';
  static const String _raidDocId = 'dragon_raid';
  static const String _joinersSubcollection = 'joiners';

  /// Serialization lock to prevent concurrent calls from the same device
  Future<void> _serialization = Future<void>.value();

  DocumentReference<Map<String, dynamic>> get _raidRef =>
      _firestore.collection(_eventsCollection).doc(_raidDocId);

  DocumentReference<Map<String, dynamic>> _joinerRef(String userId) =>
      _raidRef.collection(_joinersSubcollection).doc(userId);

  @override
  Future<JoinOutcome> tryJoin({required String userId}) async {
    debugPrint('🔄 [raid-repo] tryJoin called for: $userId');

    final previous = _serialization;
    final completer = Completer<void>();
    _serialization = completer.future;

    try {
      await previous;
      return await _attemptJoin(userId);
    } finally {
      completer.complete();
    }
  }

  /// Main join logic using **Firestore Transaction** (Recommended)
  Future<JoinOutcome> _attemptJoin(String userId) async {
    try {
      return await _firestore.runTransaction<JoinOutcome>((transaction) async {
        debugPrint('🔄 Transaction started for user: $userId');

        final raidSnap = await transaction.get(_raidRef);

        if (!raidSnap.exists) {
          debugPrint('❌ Raid document does not exist');
          return JoinOutcome.raidNotFound;
        }

        final data = raidSnap.data() ?? {};
        final parsed = _parseRaidData(data);

        debugPrint('📊 Current slots_filled: ${parsed.slots} | maxSlots: ${parsed.max}');

        if (parsed.max > 0 && parsed.slots >= parsed.max) {
          return JoinOutcome.raidFull;
        }

        // Double-check already joined
        final joinerSnap = await transaction.get(_joinerRef(userId));
        if (joinerSnap.exists) {
          return JoinOutcome.alreadyJoined;
        }

        // === CRITICAL: Use FieldValue.increment for safer updates ===
        transaction.update(_raidRef, {
          'slots_filled': FieldValue.increment(1),
        });

        transaction.set(_joinerRef(userId), {
          'userId': userId,
          'joinedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Transaction updates prepared');
        return JoinOutcome.admitted;
      });
    } on FirebaseException catch (e) {
      debugPrint('🔥 Firebase Error: ${e.code} - ${e.message}');

      if (e.code == 'permission-denied') {
        debugPrint('🚫 PERMISSION DENIED → Check your Security Rules!');
      } else if (e.code == 'not-found') {
        debugPrint('❌ Document not found');
      } else if (e.code == 'aborted') {
        debugPrint('⚔️ Transaction aborted (concurrent modification)');
        return JoinOutcome.raidFull;
      }

      return JoinOutcome.infrastructureError;
    } catch (e, stack) {
      debugPrint('❌ Unexpected error: $e\n$stack');
      return JoinOutcome.infrastructureError;
    }
  }
  /// Helper to safely parse raid data (handles messy field names)
  ({int slots, int max}) _parseRaidData(Map<String, dynamic> data) {
    int slotsFilled = 0;
    int maxSlots = 0;

    for (var entry in data.entries) {
      final cleanKey = entry.key.trim().toLowerCase();
      final value = entry.value;

      if (cleanKey == 'slots_filled' || cleanKey == 'slotsfilled') {
        slotsFilled = (value as num?)?.toInt() ?? 0;
      } else if (cleanKey.contains('max_slot') ||
          cleanKey == 'maxslots' ||
          cleanKey.contains('max')) {
        maxSlots = (value as num?)?.toInt() ?? 0;
      }
    }

    return (slots: slotsFilled, max: maxSlots);
  }

  @override
  Stream<RaidState> watch() {
    debugPrint('[raid-repo] Subscribing to events/dragon_raid');

    return _raidRef.snapshots().map(_mapToState);
  }

  RaidState _mapToState(DocumentSnapshot<Map<String, dynamic>> snap) {
    if (!snap.exists) {
      return const RaidState(slotsFilled: 0, maxSlots: 0);
    }

    final data = snap.data() ?? {};
    final parsed = _parseRaidData(data);

    debugPrint('[raid-repo] Updated → slotsFilled: ${parsed.slots} / max: ${parsed.max}');

    return RaidState(
      slotsFilled: parsed.slots,
      maxSlots: parsed.max,
    );
  }
}