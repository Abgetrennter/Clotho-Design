import 'dart:async';

import '../core/exceptions/clotho_exception.dart';
import '../mnemosyne/mnemosyne_data_engine.dart';
import '../mnemosyne/models/message.dart';
import 'services/prompt_assembler.dart';
import 'services/llm_service.dart';
import 'services/filament_parser.dart';

/// 处理用户输入请求参数
class ProcessTurnRequest {
  final String sessionId;
  final String userInput;

  const ProcessTurnRequest({
    required this.sessionId,
    required this.userInput,
  });
}

/// 生成内容块（用于流式输出）
class GenerationChunk {
  final String content;
  final String? thought;
  final bool isComplete;
  final Map<String, dynamic>? metadata;

  const GenerationChunk({
    required this.content,
    this.thought,
    this.isComplete = false,
    this.metadata,
  });
}

/// JacquardOrchestrator - 编排器主类
///
/// 协调 Mnemosyne、LLM 和 FilamentParser 完成对话流程
/// 对应设计文档 4.5.1 节
class JacquardOrchestrator {
  final MnemosyneDataEngine _dataEngine;
  final LLMService _llmService;
  final FilamentParser _parser;
  final PromptAssembler _assembler;

  JacquardOrchestrator({
    required MnemosyneDataEngine dataEngine,
    required LLMService llmService,
    FilamentParser? parser,
    PromptAssembler? assembler,
  })  : _dataEngine = dataEngine,
        _llmService = llmService,
        _parser = parser ?? FilamentParser(),
        _assembler = assembler ?? PromptAssembler();

  /// 处理用户输入，生成 AI 响应（流式）
  Stream<GenerationChunk> processTurn(ProcessTurnRequest request) async* {
    try {
      // 1. 获取 Session Context
      final context = await _dataEngine.getSessionContext(request.sessionId);
      final persona = context.persona;
      final history = context.turns;

      // 2. 组装 PromptBundle
      final bundle = _assembler.assemble(
        persona: persona,
        history: history,
        userInput: request.userInput,
      );

      // 3. 创建 Turn（包含用户消息）
      final userMessage = Message(
        id: 'msg_user_${DateTime.now().millisecondsSinceEpoch}',
        turnId: 'pending', // 将在保存时更新
        role: MessageRole.user,
        content: request.userInput,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );

      final turn = await _dataEngine.createTurn(
        sessionId: request.sessionId,
        messages: [userMessage],
      );

      // 4. 调用 LLM（流式）
      final contentBuffer = StringBuffer();
      String? thought;

      await for (final chunk in _llmService.streamCompletion(bundle)) {
        contentBuffer.write(chunk.content);

        // 实时解析 Filament
        final accumulatedContent = contentBuffer.toString();
        final parseResult = _parser.parse(accumulatedContent);

        yield GenerationChunk(
          content: chunk.content,
          thought: parseResult.thought,
          isComplete: chunk.isComplete,
        );

        if (parseResult.thought != null) {
          thought = parseResult.thought;
        }
      }

      // 5. 保存助手消息（MVP 简化版暂不实现）
      // 注意：实际项目中需要实现 TurnRepository.update()

      // 6. 返回最终结果
      yield GenerationChunk(
        content: '',
        thought: thought,
        isComplete: true,
        metadata: {
          'turnId': turn.id,
          'thought': thought,
        },
      );
    } on ClothoException {
      rethrow;
    } catch (e) {
      throw OrchestrationException(
        message: 'Failed to process turn: $e',
        code: 'PROCESS_TURN_FAILED',
        cause: e is Exception ? e : Exception(e),
      );
    }
  }

  /// 取消正在进行的生成
  Future<void> cancel() async {
    await _llmService.cancel();
  }

  /// 释放资源
  void dispose() {
    _llmService.dispose();
  }
}
