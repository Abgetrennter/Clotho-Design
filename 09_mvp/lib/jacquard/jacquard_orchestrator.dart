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

  /// 处理用户输入，生成 AI 响应（非流式）
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

      // 3. 调用 LLM（非流式）
      final fullResponse = await _llmService.completion(bundle);

      // 4. 解析 Filament
      final parseResult = _parser.parse(fullResponse);

      // 5. 创建 Turn（包含用户消息和 AI 响应）
      final userMessage = Message(
        id: 'msg_user_${DateTime.now().millisecondsSinceEpoch}',
        turnId: 'pending',
        role: MessageRole.user,
        content: request.userInput,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );

      final assistantMessage = Message(
        id: 'msg_assistant_${DateTime.now().millisecondsSinceEpoch}',
        turnId: 'pending',
        role: MessageRole.assistant,
        content: parseResult.content,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );

      final turn = await _dataEngine.createTurn(
        sessionId: request.sessionId,
        messages: [userMessage, assistantMessage],
      );

      // 6. 返回完整响应
      yield GenerationChunk(
        content: parseResult.content,
        thought: parseResult.thought,
        isComplete: true,
        metadata: {
          'turnId': turn.id,
          'thought': parseResult.thought,
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
