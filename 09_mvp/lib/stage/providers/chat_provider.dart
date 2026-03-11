import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/clotho_nexus.dart';
import '../../jacquard/jacquard_orchestrator.dart';
import '../../jacquard/services/llm_service.dart';
import '../../mnemosyne/mnemosyne_data_engine.dart';
import '../../mnemosyne/models/turn.dart';
import '../../mnemosyne/repositories/in_memory_persona_repository.dart';
import '../../mnemosyne/repositories/in_memory_session_repository.dart';
import '../../mnemosyne/repositories/in_memory_turn_repository.dart';

// 导出 ProcessTurnRequest 以便使用
export '../../jacquard/jacquard_orchestrator.dart' show ProcessTurnRequest;

/// LLM 服务配置 Provider
final llmConfigProvider = Provider<LLMServiceConfig>((ref) {
  // MVP 简化：使用环境变量或硬编码配置
  // 实际项目中应从配置文件或环境变量读取
  return const LLMServiceConfig(
    baseUrl: 'https://open.bigmodel.cn/api/coding/paas/v4',
    apiKey: '3a3ca3ae82f24e1094ffc070f384ad4c.EunL3fOC64UyF1tC', // TODO: 替换为实际 API Key
    model: 'GLM-4.7',
  );
});

/// LLM 服务 Provider
final llmServiceProvider = Provider<LLMService>((ref) {
  final config = ref.watch(llmConfigProvider);
  return LLMService(config: config);
});

/// Persona Repository Provider
final personaRepoProvider = Provider<InMemoryPersonaRepository>((ref) {
  final repo = InMemoryPersonaRepository();
  // 预加载 Persona
  repo.preload();
  return repo;
});

/// Session Repository Provider
final sessionRepoProvider = Provider<InMemorySessionRepository>((ref) {
  return InMemorySessionRepository();
});

/// Turn Repository Provider
final turnRepoProvider = Provider<InMemoryTurnRepository>((ref) {
  return InMemoryTurnRepository();
});

/// Mnemosyne 数据引擎 Provider
final dataEngineProvider = Provider<MnemosyneDataEngine>((ref) {
  return MnemosyneDataEngine(
    personaRepo: ref.watch(personaRepoProvider),
    sessionRepo: ref.watch(sessionRepoProvider),
    turnRepo: ref.watch(turnRepoProvider),
  );
});

/// Jacquard 编排器 Provider
final orchestratorProvider = Provider<JacquardOrchestrator>((ref) {
  return JacquardOrchestrator(
    dataEngine: ref.watch(dataEngineProvider),
    llmService: ref.watch(llmServiceProvider),
  );
});

/// ClothoNexus 事件总线 Provider
final clothoNexusProvider = Provider<ClothoNexus>((ref) {
  return ClothoNexus();
});

/// 聊天状态
class ChatState {
  final String? currentSessionId;
  final List<Turn> turns;
  final String? streamingContent;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.currentSessionId,
    this.turns = const [],
    this.streamingContent,
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    String? currentSessionId,
    List<Turn>? turns,
    String? streamingContent,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      currentSessionId: currentSessionId ?? this.currentSessionId,
      turns: turns ?? this.turns,
      streamingContent: streamingContent ?? this.streamingContent,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// 聊天 Notifier（Riverpod 3.x 风格）
class ChatNotifier extends Notifier<ChatState> {
  late MnemosyneDataEngine _dataEngine;
  late JacquardOrchestrator _orchestrator;

  @override
  ChatState build() {
    // 在 build 中初始化依赖
    _dataEngine = ref.read(dataEngineProvider);
    _orchestrator = ref.read(orchestratorProvider);
    return const ChatState();
  }

  /// 初始化会话
  Future<void> initializeSession(String personaId) async {
    try {
      final session = await _dataEngine.createSession(personaId: personaId);
      state = state.copyWith(
        currentSessionId: session.id,
        turns: [],
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to initialize session: $e');
    }
  }

  /// 发送消息
  Future<void> sendMessage(String content) async {
    final sessionId = state.currentSessionId;
    if (sessionId == null) {
      state = state.copyWith(error: 'No active session');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // 流式处理响应
      await for (final chunk in _orchestrator.processTurn(
        ProcessTurnRequest(sessionId: sessionId, userInput: content),
      )) {
        if (chunk.isComplete) {
          // 生成完成，刷新 turns 列表
          final turns = await _dataEngine.getTurnHistory(sessionId);
          state = state.copyWith(
            turns: turns,
            isLoading: false,
            streamingContent: null,
          );
        } else {
          // 流式更新
          state = state.copyWith(
            streamingContent: (state.streamingContent ?? '') + chunk.content,
          );
        }
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to send message: $e',
        isLoading: false,
      );
    }
  }

  /// 停止生成
  Future<void> stopGeneration() async {
    await _orchestrator.cancel();
    state = state.copyWith(isLoading: false);
  }
}

/// 聊天 Provider（状态管理）
final chatProvider = NotifierProvider<ChatNotifier, ChatState>(() {
  return ChatNotifier();
});
