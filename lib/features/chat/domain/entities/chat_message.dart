/// A single chat message. Pure domain — no Firebase types here.
final class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.uid,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String uid;
  final String text;
  final DateTime? createdAt;
}
