import 'prompt_block.dart';

/// PromptBundle - 提示词包
///
/// 对应隐喻体系中的 "Skein (绞纱)"
/// 用于向 LLM 发送的完整提示词容器
/// 对应设计文档 4.5.1 节
class PromptBundle {
  final List<PromptBlock> systemBlocks;
  final List<PromptBlock> historyBlocks;
  final PromptBlock? userBlock;

  const PromptBundle({
    required this.systemBlocks,
    required this.historyBlocks,
    this.userBlock,
  });

  /// 转换为 XML 格式（Filament 协议输入格式）
  String toXml() {
    final buffer = StringBuffer();

    // System Chain
    for (final block in systemBlocks) {
      buffer.writeln(block.toXml());
    }

    // History Chain
    for (final block in historyBlocks) {
      buffer.writeln(block.toXml());
    }

    // User Block
    if (userBlock != null) {
      buffer.writeln(userBlock!.toXml());
    }

    return buffer.toString();
  }

  /// 创建副本
  PromptBundle copyWith({
    List<PromptBlock>? systemBlocks,
    List<PromptBlock>? historyBlocks,
    PromptBlock? userBlock,
  }) {
    return PromptBundle(
      systemBlocks: systemBlocks ?? this.systemBlocks,
      historyBlocks: historyBlocks ?? this.historyBlocks,
      userBlock: userBlock ?? this.userBlock,
    );
  }

  @override
  String toString() => 'PromptBlock(system: ${systemBlocks.length}, history: ${historyBlocks.length}, user: ${userBlock != null ? "yes" : "no"})';
}
