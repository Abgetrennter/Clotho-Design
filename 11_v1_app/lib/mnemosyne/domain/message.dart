enum MessageRole { user, assistant, system }

enum MessageType { text, thought, command }

class Message {
  const Message({
    required this.id,
    required this.turnId,
    required this.role,
    required this.content,
    this.type = MessageType.text,
    this.isActive = true,
    this.meta = const <String, Object?>{},
  });

  final String id;
  final String turnId;
  final MessageRole role;
  final String content;
  final MessageType type;
  final bool isActive;
  final Map<String, Object?> meta;
}
