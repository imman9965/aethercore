import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

/// Business operation: observe the live tail of chat messages.
final class WatchChat {
  const WatchChat({required ChatRepository repository})
      : _repository = repository;

  final ChatRepository _repository;

  Stream<List<ChatMessage>> call({required String userId}) {
    return _repository.watchRecent(forUserId: userId);
  }
}
