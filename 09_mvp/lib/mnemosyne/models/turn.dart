import 'message.dart';

/// Turn - 回合数据模型
///
/// 最小的完整叙事单元
/// v1.1 Turn-Centric 架构核心
/// 对应设计文档 4.3.1 节
class Turn {
  final String id;
  final String sessionId;
  final int index;
  final DateTime createdAt;
  final List<Message> messages;

  // MVP 简化：不包含以下字段
  // final String summary;
  // final String vectorId;
  // final StateSnapshot? stateSnapshot;

  const Turn({
    required this.id,
    required this.sessionId,
    required this.index,
    required this.createdAt,
    required this.messages,
  });

  /// 从 JSON 创建 Turn
  factory Turn.fromJson(Map<String, dynamic> json) => Turn(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        index: json['index'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        messages: (json['messages'] as List<dynamic>)
            .map((m) => Message.fromJson(m as Map<String, dynamic>))
            .toList(),
      );

  /// 转换为 JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'index': index,
        'createdAt': createdAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  /// 创建副本
  Turn copyWith({
    String? id,
    String? sessionId,
    int? index,
    DateTime? createdAt,
    List<Message>? messages,
  }) {
    return Turn(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      index: index ?? this.index,
      createdAt: createdAt ?? this.createdAt,
      messages: messages ?? this.messages,
    );
  }

  /// 获取用户消息
  Message? get userMessage =>
      messages.firstWhereOrNull((m) => m.role == MessageRole.user);

  /// 获取助手消息
  Message? get assistantMessage =>
      messages.firstWhereOrNull((m) => m.role == MessageRole.assistant);

  @override
  String toString() => 'Turn(id: $id, sessionId: $sessionId, index: $index)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Turn &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sessionId == other.sessionId &&
          index == other.index &&
          createdAt == other.createdAt &&
          _listsEqual(messages, other.messages);

  bool _listsEqual(List<Message> a, List<Message> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        sessionId,
        index,
        createdAt,
        messages.hashCode,
      );
}

/// List 扩展方法：firstWhereOrNull
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
