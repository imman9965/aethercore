import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../domain/entities/chat_message.dart';
import '../domain/repositories/chat_repository.dart';

/// Firestore-backed [ChatRepository].
///
/// Schema: `chat_shards/{shard}/messages/{auto-id}` — the shard layer is
/// the scaling lever. At demo scale we run a single `global` shard. To
/// scale, raise [_shardCount] and replace [_shardFor] with a true
/// hash-bucket; reads pick one shard per user, writes round-robin.
/// Reads are clamped with `limitToLast` so per-session cost is bounded
/// regardless of message volume.
final class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const int _messageWindow = 50;
  // At demo scale, a single global shard. Wired through `_shardFor` so
  // promotion to N shards is a one-line change.
  static const int _shardCount = 1;
  static const String _shardPrefix = 'global';

  String _shardFor(String userId) {
    if (_shardCount <= 1) {
      return _shardPrefix;
    }
    final int bucket = userId.hashCode.abs() % _shardCount;
    return '${_shardPrefix}_$bucket';
  }

  CollectionReference<Map<String, dynamic>> _messagesIn(String shard) {
    return _firestore
        .collection('chat_shards')
        .doc(shard)
        .collection('messages');
  }

  @override
  Stream<List<ChatMessage>> watchRecent({required String forUserId}) {
    return _messagesIn(_shardFor(forUserId))
        .orderBy('createdAt')
        .limitToLast(_messageWindow)
        .snapshots()
        .map(_mapDocs);
  }

  List<ChatMessage> _mapDocs(QuerySnapshot<Map<String, dynamic>> snap) {
    return snap.docs
        .map(_mapDoc)
        .toList(growable: false);
  }

  ChatMessage _mapDoc(DocumentSnapshot<Map<String, dynamic>> snap) {
    final Map<String, dynamic> data =
        snap.data() ?? const <String, dynamic>{};
    return ChatMessage(
      id: snap.id,
      uid: (data['uid'] as String?) ?? 'unknown',
      text: (data['text'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  Future<Result<void>> send({
    required String uid,
    required String text,
  }) async {
    try {
      await _messagesIn(_shardFor(uid)).add(<String, Object>{
        'uid': uid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(
        InfrastructureFailure('Failed to send message.', cause: e),
      );
    }
  }
}
