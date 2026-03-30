import 'package:flutter/material.dart';

/// InputArea - 输入区域组件
///
/// 包含文本输入框和发送按钮
/// 对应设计文档 Presentation 层输入区域规范
class InputArea extends StatefulWidget {
  final Function(String) onSend;
  final VoidCallback? onStop;
  final bool isLoading;
  final String? hintText;

  const InputArea({
    super.key,
    required this.onSend,
    this.onStop,
    this.isLoading = false,
    this.hintText,
  });

  @override
  State<InputArea> createState() => _InputAreaState();
}

class _InputAreaState extends State<InputArea> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !widget.isLoading) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  void _handleStop() {
    widget.onStop?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 文本输入框
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: 5,
                  minLines: 1,
                  enabled: !widget.isLoading,
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? '输入消息...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // 发送/停止按钮
            GestureDetector(
              onTap: widget.isLoading ? _handleStop : _handleSend,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.isLoading
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isLoading ? Icons.stop : Icons.send,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
