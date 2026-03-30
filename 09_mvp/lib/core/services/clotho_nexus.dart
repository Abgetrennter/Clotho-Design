import 'dart:async';

/// Clotho 事件基类
abstract class ClothoEvent {
  final DateTime timestamp;
  final String sessionId;

  ClothoEvent({
    required this.timestamp,
    required this.sessionId,
  });
}

/// 生成开始事件
class GenerationStartedEvent extends ClothoEvent {
  final String turnId;

  GenerationStartedEvent({
    required super.sessionId,
    required this.turnId,
  }) : super(timestamp: DateTime.now());
}

/// 消息接收事件（用于流式输出）
class MessageReceivedEvent extends ClothoEvent {
  final String turnId;
  final String content;
  final bool isFinal;

  MessageReceivedEvent({
    required super.sessionId,
    required this.turnId,
    required this.content,
    this.isFinal = false,
  }) : super(timestamp: DateTime.now());
}

/// 回合完成事件
class TurnCompletedEvent extends ClothoEvent {
  final String turnId;

  TurnCompletedEvent({
    required super.sessionId,
    required this.turnId,
  }) : super(timestamp: DateTime.now());
}

/// 生成错误事件
class GenerationErrorEvent extends ClothoEvent {
  final String error;

  GenerationErrorEvent({
    required super.sessionId,
    required this.error,
  }) : super(timestamp: DateTime.now());
}

/// ClothoNexus - 事件总线
///
/// 统一事件发布和订阅机制
/// 对应设计文档 4.5.3 节
class ClothoNexus {
  final _eventController = StreamController<ClothoEvent>.broadcast();
  bool _disposed = false;

  /// 发布事件
  void publish(ClothoEvent event) {
    if (!_disposed) {
      _eventController.add(event);
    }
  }

  /// 订阅特定类型的事件
  Stream<T> on<T extends ClothoEvent>() {
    return _eventController.stream.where((event) => event is T).cast<T>();
  }

  /// 订阅所有事件
  Stream<ClothoEvent> get allEvents => _eventController.stream;

  /// 释放资源
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      _eventController.close();
    }
  }
}
