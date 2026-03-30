/// 输入区域组件
/// 对应文档: 00_active_specs/presentation/06-input-area.md
library;

import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

/// 输入区域组件
class InputArea extends StatelessWidget {
  const InputArea({
    super.key,
    required this.controller,
    required this.onSend,
    this.isGenerating = false,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isGenerating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildAttachmentButton(context),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: _buildTextField(context),
            ),
            const SizedBox(width: SpacingTokens.sm),
            _buildSendButton(context),
          ],
        ),
      ),
    );
  }

  /// 构建附件按钮
  Widget _buildAttachmentButton(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      icon: const Icon(Icons.attach_file),
      onPressed: () {},
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  /// 构建文本输入框
  Widget _buildTextField(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      maxLines: null,
      minLines: 1,
      decoration: InputDecoration(
        hintText: '输入消息...',
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.full),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.sm,
        ),
      ),
    );
  }

  /// 构建发送按钮
  Widget _buildSendButton(BuildContext context) {
    final theme = Theme.of(context);

    return FloatingActionButton(
      onPressed: isGenerating ? null : onSend,
      mini: true,
      child: isGenerating
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.onPrimaryContainer,
                ),
              ),
            )
          : const Icon(Icons.send),
    );
  }
}
