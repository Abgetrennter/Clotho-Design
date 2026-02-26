# Muse 模型路由配置规范

**版本**: 1.0.0
**日期**: 2026-02-26
**状态**: Active
**作者**: Clotho 架构团队
**关联文档**:
- [Muse 智能服务架构](README.md) - Muse 服务概览
- [Provider 适配器规范](muse-provider-adapters.md) - Provider 适配器实现
- [流式响应与计费设计](streaming-and-billing-design.md) - Token 计费与流式处理

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
class ModelRouter {
  final RouterConfig _config;
  final ProviderAdapterRegistry _adapterRegistry;
  final HealthMonitor _healthMonitor;
  final QuotaTracker _quotaTracker;
  final LatencyTracker _latencyTracker;
  
  // Provider 实例缓存
  final Map<String, ProviderInstance> _providers = {};
  
  ModelRouter({
    required RouterConfig config,
    required ProviderAdapterRegistry adapterRegistry,
    required HealthMonitor healthMonitor,
    required QuotaTracker quotaTracker,
    required LatencyTracker latencyTracker,
  })  : _config = config,
        _adapterRegistry = adapterRegistry,
        _healthMonitor = healthMonitor,
        _quotaTracker = quotaTracker,
        _latencyTracker = latencyTracker {
    _initializeProviders();
  }
  
  /// 路由请求到合适的 Provider
  Future<RoutingResult> route(RoutingRequest request) async {
    // 1. 解析模型别名
    final candidates = _resolveCandidates(request.modelAlias, request.requiredCapabilities);
    
    // 2. 过滤不可用 Provider
    final availableCandidates = await _filterAvailable(candidates);
    
    if (availableCandidates.isEmpty) {
      throw RoutingException('No available provider for model: ${request.modelAlias}');
    }
    
    // 3. 应用路由策略
    final strategy = _getStrategy(request.strategy);
    final selected = await strategy.select(availableCandidates, request);
    
    // 4. 检查配额
    if (!_quotaTracker.checkQuota(selected.providerId, selected.modelId)) {
      throw QuotaExceededException(selected.providerId);
    }
    
    // 5. 记录路由决策
    _logRoutingDecision(request, selected);
    
    return RoutingResult(
      providerId: selected.providerId,
      modelId: selected.modelId,
      provider: _providers[selected.providerId]!.adapter,
    );
  }
  
  /// 处理故障转移
  Future<RoutingResult> fallback(
    RoutingRequest request,
    RoutingResult failedAttempt,
    MuseProviderException error,
  ) async {
    final fallbackConfig = _config.fallback;
    
    // 检查是否应该触发 fallback
    if (!_shouldFallback(error, fallbackConfig)) {
      rethrow;
    }
    
    // 标记当前 Provider 为不健康（短暂）
    _healthMonitor.recordFailure(failedAttempt.providerId, error);
    
    // 重新路由（排除失败的 Provider）
    final blacklist = {failedAttempt.providerId};
    final candidates = _resolveCandidates(request.modelAlias, request.requiredCapabilities)
        .where((c) => !blacklist.contains(c.providerId))
        .toList();
    
    if (candidates.isEmpty) {
      throw RoutingException('No fallback provider available');
    }
    
    // 延迟后重试
    await Future.delayed(fallbackConfig.retryDelay);
    
    return route(request.copyWith(
      excludedProviders: blacklist,
    ));
  }
  
  // 内部方法
  List<ModelCandidate> _resolveCandidates(String alias, List<String>? requiredCaps) {
    final aliasConfig = _config.modelAliases[alias];
    if (aliasConfig == null) {
      // 直接使用 model@provider 格式
      return _parseDirectReference(alias);
    }
    
    return aliasConfig.candidates.where((c) {
      final model = _findModel(c.providerId, c.modelId);
      if (model == null) return false;
      
      // 检查能力要求
      if (requiredCaps != null) {
        return requiredCaps.every((cap) => model.capabilities.contains(cap));
      }
      return true;
    }).toList();
  }
  
  Future<List<ModelCandidate>> _filterAvailable(List<ModelCandidate> candidates) async {
    final results = <ModelCandidate>[];
    
    for (final candidate in candidates) {
      final provider = _providers[candidate.providerId];
      if (provider == null) continue;
      
      // 健康检查
      final isHealthy = await _healthMonitor.isHealthy(candidate.providerId);
      if (!isHealthy) continue;
      
      // 配额检查
      final hasQuota = _quotaTracker.checkQuota(candidate.providerId, candidate.modelId);
      if (!hasQuota) continue;
      
      results.add(candidate);
    }
    
    return results;
  }
  
  RoutingStrategy _getStrategy(String? strategyName) {
    final name = strategyName ?? _config.routing.defaultStrategy;
    return _config.routing.strategies[name] ?? PriorityStrategy();
  }
  
  void _initializeProviders() {
    for (final providerConfig in _config.providers) {
      if (!providerConfig.enabled) continue;
      
      final adapter = _adapterRegistry.createAdapter(providerConfig.toAdapterConfig());
      _providers[providerConfig.id] = ProviderInstance(
        config: providerConfig,
        adapter: adapter,
      );
    }
  }
  
  ModelConfig? _findModel(String providerId, String modelId) {
    final provider = _config.providers.firstWhereOrNull((p) => p.id == providerId);
    return provider?.models.firstWhereOrNull((m) => m.id == modelId);
  }
}

/// 路由请求
class RoutingRequest {
  final String modelAlias;  // 如 "smart", "fast", 或 "gpt-4o@openai-primary"
  final List<String>? requiredCapabilities;
  final String? strategy;
  final Set<String> excludedProviders;
  final double? maxCostPer1K;
  final Duration? maxLatency;
  
  RoutingRequest({
    required this.modelAlias,
    this.requiredCapabilities,
    this.strategy,
    this.excludedProviders = const {},
    this.maxCostPer1K,
    this.maxLatency,
  });
  
  RoutingRequest copyWith({
    Set<String>? excludedProviders,
  }) => RoutingRequest(
    modelAlias: modelAlias,
    requiredCapabilities: requiredCapabilities,
    strategy: strategy,
    excludedProviders: excludedProviders ?? this.excludedProviders,
    maxCostPer1K: maxCostPer1K,
    maxLatency: maxLatency,
  );
}

/// 路由结果
class RoutingResult {
  final String providerId;
  final String modelId;
  final ProviderAdapter provider;
  
  RoutingResult({
    required this.providerId,
    required this.modelId,
    required this.provider,
  });
}

/// Provider 实例包装
class ProviderInstance {
  final ProviderConfig config;
  final ProviderAdapter adapter;
  
  ProviderInstance({
    required this.config,
    required this.adapter,
  });
}
```

### 3.2 路由策略实现

```dart
/// 路由策略接口
abstract class RoutingStrategy {
  Future<ModelCandidate> select(
    List<ModelCandidate> candidates,
    RoutingRequest request,
  );
}

/// 优先级策略
class PriorityStrategy implements RoutingStrategy {
  @override
  Future<ModelCandidate> select(
    List<ModelCandidate> candidates,
    RoutingRequest request,
  ) async {
    // 按优先级排序，返回第一个
    final sorted = candidates.toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    return sorted.first;
  }
}

/// 轮询策略
class RoundRobinStrategy implements RoutingStrategy {
  final Map<String, int> _counters = {};
  
  @override
  Future<ModelCandidate> select(
    List<ModelCandidate> candidates,
    RoutingRequest request,
  ) async {
    final key = request.modelAlias;
    final current = _counters[key] ?? 0;
    final selected = candidates[current % candidates.length];
    _counters[key] = current + 1;
    return selected;
  }
}

/// 延迟优先策略
class LatencyBasedStrategy implements RoutingStrategy {
  final LatencyTracker _latencyTracker;
  final Duration _measurementWindow;
  final int _percentile;
  
  LatencyBasedStrategy({
    required LatencyTracker latencyTracker,
    required Duration measurementWindow,
    required int percentile,
  })  : _latencyTracker = latencyTracker,
        _measurementWindow = measurementWindow,
        _percentile = percentile;
  
  @override
  Future<ModelCandidate> select(
    List<ModelCandidate> candidates,
    RoutingRequest request,
  ) async {
    // 获取各 Provider 的延迟统计
    final latencies = <ModelCandidate, Duration>{};
    
    for (final candidate in candidates) {
      final latency = await _latencyTracker.getLatency(
        candidate.providerId,
        candidate.modelId,
        window: _measurementWindow,
        percentile: _percentile,
      );
      latencies[candidate] = latency ?? Duration(seconds: 10);
    }
    
    // 选择延迟最低的
    return latencies.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
  }
}

/// 成本优化策略
class CostOptimizedStrategy implements RoutingStrategy {
  final LatencyTracker _latencyTracker;
  final double _maxLatencyPenalty;
  
  CostOptimizedStrategy({
    required LatencyTracker latencyTracker,
    required double maxLatencyPenalty,
  })  : _latencyTracker = latencyTracker,
        _maxLatencyPenalty = maxLatencyPenalty;
  
  @override
  Future<ModelCandidate> select(
    List<ModelCandidate> candidates,
    RoutingRequest request,
  ) async {
    // 计算成本效率分数
    final scores = <ModelCandidate, double>{};
    
    for (final candidate in candidates) {
      final cost = candidate.pricing.output + candidate.pricing.input;
      final latency = await _latencyTracker.getLatency(
        candidate.providerId,
        candidate.modelId,
      ) ?? Duration(seconds: 10);
      
      // 成本效率 = 1 / (成本 * 延迟因子)
      final latencyFactor = 1 + (latency.inMilliseconds / 1000);
      if (latencyFactor > _maxLatencyPenalty) {
        scores[candidate] = 0;  // 延迟过高，不考虑成本优势
      } else {
        scores[candidate] = 1 / (cost * latencyFactor);
      }
    }
    
    return scores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}
```

### 3.3 健康监控

```dart
/// 健康监控器
class HealthMonitor {
  final Map<String, ProviderHealth> _healthStatus = {};
  final Map<String, StreamController<HealthEvent>> _healthStreams = {};
  
  /// 执行健康检查
  Future<void> checkHealth(String providerId, ProviderAdapter adapter) async {
    try {
      final status = await adapter.checkHealth();
      _updateHealth(providerId, status);
    } catch (e) {
      _updateHealth(providerId, HealthStatus.unhealthy(e.toString()));
    }
  }
  
  /// 记录失败
  void recordFailure(String providerId, MuseProviderException error) {
    final current = _healthStatus[providerId];
    if (current == null) return;
    
    // 根据错误类型决定是否标记为不健康
    if (_isCriticalError(error)) {
      _updateHealth(providerId, HealthStatus.unhealthy(error.message));
    }
    
    // 记录失败计数
    current.recordFailure();
  }
  
  /// 检查是否健康
  Future<bool> isHealthy(String providerId) async {
    final status = _healthStatus[providerId];
    if (status == null) return false;
    
    // 如果超过健康检查间隔，重新检查
    if (status.lastChecked.difference(DateTime.now()) > Duration(minutes: 1)) {
      // 触发异步检查
    }
    
    return status.isHealthy;
  }
  
  /// 订阅健康状态变化
  Stream<HealthEvent> onHealthChanged(String providerId) {
    return _healthStreams.putIfAbsent(
      providerId,
      () => StreamController<HealthEvent>.broadcast(),
    ).stream;
  }
  
  void _updateHealth(String providerId, HealthStatus status) {
    _healthStatus[providerId] = ProviderHealth(
      providerId: providerId,
      status: status,
      lastChecked: DateTime.now(),
    );
    
    _healthStreams[providerId]?.add(HealthEvent(
      providerId: providerId,
      status: status,
    ));
  }
  
  bool _isCriticalError(MuseProviderException error) {
    return error.code == MuseErrorCode.invalidApiKey ||
           error.code == MuseErrorCode.quotaExceeded;
  }
}

/// Provider 健康状态
class ProviderHealth {
  final String providerId;
  final HealthStatus status;
  final DateTime lastChecked;
  int _consecutiveFailures = 0;
  
  ProviderHealth({
    required this.providerId,
    required this.status,
    required this.lastChecked,
  });
  
  bool get isHealthy => status.isHealthy && _consecutiveFailures < 3;
  
  void recordFailure() {
    _consecutiveFailures++;
  }
  
  void recordSuccess() {
    _consecutiveFailures = 0;
  }
}

/// 健康事件
class HealthEvent {
  final String providerId;
  final HealthStatus status;
  final DateTime timestamp;
  
  HealthEvent({
    required this.providerId,
    required this.status,
  }) : timestamp = DateTime.now();
}
```

### 3.4 配额追踪

```dart
/// 配额追踪器
class QuotaTracker {
  final BillingLedger _ledger;
  final RouterConfig _config;
  
  // 内存中的配额计数（用于速率限制）
  final Map<String, TokenBucket> _rateLimitBuckets = {};
  final Map<String, DateTime> _lastRequestTime = {};
  
  QuotaTracker({
    required BillingLedger ledger,
    required RouterConfig config,
  })  : _ledger = ledger,
        _config = config;
  
  /// 检查配额
  bool checkQuota(String providerId, String modelId) {
    final provider = _config.providers.firstWhereOrNull((p) => p.id == providerId);
    if (provider == null) return false;
    
    // 检查速率限制
    if (!_checkRateLimit(provider)) {
      return false;
    }
    
    // 检查月度预算
    if (!_checkBudget(provider)) {
      return false;
    }
    
    return true;
  }
  
  /// 记录请求
  void recordRequest(String providerId) {
    final bucket = _getOrCreateBucket(providerId);
    bucket.consume(1);
    _lastRequestTime[providerId] = DateTime.now();
  }
  
  /// 记录 Token 使用
  Future<void> recordTokenUsage(
    String providerId,
    TokenUsage usage,
  ) async {
    // 更新数据库中的计费记录
    // 由 BillingManager 处理
  }
  
  bool _checkRateLimit(ProviderConfig provider) {
    final quotas = provider.quotas;
    if (quotas == null) return true;
    
    final bucket = _getOrCreateBucket(provider.id);
    return bucket.hasTokens();
  }
  
  bool _checkBudget(ProviderConfig provider) async {
    final quotas = provider.quotas;
    if (quotas?.monthlyBudget == null) return true;
    
    final monthlyUsage = await _ledger.getMonthlyUsageForProvider(provider.id);
    return monthlyUsage < quotas!.monthlyBudget!;
  }
  
  TokenBucket _getOrCreateBucket(String providerId) {
    return _rateLimitBuckets.putIfAbsent(providerId, () {
      final provider = _config.providers.firstWhere((p) => p.id == providerId);
      final rpm = provider.quotas?.requestsPerMinute ?? 60;
      return TokenBucket(
        capacity: rpm,
        refillRate: rpm / 60.0,  // 每秒补充的令牌数
      );
    });
  }
}

/// 令牌桶（速率限制）
class TokenBucket {
  final int capacity;
  final double refillRate;
  double _tokens;
  DateTime _lastRefill;
  
  TokenBucket({
    required this.capacity,
    required this.refillRate,
  })  : _tokens = capacity.toDouble(),
        _lastRefill = DateTime.now();
  
  bool hasTokens() {
    _refill();
    return _tokens >= 1;
  }
  
  void consume(int amount) {
    _refill();
    _tokens = (_tokens - amount).clamp(0, capacity.toDouble());
  }
  
  void _refill() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRefill).inMilliseconds / 1000.0;
    final tokensToAdd = elapsed * refillRate;
    
    _tokens = (_tokens + tokensToAdd).clamp(0, capacity.toDouble());
    _lastRefill = now;
  }
}
```

---

## 4. 配置热重载

```dart
/// 配置管理器
class RouterConfigManager {
  final String _configPath;
  RouterConfig _currentConfig;
  FileWatcher? _watcher;
  final _configController = StreamController<RouterConfig>.broadcast();
  
  RouterConfigManager(this._configPath) : _currentConfig = RouterConfig.default_();
  
  /// 初始化并加载配置
  Future<void> initialize() async {
    await reload();
    _startWatching();
  }
  
  /// 重新加载配置
  Future<void> reload() async {
    try {
      final file = File(_configPath);
      if (!await file.exists()) {
        // 创建默认配置
        await _createDefaultConfig();
      }
      
      final content = await file.readAsString();
      final yaml = loadYaml(content);
      final newConfig = RouterConfig.fromYaml(yaml);
      
      // 验证配置
      await _validateConfig(newConfig);
      
      _currentConfig = newConfig;
      _configController.add(newConfig);
      
      logger.info('Router config reloaded successfully');
    } catch (e, stack) {
      logger.error('Failed to reload router config', e, stack);
      // 保持当前配置
    }
  }
  
  /// 获取当前配置
  RouterConfig get current => _currentConfig;
  
  /// 订阅配置变化
  Stream<RouterConfig> get onConfigChanged => _configController.stream;
  
  void _startWatching() {
    _watcher = FileWatcher(_configPath);
    _watcher?.events.debounce(Duration(seconds: 1)).listen((_) {
      reload();
    });
  }
  
  Future<void> _createDefaultConfig() async {
    final defaultConfig = '''
version: "1.0"
providers: []
model_aliases: {}
routing:
  default_strategy: priority
  strategies: {}
'''
    final file = File(_configPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(defaultConfig);
  }
  
  Future<void> _validateConfig(RouterConfig config) async {
    // 验证所有 Provider 类型是否支持
    // 验证模型别名引用的 Provider 是否存在
    // 验证策略配置是否有效
  }
  
  void dispose() {
    _watcher?.dispose();
    _configController.close();
  }
}
```

---

## 5. 使用示例

### 5.1 基本路由

```dart
void main() async {
  // 初始化配置管理器
  final configManager = RouterConfigManager('./router_config.yaml');
  await configManager.initialize();
  
  // 初始化路由管理器
  final router = ModelRouter(
    config: configManager.current,
    adapterRegistry: initializeAdapterRegistry(),
    healthMonitor: HealthMonitor(),
    quotaTracker: QuotaTracker(
      ledger: SQLiteBillingLedger(db),
      config: configManager.current,
    ),
    latencyTracker: LatencyTracker(),
  );
  
  // 执行路由
  final result = await router.route(RoutingRequest(
    modelAlias: 'smart',  // 使用别名
    requiredCapabilities: ['function_calling'],
  ));
  
  print('Routed to: ${result.providerId}/${result.modelId}');
  
  // 使用路由结果创建迭代器
  final iterator = result.provider.createIterator(
    modelConfig: ModelConfig(model: result.modelId),
    messages: [/* ... */],
  );
}
```

### 5.2 故障转移处理

```dart
Future<void> executeWithFallback(
  ModelRouter router,
  RoutingRequest request,
  List<RawMessage> messages,
) async {
  RoutingResult? result;
  
  try {
    // 首次路由
    result = await router.route(request);
    
    // 尝试执行
    final iterator = result.provider.createIterator(
      modelConfig: ModelConfig(model: result.modelId),
      messages: messages,
    );
    
    while (iterator.hasNext) {
      final chunk = await iterator.next();
      // 处理 chunk...
    }
    
  } on MuseProviderException catch (e) {
    // 触发故障转移
    result = await router.fallback(request, result!, e);
    
    // 使用新的 Provider 重试
    final iterator = result.provider.createIterator(
      modelConfig: ModelConfig(model: result.modelId),
      messages: messages,
    );
    
    // ...
  }
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
