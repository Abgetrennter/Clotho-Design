import 'package:flutter/material.dart';

import '../../mnemosyne/models/message.dart';
import '../../mnemosyne/models/turn.dart';
import 'message_bubble.dart';

/// MessageList - 消息列表组件
///
/// 展示所有对话历史消息
class MessageList extends StatelessWidget {
  final List<Turn> turns;
  final ScrollController? scrollController;
  final bool isLoading;

  const MessageList({
    super.key,
    required this.turns,
    this.scrollController,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // 提取所有消息（按时间顺序）
    final messages = <Message>[];
    for (final turn in turns) {
      messages.addAll(turn.messages.where((m) => m.isActive));
    }

    if (messages.isEmpty && !isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '开始对话吧！',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      itemCount: messages.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && isLoading) {
          // 加载中指示器
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.smart_toy, color: Colors.white),
                ),
                SizedBox(width: 8),
                CircularProgressIndicator(strokeWidth: 2),
              ],
            ),
          );
        }

        final message = messages[index];
        return MessageBubble(
          message: message,
          isThinking: isLoading && index == messages.length - 1,
        );
      },
    );
  }
}
