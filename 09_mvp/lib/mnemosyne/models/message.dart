/// Message - 消息数据模型
///
/// Threads (丝络) 的组成部分
/// 对应设计文档 4.3.1 节
enum MessageRole { user, assistant, system }

enum MessageType { text, thought }

class Message {
  final String id;
  final String turnId;
  final MessageRole role;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isActive;

  const Message({
    required this.id,
    required this.turnId,
    required this.role,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isActive = true,
  });

  /// 从 JSON 创建 Message
  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        turnId: json['turnId'] as String,
        role: MessageRole.values.firstWhere(
          (e) => e.name == json['role'],
          orElse: () => MessageRole.user,
        ),
        content: json['content'] as String,
        type: MessageType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => MessageType.text,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
        isActive: json['isActive'] as bool? ?? true,
      );

  /// 转换为 JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'turnId': turnId,
        'role': role.name,
        'content': content,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'isActive': isActive,
      };

  /// 创建副本
  Message copyWith({
    String? id,
    String? turnId,
    MessageRole? role,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isActive,
  }) {
    return Message(
      id: id ?? this.id,
      turnId: turnId ?? this.turnId,
      role: role ?? this.role,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() => 'Message(id: $id, role: $role, type: $type)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          turnId == other.turnId &&
          role == other.role &&
          content == other.content &&
          type == other.type &&
          timestamp == other.timestamp &&
          isActive == other.isActive;

  @override
  int get hashCode => Object.hash(
        id,
        turnId,
        role,
        content,
        type,
        timestamp,
        isActive,
      );
}
