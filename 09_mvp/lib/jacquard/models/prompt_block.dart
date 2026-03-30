/// PromptBlock 类型枚举
enum PromptBlockType { system, user, assistant }

/// PromptBlock - 提示词块
///
/// 用于组装 PromptBundle 的基本单元
class PromptBlock {
  final PromptBlockType type;
  final String content;

  const PromptBlock({
    required this.type,
    required this.content,
  });

  /// 创建 System Block
  factory PromptBlock.system(String content) => PromptBlock(
        type: PromptBlockType.system,
        content: content,
      );

  /// 创建 User Block
  factory PromptBlock.user(String content) => PromptBlock(
        type: PromptBlockType.user,
        content: content,
      );

  /// 创建 Assistant Block
  factory PromptBlock.assistant(String content) => PromptBlock(
        type: PromptBlockType.assistant,
        content: content,
      );

  /// 转换为 XML 格式（Filament 协议）
  String toXml() {
    final tagName = switch (type) {
      PromptBlockType.system => 'system',
      PromptBlockType.user => 'user',
      PromptBlockType.assistant => 'assistant',
    };
    return '<$tagName>\n$content\n</$tagName>';
  }

  @override
  String toString() => 'PromptBlock(type: $type, content: ${content.substring(0, content.length.clamp(0, 50))}...)';
}
