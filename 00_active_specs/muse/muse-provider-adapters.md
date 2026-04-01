# Muse Provider 适配器规范

**版本**: 1.1.0
**日期**: 2026-03-11
**状态**: Active
**作者**: Clotho 架构团队
**关联文档**:
- [Muse 智能服务架构](README.md) - Muse 服务概览
- [流式响应与计费设计](streaming-and-billing-design.md) - LLMIterator 接口定义
- [ClothoNexus 事件总线](../infrastructure/clotho-nexus-events.md) - 事件集成

> 术语体系参见 [naming-convention.md](../naming-convention.md)

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

### 3.1 OpenAI 错误码映射表

| OpenAI 错误码 | Muse 标准错误 | 可重试 | 说明 |
|--------------|--------------|--------|------|
| `rate_limit_exceeded` | `rateLimitExceeded` | Yes | 请求频率超限 |
| `insufficient_quota` | `quotaExceeded` | No | API 配额已用尽 |
| `invalid_api_key` | `invalidApiKey` | No | API Key 无效 |
| `context_length_exceeded` | `contextLengthExceeded` | No | 上下文长度超限 |
| 其他 | `providerServerError` | Yes | 兜底映射 |

### 3.2 OpenAI FinishReason 映射

| OpenAI FinishReason | Muse FinishReason | 说明 |
|---------------------|-------------------|------|
| `stop` | `completed` | 正常完成 |
| `length` | `maxTokensReached` | 达到最大 Token 数 |
| `content_filter` | `contentFiltered` | 内容被安全过滤 |

### 3.3 OpenAI 适配器接口

```dart
/// OpenAI Provider 适配器
/// 实现 ProviderAdapter 接口，作为所有适配器的参考实现
class OpenAIAdapter implements ProviderAdapter {
  OpenAIAdapter({required OpenAIClient client, required ProviderConfig config});

  @override
  String get providerType; // => 'openai'

  @override
  LLMIterator createIterator({
    required ModelConfig modelConfig,
    required List<RawMessage> messages,
    GenerationOptions? options,
  }); // => OpenAIIterator(...)

  @override
  Future<LLMResponse> execute({...}); // 非流式生成，调用 createChatCompletion

  @override
  Future<HealthStatus> checkHealth(); // 通过 listModels 探测

  @override
  Future<List<ModelInfo>> listModels(); // 过滤 gpt-* 模型，推断能力

  @override
  Future<int> countTokens(String text, String model); // throw UnsupportedError

  /// 消息格式转换: RawMessage -> OpenAIChatMessage
  /// 角色映射: system/user/assistant/tool 一一对应
  /// 错误映射: 见 3.1 映射表
}
```

### 3.4 OpenAI 流式迭代器

```dart
/// OpenAI 流式迭代器
/// 通过 SSE 流拉取 chunk，首个 next() 调用时惰性初始化流连接
class OpenAIIterator implements LLMIterator {
  OpenAIIterator({
    required OpenAIClient client,
    required ModelConfig config,
    required List<RawMessage> messages,
    GenerationOptions? options,
  });

  @override
  Future<LLMChunk?> next(); // 拉取下一个 SSE chunk；最后一个 chunk 携带 usage
  @override
  Future<void> cancel(); // 标记取消并关闭 StreamIterator
  @override
  bool get hasNext; // => !_cancelled && !_ended
}
```

> **设计说明**: OpenAI 流式响应在最后一个 chunk 的 `finishReason` 非空时标记结束。`usage` 通常由最终 chunk 返回，若缺失则需估算。具体实现见代码仓库。

---

## 4. Anthropic 适配器

### 4.1 关键差异点

Anthropic API 与 OpenAI 的主要差异：

1. **消息格式**: Anthropic 使用 `messages` + `system` 分离，而非 system 作为 role
2. **流式格式**: SSE 事件结构不同，`data: {"type": "content_block_delta", ...}`
3. **Token 计数**: 在消息结束时通过 `message_stop` 事件返回
4. **错误码**: 使用 `overloaded_error` 表示服务器负载过高

### 4.2 Anthropic 错误码映射表

| Anthropic 错误类型 | Muse 标准错误 | 可重试 | 说明 |
|-------------------|--------------|--------|------|
| `rate_limit_error` | `rateLimitExceeded` | Yes | 请求频率超限 |
| `overloaded_error` | `providerServerError` | Yes | Anthropic 特有，服务器负载过高 |
| `invalid_request_error` | `invalidConfiguration` | No | 请求参数无效 |
| `authentication_error` | `invalidApiKey` | No | API Key 无效 |
| 其他 | `providerServerError` | Yes | 兜底映射 |

### 4.3 Anthropic FinishReason 映射

| Anthropic StopReason | Muse FinishReason | 说明 |
|----------------------|-------------------|------|
| `end_turn` | `completed` | 正常完成 |
| `max_tokens` | `maxTokensReached` | 达到最大 Token 数 |
| `stop_sequence` | `completed` | 命中自定义停止序列 |

### 4.4 Anthropic 适配器接口

```dart
/// Anthropic Provider 适配器
class AnthropicAdapter implements ProviderAdapter {
  AnthropicAdapter({required AnthropicClient client, required ProviderConfig config});

  @override
  String get providerType; // => 'anthropic'

  @override
  LLMIterator createIterator({...}); // => AnthropicIterator(...)

  @override
  Future<LLMResponse> execute({...});
  // 关键行为: 调用前需将 system message 从 messages 中分离，
  // 通过独立的 `system` 参数传递给 Anthropic API

  @override
  Future<HealthStatus> checkHealth(); // Anthropic 无独立 health API，通过 listModels 探测

  @override
  Future<List<ModelInfo>> listModels();
  // 返回固定模型列表: claude-3-opus, claude-3-sonnet, claude-3-haiku
  // 所有模型均支持: streaming, functionCalling, vision, jsonMode

  @override
  Future<int> countTokens(String text, String model);
  // Anthropic 提供专用 Token 计数 API，可直接调用

  /// 消息格式转换: 需将 system role 从 messages 中提取为独立参数
  /// 角色映射: user/assistant 直接映射；system/tool 需特殊处理
  /// 错误映射: 见 4.2 映射表
}
```

### 4.5 Anthropic 流式迭代器

```dart
/// Anthropic 流式迭代器
/// SSE 事件驱动：按事件类型分发处理
class AnthropicIterator implements LLMIterator {
  AnthropicIterator({
    required AnthropicClient client,
    required ModelConfig config,
    required List<RawMessage> messages,
    GenerationOptions? options,
  });

  @override
  Future<LLMChunk?> next();
  // SSE 事件类型分发:
  //   'content_block_delta' -> 返回内容 chunk
  //   'message_delta'       -> 提取 usage 信息，递归获取下一个
  //   'message_stop'        -> 返回最终 chunk (携带累积 usage)
  //   'ping' / 其他          -> 忽略，递归获取下一个

  @override
  Future<void> cancel();
  @override
  bool get hasNext; // => !_cancelled && !_ended
}
```

> **设计说明**: Anthropic 的 SSE 事件模型与 OpenAI 差异显著 — 不是每个事件都包含内容，需按 `type` 字段分发处理。`usage` 信息在 `message_delta` 事件中单独返回，需在 `message_stop` 时合并发出。具体实现见代码仓库。

---

## 5. Ollama (Local LLM) 适配器

### 5.1 特殊考量

Local LLM 的特殊性：
- **无内置 Token 计数**: 需要使用 Tiktoken 等库估算
- **无计费**: 成本为 0，但仍需记录使用量
- **模型发现**: 通过 `/api/tags` 动态发现本地模型
- **无速率限制**: 但可能有并发限制

### 5.2 Ollama 错误码映射表

| Ollama HTTP 状态码 | Muse 标准错误 | 可重试 | 说明 |
|-------------------|--------------|--------|------|
| 404 | `modelNotFound` | No | 本地模型不存在，需先 `ollama pull` |
| 500 | `providerServerError` | Yes | Ollama 服务内部错误 |
| 其他 | `providerServerError` | Yes | 兜底映射 |

### 5.3 Ollama 适配器接口

```dart
/// Ollama (Local LLM) Provider 适配器
/// 特殊依赖: Tokenizer（Tiktoken 或 llama_tokenizer）用于本地 Token 估算
class OllamaAdapter implements ProviderAdapter {
  OllamaAdapter({
    required OllamaClient client,
    required ProviderConfig config,
    required Tokenizer tokenizer,  // Tiktoken 或类似实现
  });

  @override
  String get providerType; // => 'ollama'

  @override
  LLMIterator createIterator({...}); // => OllamaIterator(...)

  @override
  Future<LLMResponse> execute({...});
  // 关键行为: Token 计数通过本地 Tokenizer 估算，非 API 返回
  // 每条消息额外加 4 tokens 格式开销（如 <|im_start|> 标记）

  @override
  Future<HealthStatus> checkHealth(); // 通过 listModels 探测

  @override
  Future<List<ModelInfo>> listModels();
  // 通过 Ollama /api/tags 动态发现本地模型
  // 视觉能力根据模型 families 中是否包含 'clip' 推断
  // functionCalling / jsonMode 默认 false（取决于模型和 Ollama 版本）

  @override
  Future<int> countTokens(String text, String model);
  // 使用 Tiktoken 本地估算，非远程 API 调用

  /// 消息格式: role 直接使用 .name 字符串（如 "user", "assistant"）
  /// 错误映射: 见 5.2 映射表
}
```

### 5.4 Ollama 流式迭代器

```dart
/// Ollama 流式迭代器
/// 与远程 Provider 的关键区别: 首次 next() 时需预估算 prompt tokens
class OllamaIterator implements LLMIterator {
  OllamaIterator({
    required OllamaClient client,
    required Tokenizer tokenizer,
    required ModelConfig config,
    required List<RawMessage> messages,
    GenerationOptions? options,
  });

  @override
  Future<LLMChunk?> next();
  // 行为: 累积所有 chunk 内容，最终 chunk 时通过 Tokenizer 估算完整 usage
  // Ollama 的 response.done == true 标记流结束

  @override
  Future<void> cancel();
  @override
  bool get hasNext; // => !_cancelled && !_ended
}
```

> **设计说明**: Ollama 作为本地 LLM 不提供 Token 计数 API，需在流结束时对累积内容进行本地 Token 估算。成本始终为 0，但仍需记录使用量以支持用量统计。具体实现见代码仓库。

---

## 6. 通用 OpenAI-Compatible 适配器

### 6.1 设计目的

许多 Provider（如 Azure OpenAI、Groq、Together AI）提供 OpenAI 兼容的 API。此适配器通过配置化方式支持这些 Provider，无需为每个创建独立适配器。

### 6.2 GenericOpenAIAdapter 接口

```dart
/// 通用 OpenAI-Compatible 适配器
/// 继承 OpenAIAdapter，通过配置化方式支持 Azure OpenAI、Groq、Together AI 等
class GenericOpenAIAdapter extends OpenAIAdapter {
  GenericOpenAIAdapter({required OpenAIClient client, required ProviderConfig config});

  @override
  String get providerType; // => _config.providerId（使用配置中的自定义 ID）

  @override
  Future<List<ModelInfo>> listModels();
  // 优先使用 config.fixedModels（固定模型列表），若无则 fallback 到 API 查询

  /// 错误映射扩展: 先查 config.errorCodeMapping 自定义映射，
  /// 未命中则 fallback 到父类 OpenAI 标准映射
}
```

> **设计说明**: 该适配器的核心价值在于通过 `ProviderConfig` 的 `fixedModels` 和 `errorCodeMapping` 两个字段，以配置化方式适配不同的 OpenAI 兼容 Provider，无需为每个 Provider 编写独立适配器类。具体实现见代码仓库。

---

## 7. 适配器工厂与注册

### 7.1 注册表接口

```dart
/// Provider 适配器注册表
class ProviderAdapterRegistry {
  final Map<String, ProviderAdapterFactory> _factories = {};

  void register(ProviderAdapterFactory factory);   // 注册工厂，key 为 providerType
  ProviderAdapter createAdapter(ProviderConfig config); // 创建适配器，未知类型抛 invalidConfiguration
  bool isSupported(String type);                   // 检查是否支持某类型
  List<String> get supportedTypes;                 // 获取所有已注册类型
}
```

### 7.2 各 Provider 工厂注册

初始化时注册以下工厂（默认 baseUrl 和特殊参数）：

| Factory 类 | providerType | 默认 Base URL | 特殊参数 |
|------------|-------------|---------------|---------|
| `OpenAIFactory` | `openai` | `https://api.openai.com/v1` | timeout: 60s |
| `AnthropicFactory` | `anthropic` | `https://api.anthropic.com` | version: `2023-06-01` |
| `OllamaFactory` | `ollama` | `http://localhost:11434` | 需注入 `TiktokenTokenizer` |
| `GenericOpenAIFactory` | `openai-compatible` | 由 config.baseUrl 指定 | — |

```dart
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

> 具体工厂实现见代码仓库。

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
// 1. 初始化注册表
final registry = initializeAdapterRegistry();

// 2. 创建配置 & 适配器
final adapter = registry.createAdapter(ProviderConfig(
  providerId: 'openai-primary',
  type: 'openai',
  apiKey: 'sk-xxx',
));

// 3. 流式生成
final iterator = adapter.createIterator(
  modelConfig: ModelConfig(model: 'gpt-4'),
  messages: [
    RawMessage(role: MessageRole.system, content: 'You are helpful.'),
    RawMessage(role: MessageRole.user, content: 'Hello!'),
  ],
);

// 4. 消费流
while (iterator.hasNext) {
  final chunk = await iterator.next();
  if (chunk != null) {
    print(chunk.content);
    if (chunk.isLast) print('Usage: ${chunk.usage}');
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

**最后更新**: 2026-04-02
**维护者**: Clotho 架构团队
