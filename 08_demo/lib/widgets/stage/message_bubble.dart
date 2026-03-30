/// 消息气泡组件
/// 对应文档: 00_active_specs/presentation/05-message-bubble.md
library;

import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../../theme/design_tokens.dart';

/// 消息气泡组件
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
  });

  final Message message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.sender == MessageSender.user;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(context),
            const SizedBox(width: SpacingTokens.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: SpacingTokens.xs),
                _buildContent(context),
                if (message.isGenerating) _buildGeneratingIndicator(context),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: SpacingTokens.md),
            _buildAvatar(context),
          ],
        ],
      ),
    );
  }

  /// 构建头像
  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.sender == MessageSender.user;

    return CircleAvatar(
      radius: SizeTokens.avatarMedium / 2,
      backgroundColor: isUser
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.secondaryContainer,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        color: isUser
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSecondaryContainer,
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final senderName = _getSenderName();

    return Text(
      senderName,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// 构建内容
  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.sender == MessageSender.user;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: isUser
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
      ),
      child: Text(
        message.content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isUser
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  /// 构建生成中指示器
  Widget _buildGeneratingIndicator(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: SpacingTokens.sm),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          Text(
            '生成中...',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取发送者名称
  String _getSenderName() {
    switch (message.sender) {
      case MessageSender.user:
        return '用户';
      case MessageSender.character:
        return '角色';
      case MessageSender.system:
        return '系统';
    }
  }
}
