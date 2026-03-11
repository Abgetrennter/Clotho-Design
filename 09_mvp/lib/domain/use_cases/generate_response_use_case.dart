import 'dart:async';

import '../../jacquard/jacquard_orchestrator.dart';

/// 生成响应用例的输入参数
class GenerateResponseParams {
  final String sessionId;
  final String turnId;
  final String userInput;
  final GenerationOptions? options;

  const GenerateResponseParams({
    required this.sessionId,
    required this.turnId,
    required this.userInput,
    this.options,
  });
}

/// 生成响应选项
class GenerationOptions {
  final Duration? timeout;
  final bool streaming;

  const GenerationOptions({
    this.timeout,
    this.streaming = true,
  });
}

/// GenerateResponseUseCase - 生成响应用例
///
/// 负责协调 Jacquard 编排器完成 AI 响应生成
/// 对应设计文档 4.4.2 节
class GenerateResponseUseCase {
  final JacquardOrchestrator _orchestrator;

  GenerateResponseUseCase(this._orchestrator);

  /// 执行生成响应用例（流式）
  Stream<GenerationChunk> executeStreaming(GenerateResponseParams params) {
    return _orchestrator.processTurn(
      ProcessTurnRequest(
        sessionId: params.sessionId,
        userInput: params.userInput,
      ),
    );
  }

  /// 取消正在进行的生成
  Future<void> cancel() async {
    await _orchestrator.cancel();
  }
}
