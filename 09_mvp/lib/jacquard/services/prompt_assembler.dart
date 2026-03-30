import '../../mnemosyne/models/persona.dart';
import '../../mnemosyne/models/turn.dart';
import '../../mnemosyne/models/message.dart';
import '../models/prompt_block.dart';
import '../models/prompt_bundle.dart';

/// PromptAssembler - 提示词组装器
///
/// 负责将 Persona、历史记录和用户输入组装成 PromptBundle
/// 对应设计文档 4.5.1 节
class PromptAssembler {
  /// 组装 PromptBundle
  PromptBundle assemble({
    required Persona persona,
    required List<Turn> history,
    required String userInput,
  }) {
    // System Blocks: Persona 系统提示
    final systemBlocks = [
      PromptBlock.system(persona.systemPrompt),
    ];

    // History Blocks: 历史对话
    final historyBlocks = <PromptBlock>[];
    for (final turn in history) {
      for (final message in turn.messages) {
        if (message.isActive) {
          historyBlocks.add(_messageToBlock(message));
        }
      }
    }

    // User Block: 当前用户输入
    final userBlock = PromptBlock.user(userInput);

    return PromptBundle(
      systemBlocks: systemBlocks,
      historyBlocks: historyBlocks,
      userBlock: userBlock,
    );
  }

  /// 将 Message 转换为 PromptBlock
  PromptBlock _messageToBlock(Message message) {
    return switch (message.role) {
      MessageRole.system => PromptBlock.system(message.content),
      MessageRole.user => PromptBlock.user(message.content),
      MessageRole.assistant => PromptBlock.assistant(message.content),
    };
  }

  /// 创建简化的 PromptBundle（仅包含系统提示和用户输入）
  PromptBundle assembleSimple({
    required Persona persona,
    required String userInput,
  }) {
    return PromptBundle(
      systemBlocks: [PromptBlock.system(persona.systemPrompt)],
      historyBlocks: [],
      userBlock: PromptBlock.user(userInput),
    );
  }
}
