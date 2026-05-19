import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/entities/world_boss.dart';
import '../domain/repositories/world_boss_repository.dart';

/// Firestore-backed [WorldBossRepository] — strictly Firebase-driven.
///
/// Subscribes once to `events/world_boss`. Only emits a [WorldBoss]
/// when the snapshot contains a valid `boss_end_time` (Timestamp).
/// Snapshots with missing/wrong-type fields are filtered out — the
/// controller stays without an `_endTime` and the UI shows 00:00.0
/// until valid Firebase data arrives. No synthetic fallback.
///
/// **Robust key lookup:** the data layer trims whitespace and
/// lower-cases field keys before matching, so `"boss_end_time  "`
/// (trailing spaces) or `"Boss_End_Time"` still resolve. Loud warnings
/// fire when malformed keys are detected so the data can be cleaned
/// up in the Console.
final class FirestoreWorldBossRepository implements WorldBossRepository {
  FirestoreWorldBossRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const String _collection = 'events';
  static const String _docId = 'world_boss';

  @override
  Stream<WorldBoss> watch() {
    debugPrint('[boss-repo] Subscribing to events/world_boss');
    return _firestore
        .collection(_collection)
        .doc(_docId)
        .snapshots()
        .where(_hasValidEndTime)
        .map(_mapToEntity);
  }

  /// Filter: only let through snapshots that have a valid
  /// `boss_end_time` Timestamp (whitespace in the key is tolerated).
  bool _hasValidEndTime(DocumentSnapshot<Map<String, dynamic>> snap) {
    final Map<String, dynamic>? data = snap.data();
    debugPrint(
      '[boss-repo] snapshot exists=${snap.exists} data=$data',
    );
    if (data == null) {
      debugPrint(
        '[boss-repo] doc does not exist — no emission. '
        'Create events/world_boss in the Console.',
      );
      return false;
    }

    _warnIfMalformedKeys(data);

    final Timestamp? ts = _findTimestamp(data, 'boss_end_time');
    if (ts == null) {
      debugPrint(
        '[boss-repo] boss_end_time missing or wrong type — no emission. '
        'Field must be named exactly "boss_end_time" and stored as '
        'timestamp (whitespace in the name is tolerated).',
      );
      return false;
    }
    return true;
  }

  WorldBoss _mapToEntity(DocumentSnapshot<Map<String, dynamic>> snap) {
    final Map<String, dynamic> data = snap.data()!;
    final Timestamp ts = _findTimestamp(data, 'boss_end_time')!;
    final DateTime endTime = ts.toDate();
    final String bossName = _findString(data, 'boss_name') ?? 'Grok';

    debugPrint(
      '[boss-repo] emit endTime=$endTime bossName=$bossName',
    );
    return WorldBoss(endTime: endTime, bossName: bossName);
  }

  /// Tolerant Timestamp lookup. Trims whitespace and lower-cases each
  /// key before matching — the defensive shield against
  /// `"boss_end_time  "` data-quality bugs.
  Timestamp? _findTimestamp(Map<String, dynamic> data, String wantedKey) {
    final String target = wantedKey.toLowerCase();
    for (final MapEntry<String, dynamic> entry in data.entries) {
      final String cleanKey = entry.key.trim().toLowerCase();
      if (cleanKey == target && entry.value is Timestamp) {
        return entry.value as Timestamp;
      }
    }
    return null;
  }

  /// Tolerant String lookup. Same approach as [_findTimestamp].
  String? _findString(Map<String, dynamic> data, String wantedKey) {
    final String target = wantedKey.toLowerCase();
    for (final MapEntry<String, dynamic> entry in data.entries) {
      final String cleanKey = entry.key.trim().toLowerCase();
      if (cleanKey == target) {
        final Object? v = entry.value;
        if (v is String) return v;
      }
    }
    return null;
  }

  /// Loud warning when a field key has surrounding whitespace — the
  /// silent-failure trap that's caused us trouble before.
  void _warnIfMalformedKeys(Map<String, dynamic> data) {
    for (final String key in data.keys) {
      if (key != key.trim()) {
        debugPrint(
          '[boss-repo] MALFORMED FIELD KEY: '
          '"${key.replaceAll(' ', '_')}" '
          '(${key.length} chars, expected ${key.trim().length}). '
          'Rename this field in Firebase Console.',
        );
      }
    }
  }
}
