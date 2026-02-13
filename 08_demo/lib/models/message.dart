/// 消息模型
library;

/// 消息发送者类型
enum MessageSender {
  /// 用户
  user,
  /// 角色/系统
  character,
  /// 系统/助手
  system,
}

/// 消息状态
enum MessageStatus {
  /// 发送中
  sending,
  /// 已发送
  sent,
  /// 已接收
  received,
  /// 失败
  failed,
}

/// 消息模型
class Message {
  const Message({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.avatarUrl,
    this.isGenerating = false,
  });

  final String id;
  final MessageSender sender;
  final String content;
  final DateTime timestamp;
  final MessageStatus status;
  final String? avatarUrl;
  final bool isGenerating;

  /// 创建用户消息
  factory Message.user({
    required String id,
    required String content,
    String? avatarUrl,
  }) {
    return Message(
      id: id,
      sender: MessageSender.user,
      content: content,
      timestamp: DateTime.now(),
      avatarUrl: avatarUrl,
    );
  }

  /// 创建角色消息
  factory Message.character({
    required String id,
    required String content,
    String? avatarUrl,
    bool isGenerating = false,
  }) {
    return Message(
      id: id,
      sender: MessageSender.character,
      content: content,
      timestamp: DateTime.now(),
      avatarUrl: avatarUrl,
      isGenerating: isGenerating,
    );
  }

  /// 创建系统消息
  factory Message.system({
    required String id,
    required String content,
  }) {
    return Message(
      id: id,
      sender: MessageSender.system,
      content: content,
      timestamp: DateTime.now(),
    );
  }
}
