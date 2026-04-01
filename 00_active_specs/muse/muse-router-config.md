# Muse 模型路由配置规范

**版本**: 1.1.0
**日期**: 2026-03-11
**状态**: Active
**作者**: Clotho 架构团队
**关联文档**:
- [Muse 智能服务架构](README.md) - Muse 服务概览
- [Provider 适配器规范](muse-provider-adapters.md) - Provider 适配器实现
- [流式响应与计费设计](streaming-and-billing-design.md) - Token 计费与流式处理

> 术语体系参见 [naming-convention.md](../naming-convention.md)

---

## 1. 概述

模型路由是 Muse 智能服务的核心组件，负责根据配置策略将 LLM 请求分发到合适的 Provider 和模型。它提供了负载均衡、故障转移、成本控制等关键能力，确保系统在面对多个 Provider 时能够稳定、高效、经济地运行。

### 1.1 设计目标

- **智能路由**: 根据模型能力、成本、延迟等因素智能选择最优 Provider
- **故障转移**: Provider 故障时自动切换到备用节点
- **负载均衡**: 在多 Key 或多节点间均衡请求
- **成本控制**: 支持预算限制和成本优化策略
- **灵活配置**: 通过 YAML 配置文件动态调整路由策略，无需重启

### 1.2 核心概念

| 概念 | 说明 | 示例 |
|------|------|------|
| **Provider** | LLM 服务提供商实例 | OpenAI 主账号、Anthropic 备用账号 |
| **Model Alias** | 模型别名（抽象层） | "smart" → gpt-4 / claude-3-opus |
| **Routing Strategy** | 路由策略 | priority、round_robin、latency_based |
| **Fallback** | 故障转移配置 | 当 Provider A 失败时切换到 Provider B |
| **Quota** | 配额限制 | 每分钟最多 60 请求，每月最多 $100 |

---

## 2. 配置文件规范

### 2.1 文件位置与加载

```
配置路径: <AppData>/muse/router_config.yaml
备份路径: <AppData>/muse/router_config.yaml.bak
```

配置文件支持热重载，修改后 30 秒内自动生效（或通过 API 触发立即重载）。

### 2.2 完整配置 Schema

```yaml
# router_config.yaml
version: "1.0"

# ==================== Provider 定义 ====================
providers:
  # OpenAI 主账号
  - id: openai-primary
    name: "OpenAI 主账号"
    type: openai
    enabled: true
    config:
      api_key: "${OPENAI_API_KEY}"  # 支持环境变量
      base_url: "https://api.openai.com/v1"
      timeout: 60s
    models:
      - id: gpt-4o
        name: "GPT-4o"
        enabled: true
        capabilities: [streaming, function_calling, vision, json_mode]
        pricing:
          input: 0.005    # $0.005 per 1K tokens
          output: 0.015   # $0.015 per 1K tokens
          currency: USD
      - id: gpt-4o-mini
        name: "GPT-4o Mini"
        enabled: true
        capabilities: [streaming, function_calling, vision, json_mode]
        pricing:
          input: 0.00015
          output: 0.0006
          currency: USD
      - id: gpt-3.5-turbo
        name: "GPT-3.5 Turbo"
        enabled: true
        capabilities: [streaming, function_calling, json_mode]
        pricing:
          input: 0.0005
          output: 0.0015
          currency: USD
    quotas:
      requests_per_minute: 60
      tokens_per_minute: 150000
      monthly_budget: 100.00  # USD
    health_check:
      enabled: true
      interval: 30s
      timeout: 10s
      retries: 3

  # Anthropic 备用账号
  - id: anthropic-backup
    name: "Anthropic 备用"
    type: anthropic
    enabled: true
    config:
      api_key: "${ANTHROPIC_API_KEY}"
      base_url: "https://api.anthropic.com"
    models:
      - id: claude-3-opus-20240229
        name: "Claude 3 Opus"
        enabled: true
        capabilities: [streaming, function_calling, vision, json_mode]
        pricing:
          input: 0.015
          output: 0.075
          currency: USD
      - id: claude-3-sonnet-20240229
        name: "Claude 3 Sonnet"
        enabled: true
        capabilities: [streaming, function_calling, vision, json_mode]
        pricing:
          input: 0.003
          output: 0.015
          currency: USD
      - id: claude-3-haiku-20240307
        name: "Claude 3 Haiku"
        enabled: true
        capabilities: [streaming, function_calling, vision, json_mode]
        pricing:
          input: 0.00025
          output: 0.00125
          currency: USD
    quotas:
      requests_per_minute: 50
      monthly_budget: 50.00
    health_check:
      enabled: true
      interval: 60s

  # Ollama 本地模型
  - id: ollama-local
    name: "Ollama 本地"
    type: ollama
    enabled: true
    config:
      base_url: "http://localhost:11434"
    models:
      - id: llama3.1:8b
        name: "Llama 3.1 8B"
        enabled: true
        capabilities: [streaming]
        pricing:
          input: 0
          output: 0
          currency: USD
    health_check:
      enabled: true
      interval: 10s

  # Groq (OpenAI-Compatible)
  - id: groq-speed
    name: "Groq 高速"
    type: openai-compatible
    enabled: true
    config:
      api_key: "${GROQ_API_KEY}"
      base_url: "https://api.groq.com/openai/v1"
    models:
      - id: llama-3.1-70b-versatile
        name: "Llama 3.1 70B"
        enabled: true
        capabilities: [streaming, function_calling, json_mode]
        pricing:
          input: 0.00059
          output: 0.00079
          currency: USD

# ==================== 模型别名 ====================
model_aliases:
  # 智能模型（最高质量）
  smart:
    description: "最高质量的模型，用于复杂推理"
    candidates:
      - model: gpt-4o
        provider: openai-primary
        priority: 1
      - model: claude-3-opus-20240229
        provider: anthropic-backup
        priority: 2
    selection_criteria:
      - availability
      - latency
      - cost

  # 平衡模型（质量与成本平衡）
  balanced:
    description: "质量与成本平衡的模型"
    candidates:
      - model: gpt-4o-mini
        provider: openai-primary
        priority: 1
      - model: claude-3-sonnet-20240229
        provider: anthropic-backup
        priority: 2
      - model: llama-3.1-70b-versatile
        provider: groq-speed
        priority: 3

  # 快速模型（低成本、低延迟）
  fast:
    description: "快速响应模型，用于简单任务"
    candidates:
      - model: gpt-3.5-turbo
        provider: openai-primary
        priority: 1
      - model: claude-3-haiku-20240307
        provider: anthropic-backup
        priority: 2
      - model: llama3.1:8b
        provider: ollama-local
        priority: 3

  # 视觉模型（支持图像理解）
  vision:
    description: "支持图像理解的模型"
    capabilities_required: [vision]
    candidates:
      - model: gpt-4o
        provider: openai-primary
        priority: 1
      - model: claude-3-opus-20240229
        provider: anthropic-backup
        priority: 2

  # 本地模型（隐私优先）
  local:
    description: "本地运行的模型，数据不出境"
    candidates:
      - model: llama3.1:8b
        provider: ollama-local
        priority: 1
    fallback_policy: none  # 本地模型失败时不fallback到云端

# ==================== 路由策略 ====================
routing:
  # 默认策略
  default_strategy: priority
  
  # 策略定义
  strategies:
    # 优先级策略：按优先级顺序选择第一个可用 Provider
    priority:
      type: priority
      description: "按优先级顺序选择"
      config:
        skip_unhealthy: true
        skip_over_quota: true
    
    # 轮询策略：在可用 Provider 间轮流分配
    round_robin:
      type: round_robin
      description: "轮询负载均衡"
      config:
        skip_unhealthy: true
        reset_interval: 1m
    
    # 延迟策略：选择响应延迟最低的 Provider
    latency_based:
      type: latency_based
      description: "基于延迟的动态路由"
      config:
        measurement_window: 5m
        percentile: 90  # 使用 P90 延迟
        penalty_per_error: 500ms  # 每次错误增加惩罚延迟
    
    # 成本策略：选择成本最低的可用 Provider
    cost_optimized:
      type: cost_optimized
      description: "成本优化路由"
      config:
        max_latency_penalty: 2.0  # 延迟超过2倍则忽略成本优势
    
    # 加权随机策略：按权重随机选择（用于 A/B 测试）
    weighted_random:
      type: weighted_random
      description: "加权随机选择"
      config:
        weights:
          openai-primary: 70
          anthropic-backup: 30

# ==================== 故障转移 ====================
fallback:
  # 全局故障转移配置
  enabled: true
  max_retries: 3
  retry_delay: 1s
  exponential_backoff: true
  
  # 故障转移触发条件
  trigger_conditions:
    - error_code: rate_limit_exceeded
      retry_after_header: true
    - error_code: provider_server_error
      max_retries: 2
    - error_code: network_timeout
      max_retries: 3
    - error_code: context_length_exceeded  # 不触发 fallback，直接报错
      fallback: false

# ==================== 全局限制 ====================
global_limits:
  # 全局速率限制
  rate_limits:
    requests_per_minute: 200
    tokens_per_minute: 500000
  
  # 全局预算
  budget:
    daily: 50.00
    monthly: 500.00
    currency: USD
    action_on_exceed: block  # block | warn | throttle
  
  # 全局超时
  timeouts:
    connection: 30s
    request: 120s
    streaming_chunk: 30s  # 流式传输中两个 chunk 之间的最大间隔

# ==================== 日志与监控 ====================
logging:
  level: info  # debug | info | warn | error
  include_request_body: false  # 是否记录请求内容（注意隐私）
  include_response_body: false
  slow_request_threshold: 10s  # 超过此时间的请求记录为慢请求

metrics:
  enabled: true
  export_interval: 60s
  collectors:
    - request_count
    - latency_histogram
    - token_usage
    - error_rate
    - cost_per_minute
```

---

## 3. 核心组件设计

### 3.1 路由管理器

```dart
/// 模型路由管理器
///
/// 核心路由流程：
/// 1. _resolveCandidates(alias, requiredCaps) —— 解析模型别名为候选列表，过滤不满足能力要求的候选
/// 2. _filterAvailable(candidates) —— 过滤不健康和配额已满的 Provider
/// 3. _getStrategy(strategyName) —— 获取路由策略（默认为 priority）
/// 4. strategy.select(availableCandidates, request) —— 按策略选择最优候选
/// 5. _quotaTracker.checkQuota() —— 最终配额检查
///
/// 故障转移流程：
/// - fallback(request, failedAttempt, error) → 检查是否应触发 fallback → 标记失败 Provider → 排除后重新路由
///
/// 接口签名：
class ModelRouter {
  final RouterConfig _config;
  final ProviderAdapterRegistry _adapterRegistry;
  final HealthMonitor _healthMonitor;
  final QuotaTracker _quotaTracker;
  final LatencyTracker _latencyTracker;

  Future<RoutingResult> route(RoutingRequest request);
  Future<RoutingResult> fallback(RoutingRequest request, RoutingResult failedAttempt, MuseProviderException error);
}

/// 路由请求
class RoutingRequest {
  final String modelAlias;              // "smart", "fast", 或 "gpt-4o@openai-primary"
  final List<String>? requiredCapabilities;
  final String? strategy;
  final Set<String> excludedProviders;
  final double? maxCostPer1K;
  final Duration? maxLatency;
  RoutingRequest copyWith({Set<String>? excludedProviders});
}

/// 路由结果
class RoutingResult {
  final String providerId;
  final String modelId;
  final ProviderAdapter provider;
}

/// Provider 实例包装
class ProviderInstance {
  final ProviderConfig config;
  final ProviderAdapter adapter;
}
// 具体实现见代码仓库
```

### 3.2 路由策略实现

```dart
/// 路由策略接口
abstract class RoutingStrategy {
  Future<ModelCandidate> select(List<ModelCandidate> candidates, RoutingRequest request);
}
```

**策略实现概要**（详细算法见代码仓库）：

| 策略 | 行为 | 核心逻辑 |
|------|------|---------|
| `PriorityStrategy` | 按优先级排序，选择第一个 | `candidates.sort(by priority).first` |
| `RoundRobinStrategy` | 轮询负载均衡 | 按 modelAlias 维护计数器，`candidates[count % length]` |
| `LatencyBasedStrategy` | 选择延迟最低的 Provider | 从 LatencyTracker 获取 P90 延迟，选最小值；无数据时默认 10s |
| `CostOptimizedStrategy` | 成本效率最优 | 成本效率 = `1 / (cost * latencyFactor)`，latencyFactor 超 `_maxLatencyPenalty` 则排除 |
| `WeightedRandomStrategy` | 加权随机选择（A/B 测试） | 按 config 中 weights 配置进行加权随机 |

```
// 具体实现见代码仓库
```

### 3.3 健康监控

```dart
/// 健康监控器接口
///
/// 职责：
/// - 定期对 Provider 执行健康检查（通过 adapter.checkHealth()）
/// - 维护每个 Provider 的健康状态（ProviderHealth），连续失败 >= 3 次标记为不健康
/// - 关键错误（invalidApiKey, quotaExceeded）直接标记不健康
/// - 状态变化时通过 onHealthChanged 流广播 HealthEvent
///
/// 接口签名：
class HealthMonitor {
  Future<void> checkHealth(String providerId, ProviderAdapter adapter);
  void recordFailure(String providerId, MuseProviderException error);
  Future<bool> isHealthy(String providerId);
  Stream<HealthEvent> onHealthChanged(String providerId);
}

/// Provider 健康状态
class ProviderHealth {
  final String providerId;
  final HealthStatus status;
  final DateTime lastChecked;
  bool get isHealthy;          // status.isHealthy && _consecutiveFailures < 3
  void recordFailure();       // _consecutiveFailures++
  void recordSuccess();       // _consecutiveFailures = 0
}

/// 健康事件
class HealthEvent {
  final String providerId;
  final HealthStatus status;
  final DateTime timestamp;
}
// 具体实现见代码仓库
```

### 3.4 配额追踪

```dart
/// 配额追踪器接口
///
/// 职责：
/// - 检查 Provider 的速率限制（令牌桶算法，按 requests_per_minute 配置）
/// - 检查 Provider 的月度预算（通过 BillingLedger 查询累计使用量）
/// - 检查全局速率限制和预算
///
/// 令牌桶算法：
/// - 每个 Provider 维护一个 TokenBucket（capacity = rpm, refillRate = rpm/60 per second）
/// - hasTokens() 时先 refill（按经过时间补充令牌），再检查 >= 1
/// - consume(amount) 时先 refill，再扣减（clamp 到 0~capacity）
///
/// 接口签名：
class QuotaTracker {
  final BillingLedger _ledger;
  final RouterConfig _config;

  bool checkQuota(String providerId, String modelId);  // 速率限制 + 月度预算
  void recordRequest(String providerId);               // 消耗令牌桶
  Future<void> recordTokenUsage(String providerId, TokenUsage usage);
}

/// 令牌桶（速率限制）
class TokenBucket {
  final int capacity;
  final double refillRate;
  bool hasTokens();    // refill + 检查
  void consume(int);   // refill + 扣减
}
// 具体实现见代码仓库
```

---

## 4. 配置热重载

```dart
/// 配置管理器接口
///
/// 职责：
/// - 从 YAML 文件加载 RouterConfig（loadYaml → RouterConfig.fromYaml）
/// - 文件变更时自动重载（FileWatcher + debounce 1s）
/// - 重载前验证配置（Provider 类型、别名引用、策略有效性）
/// - 验证失败时保持当前配置不变，记录错误日志
/// - 通过 onConfigChanged 流通知订阅者配置变更
///
/// 接口签名：
class RouterConfigManager {
  final String _configPath;
  RouterConfig _currentConfig;

  Future<void> initialize();              // 加载配置 + 启动文件监听
  Future<void> reload();                  // 读取 YAML → 解析 → 验证 → 更新 _currentConfig → 广播
  RouterConfig get current;
  Stream<RouterConfig> get onConfigChanged;
  void dispose();
}
// 具体实现见代码仓库
```

---

## 5. 使用示例

### 5.1 基本路由

```dart
// 初始化
final configManager = RouterConfigManager('./router_config.yaml');
await configManager.initialize();
final router = ModelRouter(config: configManager.current, /* ... */);

// 路由请求
final result = await router.route(RoutingRequest(
  modelAlias: 'smart',
  requiredCapabilities: ['function_calling'],
));
// result.providerId / result.modelId / result.provider

// 使用路由结果创建迭代器
final iterator = result.provider.createIterator(modelConfig: ModelConfig(model: result.modelId), messages: [...]);
```

### 5.2 故障转移处理

```dart
// 调用 router.route() → 执行迭代器 → 捕获 MuseProviderException → router.fallback() → 用新 Provider 重试
try {
  final result = await router.route(request);
  // ... 使用 result.provider 执行请求
} on MuseProviderException catch (e) {
  final fallbackResult = await router.fallback(request, result, e);
  // ... 使用 fallbackResult.provider 重试
}
```

---

## 6. 后续工作

- [ ] 实现基于机器学习的智能路由（根据历史数据预测最佳 Provider）
- [ ] 支持地域感知路由（选择距离最近的 endpoint）
- [ ] 实现 A/B 测试框架（比较不同模型/Provider 的效果）
- [ ] 添加路由决策的可解释性（为什么选择了这个 Provider）

---

**最后更新**: 2026-02-26  
**维护者**: Clotho 架构团队
