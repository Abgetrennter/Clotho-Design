# Muse Provider 适配器规范

**版本**: 1.0.0
**日期**: 2026-02-26
**状态**: Active
**作者**: Clotho 架构团队
**关联文档**:
- [Muse 智能服务架构](README.md) - Muse 服务概览
- [流式响应与计费设计](streaming-and-billing-design.md) - LLMIterator 接口定义
- [ClothoNexus 事件总线](../infrastructure/clotho-nexus-events.md) - 事件集成

---

## 1. 概述

本文档定义 Muse 智能服务中各类 LLM Provider 的适配器实现规范。Provider 适配器负责将不同厂商的 API 协议统一映射到 Muse 内部的 `LLMIterator` 接口，实现多 Provider 的无缝切换和统一治理。

### 1.1 设计目标

- **协议统一**: 无论底层是 OpenAI、Anthropic 还是 Local LLM，上层均通过统一接口访问
- **错误标准化**: 将各 Provider 的差异性错误码映射为 Muse 标准错误类型
- **功能对等**: 在 Provider 能力范围内，提供一致的功能体验（流式、计费、工具调用）
- **可扩展性**: 新增 Provider 仅需实现标准接口，无需修改上层代码

### 1.2 支持矩阵

| Provider | 流式生成 | Token 计费 | 工具调用 | 多模态 | 状态 |
|----------|----------|------------|----------|--------|------|
| OpenAI | ✅ | ✅ | ✅ | ✅ | 已实现 |
| Anthropic | ✅ | ✅ | ✅ | ✅ | 待实现 |
| Ollama (Local) | ✅ | ⚠️ 估算 | ❌ | ❌ | 待实现 |
| OpenAI-Compatible | ✅ | ✅ | ✅ | ⚠️ 视实现 | 待实现 |
| Google Gemini | ✅ | ✅ | ✅ | ✅ | 规划中 |

> **Token 计费说明**: Ollama 等 Local LLM 通常不返回 Token 计数，需通过 Tiktoken 等库进行估算。

---

## 2. 核心抽象

### 2.1 Provider 适配器接口

```dart
/// Provider 适配器工厂
abstract class ProviderAdapterFactory {
  /// 创建适配器实例
  ProviderAdapter createAdapter(ProviderConfig config);
  
  /// 支持的 Provider 类型标识
  String get providerType;
}

/// Provider 适配器核心接口
abstract class ProviderAdapter {
  /// Provider 类型标识
  String get providerType;
  
  /// 创建流式迭代器
  LLMIterator createIterator({
    required ModelConfig modelConfig,
    required List<RawMessage> messages,
    GenerationOptions? options,
  });
  
  /// 执行非流式生成
  Future<LLMResponse> execute({
    required ModelConfig modelConfig,
    required List<RawMessage> messages,
    GenerationOptions? options,
  });
  
  /// 健康检查
  Future<HealthStatus> checkHealth();
  
  /// 获取可用模型列表
  Future<List<ModelInfo>> listModels();
  
  /// 计算 Token 数量（用于 Local LLM）
  Future<int> countTokens(String text, String model);
}
```

### 2.2 错误码标准化

```dart
/// Muse 标准错误类型
enum MuseErrorCode {
  // 网络层错误 (1xxx)
  networkTimeout('NET1000', '请求超时'),
  networkUnreachable('NET1001', '网络不可达'),
  dnsResolutionFailed('NET1002', 'DNS 解析失败'),
  
  // Provider 层错误 (2xxx)
  rateLimitExceeded('PRV2000', '速率限制 exceeded'),
  quotaExceeded('PRV2001', '配额已用尽'),
  invalidApiKey('PRV2002', 'API Key 无效'),
  contextLengthExceeded('PRV2003', '上下文长度超限'),
  modelNotFound('PRV2004', '模型不存在'),
  providerServerError('PRV2005', 'Provider 服务器错误'),
  
  // 内容层错误 (3xxx)
  contentFiltered('CNT3000', '内容被过滤'),
  contentTooLong('CNT3001', '内容过长'),
  
  // 配置层错误 (4xxx)
  invalidConfiguration('CFG4000', '配置无效'),
  unsupportedFeature('CFG4001', '不支持的功能'),
}

class MuseProviderException implements Exception {
  final MuseErrorCode code;
  final String message;
  final String? providerErrorCode;  // Provider 原始错误码
  final Map<String, dynamic>? metadata;
  final bool isRetryable;
  
  MuseProviderException({
    required this.code,
    required this.message,
    this.providerErrorCode,
    this.metadata,
    required this.isRetryable,
  });
}
```

---

## 3. OpenAI 适配器（参考实现）

### 3.1 完整实现代码

```dart
/// OpenAI Provider 适配器
class OpenAIAdapter implements ProviderAdapter {
  final OpenAIClient _client;
  final ProviderConfig _config;
  
  OpenAIAdapter({
    required OpenAIClient client,
    required ProviderConfig config,
  })  : _client = client,
        _config = config;
  
  @override
  String get providerType => 'openai';
  
  @override
  LLMIterator createIterator({
    required ModelConfig modelConfig,
    required List<RawMessage> messages,
    GenerationOptions? options,
  }) {
    return OpenAIIterator(
      client: _client,
      config: modelConfig,
      messages: messages,
      options: options,
    );
  }
  
  @override
  Future<LLMResponse> execute({
    required ModelConfig modelConfig,
    required List<RawMessage> messages,
    GenerationOptions? options,
  }) async {
    try {
      final response = await _client.createChatCompletion(
        model: modelConfig.model,
        messages: _convertMessages(messages),
        temperature: options?.temperature ?? 0.7,
        maxTokens: options?.maxTokens,
        topP: options?.topP,
        frequencyPenalty: options?.frequencyPenalty,
        presencePenalty: options?.presencePenalty,
      );
      
      return LLMResponse(
        content: response.choices.first.message.content ?? '',
        usage: TokenUsage(
          promptTokens: response.usage?.promptTokens ?? 0,
          completionTokens: response.usage?.completionTokens ?? 0,
          totalTokens: response.usage?.totalTokens ?? 0,
        ),
        finishReason: _mapFinishReason(response.choices.first.finishReason),
      );
    } on OpenAIException catch (e) {
      throw _mapOpenAIError(e);
    }
  }
  
  @override
  Future<HealthStatus> checkHealth() async {
    try {
      await _client.listModels();
      return HealthStatus.healthy;
    } catch (e) {
      return HealthStatus.unhealthy(e.toString());
    }
  }
  
  @override
  Future<List<ModelInfo>> listModels() async {
    final response = await _client.listModels();
    return response.data
        .where((m) => m.id.startsWith('gpt'))
        .map((m) => ModelInfo(
              id: m.id,
              name: m.id,
              provider: 'openai',
              capabilities: _inferCapabilities(m.id),
            ))
        .toList();
  }
  
  @override
  Future<int> countTokens(String text, String model) async {
    // OpenAI 返回实际使用量，无需预估
    throw UnsupportedError('OpenAI 不需要本地 Token 计数');
  }
  
  // 内部方法
  List<OpenAIChatCompletionChoiceMessageModel> _convertMessages(
    List<RawMessage> messages,
  ) {
    return messages.map((m) => OpenAIChatCompletionChoiceMessageModel(
      role: _mapRole(m.role),
      content: m.content,
    )).toList();
  }
  
  OpenAIChatMessageRole _mapRole(MessageRole role) {
    return switch (role) {
      MessageRole.system => OpenAIChatMessageRole.system,
      MessageRole.user => OpenAIChatMessageRole.user,
      MessageRole.assistant => OpenAIChatMessageRole.assistant,
      MessageRole.tool => OpenAIChatMessageRole.tool,
    };
  }
  
  FinishReason _mapFinishReason(String? reason) {
    return switch (reason) {
      'stop' => FinishReason.completed,
      'length' => FinishReason.maxTokensReached,
      'content_filter' => FinishReason.contentFiltered,
      _ => FinishReason.unknown,
    };
  }
  
  MuseProviderException _mapOpenAIError(OpenAIException error) {
    final code = error.code;
    return switch (code) {
      'rate_limit_exceeded' => MuseProviderException(
          code: MuseErrorCode.rateLimitExceeded,
          message: '请求频率超限，请稍后重试',
          providerErrorCode: code,
          isRetryable: true,
        ),
      'insufficient_quota' => MuseProviderException(
          code: MuseErrorCode.quotaExceeded,
          message: 'API 配额已用尽',
          providerErrorCode: code,
          isRetryable: false,
        ),
      'invalid_api_key' => MuseProviderException(
          code: MuseErrorCode.invalidApiKey,
          message: 'API Key 无效',
          providerErrorCode: code,
          isRetryable: false,
        ),
      'context_length_exceeded' => MuseProviderException(
          code: MuseErrorCode.contextLengthExceeded,
          message: '上下文长度超过模型限制',
          providerErrorCode: code,
          isRetryable: false,
        ),
      _ => MuseProviderException(
          code: MuseErrorCode.providerServerError,
          message: error.message,
          providerErrorCode: code,
          isRetryable: true,
        ),
    };
  }
  
  ModelCapabilities _inferCapabilities(String modelId) {
    return ModelCapabilities(
      streaming: true,
      functionCalling: modelId.contains('gpt-4') || modelId.contains('gpt-3.5-turbo'),
      vision: modelId.contains('vision') || modelId.contains('gpt-4-turbo'),
      jsonMode: modelId.contains('gpt-4') || modelId.contains('gpt-3.5-turbo-1106'),
    );
  }
}

/// OpenAI 流式迭代器实现
class OpenAIIterator implements LLMIterator {
  final OpenAIClient _client;
  final ModelConfig _config;
  final List<RawMessage> _messages;
  final GenerationOptions _options;
  
  Stream<OpenAIStreamChatCompletionChunk>? _stream;
  StreamIterator<OpenAIStreamChatCompletionChunk>? _iterator;
  bool _cancelled = false;
  bool _ended = false;
  int _chunkIndex = 0;
  String _bufferedContent = '';
  
  OpenAIIterator({
    required OpenAIClient client,
    required ModelConfig config,
    required List<RawMessage> messages,
    GenerationOptions? options,
  })  : _client = client,
        _config = config,
        _messages = messages,
        _options = options ?? const GenerationOptions();
  
  @override
  Future<LLMChunk?> next() async {
    if (_cancelled || _ended) return null;
    
    try {
      // 首次调用时初始化流
      if (_stream == null) {
        _stream = _client.createChatCompletionStream(
          model: _config.model,
          messages: _messages.map((m) => OpenAIChatCompletionChoiceMessageModel(
            role: _mapRole(m.role),
            content: m.content,
          )).toList(),
          temperature: _options.temperature,
          maxTokens: _options.maxTokens,
          topP: _options.topP,
        );
        _iterator = StreamIterator(_stream!);
      }
      
      // 拉取下一个事件
      final hasNext = await _iterator!.moveNext();
      if (!hasNext) {
        _ended = true;
        return null;
      }
      
      final chunk = _iterator!.current;
      final delta = chunk.choices.first.delta;
      
      // 累积内容
      if (delta.content != null) {
        _bufferedContent += delta.content!;
      }
      
      // 检查是否结束
      final finishReason = chunk.choices.first.finishReason;
      final isLast = finishReason != null;
      
      if (isLast) {
        _ended = true;
      }
      
      return LLMChunk(
        content: delta.content ?? '',
        index: _chunkIndex++,
        isLast: isLast,
        usage: isLast ? _estimateUsage() : null,
        timestamp: DateTime.now(),
      );
    } on OpenAIException catch (e) {
      throw _mapOpenAIError(e);
    }
  }
  
  @override
  Future<void> cancel() async {
    _cancelled = true;
    await _iterator?.cancel();
  }
  
  @override
  bool get hasNext => !_cancelled && !_ended;
  
  TokenUsage? _estimateUsage() {
    // OpenAI 流式响应通常在最后一个 chunk 返回 usage
    // 如果没有，则需要估算
    return null;
  }
  
  OpenAIChatMessageRole _mapRole(MessageRole role) {
    return switch (role) {
      MessageRole.system => OpenAIChatMessageRole.system,
      MessageRole.user => OpenAIChatMessageRole.user,
      MessageRole.assistant => OpenAIChatMessageRole.assistant,
      MessageRole.tool => OpenAIChatMessageRole.tool,
    };
  }
}
```

---

## 4. Anthropic 适配器

### 4.1 关键差异点

Anthropic API 与 OpenAI 的主要差异：

1. **消息格式**: Anthropic 使用 `messages` + `system` 分离，而非 system 作为 role
2. **流式格式**: SSE 事件结构不同，`data: {"type": "content_block_delta", ...}`
3. **Token 计数**: 在消息结束时通过 `message_stop` 事件返回
4. **错误码**: 使用 `overloaded_error` 表示服务器负载过高

### 4.2 实现代码

```dart
/// Anthropic Provider 适配器
class AnthropicAdapter implements ProviderAdapter {
  final AnthropicClient _client;
  final ProviderConfig _config;
  
  AnthropicAdapter({
    required AnthropicClient client,
    required ProviderConfig config,
  })  : _client = client,
        _config = config;
  
  @override
  String get providerType => 'anthropic';
  
  @override
  LLMIterator createIterator({
    required ModelConfig modelConfig,
    required List<RawMessage> messages,
    GenerationOptions? options,
  }) {
    return AnthropicIterator(
      client: _client,
      config: modelConfig,
      messages: messages,
      options: options,
    );
  }
  
  @override
  Future<LLMResponse> execute({
    required ModelConfig modelConfig,
    required List<RawMessage> messages,
    GenerationOptions? options,
  }) async {
    final (systemMessage, chatMessages) = _separateSystemMessage(messages);
    
    try {
      final response = await _client.createMessage(
        model: modelConfig.model,
        maxTokens: options?.maxTokens ?? 4096,
        messages: chatMessages.map((m) => AnthropicMessage(
          role: _mapRole(m.role),
          content: m.content,
        )).toList(),
        system: systemMessage,
        temperature: options?.temperature,
        topP: options?.topP,
      );
      
      return LLMResponse(
        content: response.content.first.text,
        usage: TokenUsage(
          promptTokens: response.usage.inputTokens,
          completionTokens: response.usage.outputTokens,
          totalTokens: response.usage.inputTokens + response.usage.outputTokens,
        ),
        finishReason: _mapFinishReason(response.stopReason),
      );
    } on AnthropicException catch (e) {
      throw _mapAnthropicError(e);
    }
  }
  
  @override
  Future<HealthStatus> checkHealth() async {
    try {
      // Anthropic 没有直接的 health check，尝试 list models
      await listModels();
      return HealthStatus.healthy;
    } catch (e) {
      return HealthStatus.unhealthy(e.toString());
    }
  }
  
  @override
  Future<List<ModelInfo>> listModels() async {
    // Anthropic 模型列表通常是固定的
    return [
      ModelInfo(
        id: 'claude-3-opus-20240229',
        name: 'Claude 3 Opus',
        provider: 'anthropic',
        capabilities: ModelCapabilities(
          streaming: true,
          functionCalling: true,
          vision: true,
          jsonMode: true,
        ),
      ),
      ModelInfo(
        id: 'claude-3-sonnet-20240229',
        name: 'Claude 3 Sonnet',
        provider: 'anthropic',
        capabilities: ModelCapabilities(
          streaming: true,
          functionCalling: true,
          vision: true,
          jsonMode: true,
        ),
      ),
      ModelInfo(
        id: 'claude-3-haiku-20240307',
        name: 'Claude 3 Haiku',
        provider: 'anthropic',
        capabilities: ModelCapabilities(
          streaming: true,
          functionCalling: true,
          vision: true,
          jsonMode: true,
        ),
      ),
    ];
  }
  
  @override
  Future<int> countTokens(String text, String model) async {
    // Anthropic 提供专门的 Token 计数 API
    final response = await _client.countTokens(
      model: model,
      messages: [AnthropicMessage(role: 'user', content: text)],
    );
    return response.inputTokens;
  }
  
  // 内部辅助方法
  (String?, List<RawMessage>) _separateSystemMessage(List<RawMessage> messages) {
    String? systemMessage;
    final chatMessages = <RawMessage>[];
    
    for (final msg in messages) {
      if (msg.role == MessageRole.system && systemMessage == null) {
        systemMessage = msg.content;
      } else {
        chatMessages.add(msg);
      }
    }
    
    return (systemMessage, chatMessages);
  }
  
  String _mapRole(MessageRole role) {
    return switch (role) {
      MessageRole.system => throw ArgumentError('System message should be separated'),
      MessageRole.user => 'user',
      MessageRole.assistant => 'assistant',
      MessageRole.tool => throw ArgumentError('Anthropic does not support tool role in this format'),
    };
  }
  
  FinishReason _mapFinishReason(String? reason) {
    return switch (reason) {
      'end_turn' => FinishReason.completed,
      'max_tokens' => FinishReason.maxTokensReached,
      'stop_sequence' => FinishReason.completed,
      _ => FinishReason.unknown,
    };
  }
  
  MuseProviderException _mapAnthropicError(AnthropicException error) {
    final type = error.type;
    return switch (type) {
      'rate_limit_error' => MuseProviderException(
          code: MuseErrorCode.rateLimitExceeded,
          message: '请求频率超限',
          providerErrorCode: type,
          isRetryable: true,
        ),
      'overloaded_error' => MuseProviderException(
          code: MuseErrorCode.providerServerError,
          message: 'Anthropic 服务器负载过高',
          providerErrorCode: type,
          isRetryable: true,
        ),
      'invalid_request_error' => MuseProviderException(
          code: MuseErrorCode.invalidConfiguration,
          message: error.message,
          providerErrorCode: type,
          isRetryable: false,
        ),
      'authentication_error' => MuseProviderException(
          code: MuseErrorCode.invalidApiKey,
          message: 'API Key 无效',
          providerErrorCode: type,
          isRetryable: false,
        ),
      _ => MuseProviderException(
          code: MuseErrorCode.providerServerError,
          message: error.message,
          providerErrorCode: type,
          isRetryable: true,
        ),
    };
  }
}

/// Anthropic 流式迭代器
class AnthropicIterator implements LLMIterator {
  final AnthropicClient _client;
  final ModelConfig _config;
  final List<RawMessage> _messages;
  final GenerationOptions _options;
  
  Stream<AnthropicStreamEvent>? _stream;
  StreamIterator<AnthropicStreamEvent>? _iterator;
  bool _cancelled = false;
  bool _ended = false;
  int _chunkIndex = 0;
  TokenUsage? _finalUsage;
  
  AnthropicIterator({
    required AnthropicClient client,
    required ModelConfig config,
    required List<RawMessage> messages,
    GenerationOptions? options,
  })  : _client = client,
        _config = config,
        _messages = messages,
        _options = options ?? const GenerationOptions();
  
  @override
  Future<LLMChunk?> next() async {
    if (_cancelled || _ended) return null;
    
    try {
      if (_stream == null) {
        final (systemMessage, chatMessages) = _separateSystemMessage(_messages);
        _stream = _client.createMessageStream(
          model: _config.model,
          maxTokens: _options.maxTokens ?? 4096,
          messages: chatMessages.map((m) => AnthropicMessage(
            role: _mapRole(m.role),
            content: m.content,
          )).toList(),
          system: systemMessage,
          temperature: _options.temperature,
          topP: _options.topP,
        );
        _iterator = StreamIterator(_stream!);
      }
      
      final hasNext = await _iterator!.moveNext();
      if (!hasNext) {
        _ended = true;
        return null;
      }
      
      final event = _iterator!.current;
      
      // Anthropic 流式事件类型处理
      return switch (event.type) {
        'content_block_delta' => _handleContentDelta(event),
        'message_delta' => _handleMessageDelta(event),
        'message_stop' => _handleMessageStop(),
        'ping' => next(),  // 心跳包，递归获取下一个
        _ => next(),  // 忽略其他事件类型
      };
    } on AnthropicException catch (e) {
      throw _mapAnthropicError(e);
    }
  }
  
  LLMChunk _handleContentDelta(AnthropicStreamEvent event) {
    final delta = event.delta;
    return LLMChunk(
      content: delta.text ?? '',
      index: _chunkIndex++,
      isLast: false,
      usage: null,
      timestamp: DateTime.now(),
    );
  }
  
  LLMChunk? _handleMessageDelta(AnthropicStreamEvent event) {
    // 可能包含 usage 信息
    if (event.usage != null) {
      _finalUsage = TokenUsage(
        promptTokens: event.usage!.inputTokens,
        completionTokens: event.usage!.outputTokens,
        totalTokens: event.usage!.inputTokens + event.usage!.outputTokens,
      );
    }
    // message_delta 通常不包含内容，继续获取下一个
    return next();
  }
  
  LLMChunk _handleMessageStop() {
    _ended = true;
    return LLMChunk(
      content: '',
      index: _chunkIndex++,
      isLast: true,
      usage: _finalUsage,
      timestamp: DateTime.now(),
    );
  }
  
  @override
  Future<void> cancel() async {
    _cancelled = true;
    await _iterator?.cancel();
  }
  
  @override
  bool get hasNext => !_cancelled && !_ended;
  
  // 辅助方法（与 AnthropicAdapter 相同，省略）
  (String?, List<RawMessage>) _separateSystemMessage(List<RawMessage> messages) {
    // ...
  }
  
  String _mapRole(MessageRole role) {
    // ...
  }
  
  MuseProviderException _mapAnthropicError(AnthropicException error) {
    // ...
  }
}
```

---

## 5. Ollama (Local LLM) 适配器

### 5.1 特殊考量

Local LLM 的特殊性：
- **无内置 Token 计数**: 需要使用 Tiktoken 等库估算
- **无计费**: 成本为 0，但仍需记录使用量
- **模型发现**: 通过 `/api/tags` 动态发现本地模型
- **无速率限制**: 但可能有并发限制

### 5.2 实现代码

```dart
/// Ollama Provider 适配器
class OllamaAdapter implements ProviderAdapter {
  final OllamaClient _client;
  final ProviderConfig _config;
  final Tokenizer _tokenizer;  // Tiktoken 或类似实现
  
  OllamaAdapter({
    required OllamaClient client,
    required ProviderConfig config,
    required Tokenizer tokenizer,
  })  : _client = client,
        _config = config,
        _tokenizer = tokenizer;
  
  @override
  String get providerType => 'ollama';
  
  @override
  LLMIterator createIterator({
    required ModelConfig modelConfig,
    required List<RawMessage> messages,
    GenerationOptions? options,
  }) {
    return OllamaIterator(
      client: _client,
      tokenizer: _tokenizer,
      config: modelConfig,
      messages: messages,
      options: options,
    );
  }
  
  @override
  Future<LLMResponse> execute({
    required ModelConfig modelConfig,
    required List<RawMessage> messages,
    GenerationOptions? options,
  }) async {
    try {
      final promptTokens = await _countMessagesTokens(messages, modelConfig.model);
      
      final response = await _client.generate(
        model: modelConfig.model,
        messages: messages.map((m) => OllamaMessage(
          role: m.role.name,
          content: m.content,
        )).toList(),
        options: OllamaRequestOptions(
          temperature: options?.temperature ?? 0.7,
          numPredict: options?.maxTokens ?? 128,
          topP: options?.topP ?? 0.9,
        ),
      );
      
      final completionTokens = await _tokenizer.encode(response.message.content);
      
      return LLMResponse(
        content: response.message.content,
        usage: TokenUsage(
          promptTokens: promptTokens,
          completionTokens: completionTokens.length,
          totalTokens: promptTokens + completionTokens.length,
        ),
        finishReason: response.done ? FinishReason.completed : FinishReason.unknown,
      );
    } on OllamaException catch (e) {
      throw _mapOllamaError(e);
    }
  }
  
  @override
  Future<HealthStatus> checkHealth() async {
    try {
      final response = await _client.listModels();
      return HealthStatus.healthy;
    } catch (e) {
      return HealthStatus.unhealthy(e.toString());
    }
  }
  
  @override
  Future<List<ModelInfo>> listModels() async {
    final response = await _client.listModels();
    return response.models.map((m) => ModelInfo(
      id: m.name,
      name: m.name,
      provider: 'ollama',
      capabilities: ModelCapabilities(
        streaming: true,
        functionCalling: false,  // 取决于模型和 Ollama 版本
        vision: m.details?.families?.contains('clip') ?? false,
        jsonMode: false,
      ),
    )).toList();
  }
  
  @override
  Future<int> countTokens(String text, String model) async {
    // 使用 Tiktoken 估算
    final encoding = await _tokenizer.encode(text);
    return encoding.length;
  }
  
  Future<int> _countMessagesTokens(List<RawMessage> messages, String model) async {
    int total = 0;
    for (final msg in messages) {
      // 消息格式开销估算
      total += await countTokens(msg.content, model);
      total += 4;  // 格式开销（<|im_start|> 等）
    }
    return total;
  }
  
  MuseProviderException _mapOllamaError(OllamaException error) {
    return switch (error.statusCode) {
      404 => MuseProviderException(
          code: MuseErrorCode.modelNotFound,
          message: '本地模型不存在，请先执行 ollama pull',
          providerErrorCode: 'model_not_found',
          isRetryable: false,
        ),
      500 => MuseProviderException(
          code: MuseErrorCode.providerServerError,
          message: 'Ollama 服务内部错误: ${error.message}',
          providerErrorCode: 'internal_error',
          isRetryable: true,
        ),
      _ => MuseProviderException(
          code: MuseErrorCode.providerServerError,
          message: error.message,
          providerErrorCode: error.statusCode?.toString(),
          isRetryable: true,
        ),
    };
  }
}

/// Ollama 流式迭代器
class OllamaIterator implements LLMIterator {
  final OllamaClient _client;
  final Tokenizer _tokenizer;
  final ModelConfig _config;
  final List<RawMessage> _messages;
  final GenerationOptions _options;
  
  Stream<OllamaGenerateResponse>? _stream;
  StreamIterator<OllamaGenerateResponse>? _iterator;
  bool _cancelled = false;
  bool _ended = false;
  int _chunkIndex = 0;
  String _accumulatedContent = '';
  int _promptTokens = 0;
  
  OllamaIterator({
    required OllamaClient client,
    required Tokenizer tokenizer,
    required ModelConfig config,
    required List<RawMessage> messages,
    GenerationOptions? options,
  })  : _client = client,
        _tokenizer = tokenizer,
        _config = config,
        _messages = messages,
        _options = options ?? const GenerationOptions();
  
  @override
  Future<LLMChunk?> next() async {
    if (_cancelled || _ended) return null;
    
    try {
      if (_stream == null) {
        // 预估 prompt tokens
        _promptTokens = await _countMessagesTokens();
        
        _stream = _client.generateStream(
          model: _config.model,
          messages: _messages.map((m) => OllamaMessage(
            role: m.role.name,
            content: m.content,
          )).toList(),
          options: OllamaRequestOptions(
            temperature: _options.temperature ?? 0.7,
            numPredict: _options.maxTokens ?? 128,
            topP: _options.topP ?? 0.9,
          ),
        );
        _iterator = StreamIterator(_stream!);
      }
      
      final hasNext = await _iterator!.moveNext();
      if (!hasNext) {
        _ended = true;
        return null;
      }
      
      final response = _iterator!.current;
      _accumulatedContent += response.message.content;
      
      final isLast = response.done;
      if (isLast) {
        _ended = true;
      }
      
      return LLMChunk(
        content: response.message.content,
        index: _chunkIndex++,
        isLast: isLast,
        usage: isLast ? await _calculateFinalUsage() : null,
        timestamp: DateTime.now(),
      );
    } on OllamaException catch (e) {
      throw _mapOllamaError(e);
    }
  }
  
  Future<TokenUsage> _calculateFinalUsage() async {
    final completionTokens = await _tokenizer.encode(_accumulatedContent);
    return TokenUsage(
      promptTokens: _promptTokens,
      completionTokens: completionTokens.length,
      totalTokens: _promptTokens + completionTokens.length,
    );
  }
  
  Future<int> _countMessagesTokens() async {
    int total = 0;
    for (final msg in _messages) {
      total += (await _tokenizer.encode(msg.content)).length;
      total += 4;
    }
    return total;
  }
  
  @override
  Future<void> cancel() async {
    _cancelled = true;
    await _iterator?.cancel();
  }
  
  @override
  bool get hasNext => !_cancelled && !_ended;
  
  MuseProviderException _mapOllamaError(OllamaException error) {
    // 同 OllamaAdapter
  }
}
```

---

## 6. 通用 OpenAI-Compatible 适配器

### 6.1 设计目的

许多 Provider（如 Azure OpenAI、Groq、Together AI）提供 OpenAI 兼容的 API。此适配器通过配置化方式支持这些 Provider，无需为每个创建独立适配器。

### 6.2 实现代码

```dart
/// 通用 OpenAI-Compatible 适配器
class GenericOpenAIAdapter extends OpenAIAdapter {
  final ProviderConfig _config;
  
  GenericOpenAIAdapter({
    required OpenAIClient client,
    required ProviderConfig config,
  })  : _config = config,
        super(client: client, config: config);
  
  @override
  String get providerType => _config.providerId;  // 使用配置的 ID
  
  @override
  Future<List<ModelInfo>> listModels() async {
    // 如果配置中提供了固定模型列表，直接返回
    if (_config.fixedModels != null) {
      return _config.fixedModels!.map((m) => ModelInfo(
        id: m.id,
        name: m.name,
        provider: providerType,
        capabilities: m.capabilities,
      )).toList();
    }
    
    // 否则尝试从 API 获取
    return super.listModels();
  }
  
  @override
  MuseProviderException _mapOpenAIError(OpenAIException error) {
    // 可以添加 Provider 特定的错误码映射
    final customMapping = _config.errorCodeMapping?[error.code];
    if (customMapping != null) {
      return MuseProviderException(
        code: customMapping,
        message: error.message,
        providerErrorCode: error.code,
        isRetryable: _isRetryable(customMapping),
      );
    }
    
    return super._mapOpenAIError(error);
  }
  
  bool _isRetryable(MuseErrorCode code) {
    return switch (code) {
      MuseErrorCode.rateLimitExceeded ||
      MuseErrorCode.networkTimeout ||
      MuseErrorCode.providerServerError => true,
      _ => false,
    };
  }
}
```

---

## 7. 适配器工厂与注册

### 7.1 工厂实现

```dart
/// Provider 适配器工厂
class ProviderAdapterRegistry {
  final Map<String, ProviderAdapterFactory> _factories = {};
  
  /// 注册适配器工厂
  void register(ProviderAdapterFactory factory) {
    _factories[factory.providerType] = factory;
  }
  
  /// 创建适配器
  ProviderAdapter createAdapter(ProviderConfig config) {
    final factory = _factories[config.type];
    if (factory == null) {
      throw MuseProviderException(
        code: MuseErrorCode.invalidConfiguration,
        message: 'Unknown provider type: ${config.type}',
        isRetryable: false,
      );
    }
    return factory.createAdapter(config);
  }
  
  /// 检查是否支持某 Provider 类型
  bool isSupported(String type) => _factories.containsKey(type);
  
  /// 获取支持的类型列表
  List<String> get supportedTypes => _factories.keys.toList();
}

/// 初始化注册表
ProviderAdapterRegistry initializeAdapterRegistry() {
  final registry = ProviderAdapterRegistry();
  
  registry.register(OpenAIFactory());
  registry.register(AnthropicFactory());
  registry.register(OllamaFactory());
  registry.register(GenericOpenAIFactory());
  
  return registry;
}
```

### 7.2 各 Provider 工厂实现

```dart
class OpenAIFactory implements ProviderAdapterFactory {
  @override
  String get providerType => 'openai';
  
  @override
  ProviderAdapter createAdapter(ProviderConfig config) {
    final client = OpenAIClient(
      apiKey: config.apiKey,
      baseUrl: config.baseUrl ?? 'https://api.openai.com/v1',
      timeout: config.timeout ?? const Duration(seconds: 60),
    );
    return OpenAIAdapter(client: client, config: config);
  }
}

class AnthropicFactory implements ProviderAdapterFactory {
  @override
  String get providerType => 'anthropic';
  
  @override
  ProviderAdapter createAdapter(ProviderConfig config) {
    final client = AnthropicClient(
      apiKey: config.apiKey,
      baseUrl: config.baseUrl ?? 'https://api.anthropic.com',
      version: '2023-06-01',
    );
    return AnthropicAdapter(client: client, config: config);
  }
}

class OllamaFactory implements ProviderAdapterFactory {
  @override
  String get providerType => 'ollama';
  
  @override
  ProviderAdapter createAdapter(ProviderConfig config) {
    final client = OllamaClient(
      baseUrl: config.baseUrl ?? 'http://localhost:11434',
    );
    final tokenizer = TiktokenTokenizer();  // 或 llama_tokenizer
    return OllamaAdapter(
      client: client,
      config: config,
      tokenizer: tokenizer,
    );
  }
}

class GenericOpenAIFactory implements ProviderAdapterFactory {
  @override
  String get providerType => 'openai-compatible';
  
  @override
  ProviderAdapter createAdapter(ProviderConfig config) {
    final client = OpenAIClient(
      apiKey: config.apiKey,
      baseUrl: config.baseUrl,
      timeout: config.timeout ?? const Duration(seconds: 60),
    );
    return GenericOpenAIAdapter(client: client, config: config);
  }
}
```

---

## 8. 配置模型

```dart
/// Provider 配置
class ProviderConfig {
  final String providerId;       // 唯一标识，如 "openai-primary"
  final String type;             // 类型，如 "openai", "anthropic"
  final String? displayName;     // 显示名称
  final String apiKey;           // API Key
  final String? baseUrl;         // 自定义 Base URL
  final Duration? timeout;       // 超时设置
  final Map<String, dynamic>? extraHeaders;  // 额外请求头
  final List<FixedModelConfig>? fixedModels; // 固定模型列表（用于兼容 Provider）
  final Map<String, MuseErrorCode>? errorCodeMapping;  // 错误码映射
  
  ProviderConfig({
    required this.providerId,
    required this.type,
    this.displayName,
    required this.apiKey,
    this.baseUrl,
    this.timeout,
    this.extraHeaders,
    this.fixedModels,
    this.errorCodeMapping,
  });
}

/// 固定模型配置（用于 Generic OpenAI-Compatible）
class FixedModelConfig {
  final String id;
  final String name;
  final ModelCapabilities capabilities;
  
  FixedModelConfig({
    required this.id,
    required this.name,
    required this.capabilities,
  });
}

/// 模型能力
class ModelCapabilities {
  final bool streaming;
  final bool functionCalling;
  final bool vision;
  final bool jsonMode;
  
  ModelCapabilities({
    required this.streaming,
    required this.functionCalling,
    required this.vision,
    required this.jsonMode,
  });
}

/// 模型信息
class ModelInfo {
  final String id;
  final String name;
  final String provider;
  final ModelCapabilities capabilities;
  
  ModelInfo({
    required this.id,
    required this.name,
    required this.provider,
    required this.capabilities,
  });
}

/// 健康状态
class HealthStatus {
  final bool isHealthy;
  final String? message;
  final DateTime checkedAt;
  
  HealthStatus._(this.isHealthy, this.message) : checkedAt = DateTime.now();
  
  factory HealthStatus.healthy() => HealthStatus._(true, null);
  factory HealthStatus.unhealthy(String message) => HealthStatus._(false, message);
}
```

---

## 9. 使用示例

```dart
void main() async {
  // 1. 初始化适配器注册表
  final registry = initializeAdapterRegistry();
  
  // 2. 创建 Provider 配置
  final openaiConfig = ProviderConfig(
    providerId: 'openai-primary',
    type: 'openai',
    apiKey: 'sk-xxx',
  );
  
  final anthropicConfig = ProviderConfig(
    providerId: 'anthropic-backup',
    type: 'anthropic',
    apiKey: 'sk-ant-xxx',
  );
  
  // 3. 创建适配器
  final openaiAdapter = registry.createAdapter(openaiConfig);
  final anthropicAdapter = registry.createAdapter(anthropicConfig);
  
  // 4. 执行流式生成
  final iterator = openaiAdapter.createIterator(
    modelConfig: ModelConfig(model: 'gpt-4'),
    messages: [
      RawMessage(role: MessageRole.system, content: 'You are helpful.'),
      RawMessage(role: MessageRole.user, content: 'Hello!'),
    ],
  );
  
  // 5. 消费流
  while (iterator.hasNext) {
    final chunk = await iterator.next();
    if (chunk != null) {
      print(chunk.content);
      if (chunk.isLast) {
        print('Usage: ${chunk.usage}');
      }
    }
  }
}
```

---

## 10. 后续工作

- [ ] 实现 Azure OpenAI 专用适配器（支持 Azure AD 认证）
- [ ] 实现 Google Gemini 适配器
- [ ] 添加工具调用（Function Calling）标准化支持
- [ ] 实现多模态输入（图片、音频）标准化接口

---

**最后更新**: 2026-02-26  
**维护者**: Clotho 架构团队
