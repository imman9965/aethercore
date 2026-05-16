import '../../../../core/result/result.dart';
import '../entities/chat_message.dart';

/// Domain-level abstraction over the chat message store.
///
/// The "sharding" decision (one shard, hash-bucketed, fan-out, etc.) is
/// an implementation concern hidden behind this interface — domain
/// callers only ask "watch my chat" and "send a message".
abstract interface class ChatRepository {
  /// Live tail of recent messages. Implementations MUST cap the working
  /// set (e.g. via `limitToLast`) so read cost is bounded per session.
  Stream<List<ChatMessage>> watchRecent({required String forUserId});

  /// Persist a message authored by [uid]. Returns a typed result so the
  /// caller knows whether to surface a UI error.
  Future<Result<void>> send({required String uid, required String text});
}
