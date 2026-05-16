import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../repositories/chat_repository.dart';

/// Business operation: send a chat message, with input validation.
///
/// The validation rule (non-empty, length cap) lives here rather than
/// in the repository because it's a business rule, not a persistence
/// concern. The data layer also enforces it via Firestore security
/// rules as defence-in-depth.
final class SendMessage {
  const SendMessage({required ChatRepository repository})
      : _repository = repository;

  final ChatRepository _repository;

  static const int _maxLength = 280;

  Future<Result<void>> call({
    required String uid,
    required String text,
  }) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const Err<void>(ValidationFailure('Message cannot be empty.'));
    }
    if (trimmed.length > _maxLength) {
      return const Err<void>(
          ValidationFailure('Message exceeds 280 characters.'));
    }
    return _repository.send(uid: uid, text: trimmed);
  }
}
