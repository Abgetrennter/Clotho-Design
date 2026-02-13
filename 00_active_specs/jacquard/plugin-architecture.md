# Jacquard 插件架构规范 (Plugin Architecture)

**版本**: 1.1.0
**日期**: 2026-02-13
**状态**: Draft
**关联文档**:
- [`README.md`](README.md)
- [`skein-and-weaving.md`](skein-and-weaving.md)
- [`preset-system.md`](preset-system.md) - 预设系统中的能力声明
- [`capability-system-spec.md`](capability-system-spec.md) - 能力系统详细规范

---

## 1. 概述 (Overview)

在 Clotho 的架构中，**Jacquard** 本质上是一个 **Pipeline Runner**。所有的实际业务逻辑——从决策、检索、构建到执行——都被封装在独立的 **Plugin** 中。

本以此规范定义了 `JacquardPlugin` 的通用接口和交互模式，确保系统的可扩展性和确定性。

---

## 2. 核心接口定义 (Core Interface)

为了保证类型安全和异步支持，插件接口采用 Dart `abstract class` 定义。

```dart
import 'dart:async';

/// Jacquard 流水线中的原子执行单元。
/// 
/// 遵循单一职责原则，每个插件只负责流水线中的一个特定步骤。
abstract class JacquardPlugin {
  /// 插件的唯一标识符
  /// 格式建议: "namespace.plugin_name" (e.g., "core.planner", "ext.web_search")
  String get id;

  /// 插件在流水线中的执行优先级。
  /// 数值越小，越先执行。
  int get priority;
  
  /// 该插件对应的能力路径。
  /// 用于与 Capability System 集成，控制插件的启用/禁用。
  /// 例如: "jacquard.pipeline.planner"
  String get capabilityPath;

  /// 插件的核心执行逻辑。
  ///
  /// [context] 是贯穿整个流水线的共享上下文对象。
  /// 如果插件抛出异常，流水线可能会根据策略中断或跳过。
  Future<void> execute(JacquardContext context);

  /// (可选) 插件初始化逻辑
  /// 仅在 Pipeline 首次加载或重新配置时调用。
  Future<void> initialize() async {}

  /// (可选) 插件销毁逻辑
  /// 在 Pipeline 销毁或插件被卸载时调用。
  Future<void> dispose() async {}
}
```
```

---

## 3. 共享上下文 (Jacquard Context)

插件之间不直接通信，而是通过共享的 `JacquardContext` 黑板进行数据交换。这解耦了插件间的依赖。

```dart
class JacquardContext {
  /// 当前会话 ID
  final String sessionId;

  /// 原始用户输入 (只读)
  final String userInput;

  /// 核心数据容器：Skein
  /// Builder 和 Renderer 插件会主要操作此对象。
  Skein skein;

  /// 运行时状态快照 (只读引用)
  /// 若需修改状态，应生成 StateUpdate指令，而不是直接修改此对象。
  final MnemosyneState state;

  /// 规划器上下文 (读写)
  /// 允许 Planner 修改任务焦点和短期目标。
  PlannerContext plannerContext;

  /// 插件间共享的临时数据黑板
  /// 用于存储跨插件的非持久化中间产物（如 RAG 搜索结果、临时标记）。
  final Map<String, dynamic> blackboard = {};

  /// 流水线控制标志
  bool _abortRequested = false;

  /// 请求中断流水线
  /// 后续的插件将不再执行。
  void abort() => _abortRequested = true;

  /// 检查是否已请求中断
  bool get isAborted => _abortRequested;

  JacquardContext({
    required this.sessionId,
    required this.userInput,
    required this.skein,
    required this.state,
    required this.plannerContext,
  });
}
```

---

## 4. 优先级系统 (Priority System)

为了规范原生插件的执行顺序，并为第三方插件预留插槽，我们定义了以下标准优先级锚点。

```dart
class PluginPriority {
  // --- Phase 1: Decision & Preparation ---
  
  /// 规划层 (Planning Phase): 决定聊什么，更新焦点
  static const int planner = 100;
  
  /// 调度层: 触发定时任务和脚本
  static const int scheduler = 200;

  // --- Phase 2: Construction ---

  /// 构建层: 从数据库提取数据，组装 Skein
  static const int builder = 300;
  
  // (预留插槽: 350 - 例如在这里插入一个 "敏感词过滤" 或 "Prompt 优化" 插件)

  /// 渲染层: 将 Skein 渲染为最终 Prompt 字符串 (Jinja2)
  static const int renderer = 400;

  // --- Phase 3: Execution ---

  /// 执行层: 调用 LLM API
  static const int invoker = 500;

  // --- Phase 4: Processing ---

  /// 解析层: 解析 Filament 输出流
  static const int parser = 600;
  
  /// 更新层: 将状态变更写回 Mnemosyne
  static const int updater = 700;
  
  // --- Phase 5: Cleanup ---
  
  /// 清理层: 释放资源，日志归档
  static const int cleanup = 900;
}
```

## 5. 插件与能力系统集成 (Capability Integration)

插件通过 `capabilityPath` 属性与能力系统集成，实现基于功能开关的动态加载。

### 5.1 能力感知插件基类

```dart
/// 能力感知插件基类
abstract class CapabilityAwarePlugin implements JacquardPlugin {
  @override
  String get capabilityPath;
  
  /// 检查当前插件是否被启用
  bool isEnabled(JacquardContext context) {
    return context.capabilities.isEnabled(capabilityPath);
  }
  
  @override
  Future<void> execute(JacquardContext context) async {
    // 如果插件被禁用，直接跳过
    if (!isEnabled(context)) {
      context.logger.debug("Plugin '$id' is disabled by capability '$capabilityPath', skipping.");
      return;
    }
    
    // 执行实际逻辑
    await executeInternal(context);
  }
  
  /// 子类实现的具体执行逻辑
  Future<void> executeInternal(JacquardContext context);
}
```

### 5.2 Pipeline 能力感知初始化

```dart
class JacquardPipeline {
  List<JacquardPlugin> _allPlugins;
  List<JacquardPlugin> _activePlugins;
  
  /// 根据能力配置初始化 Pipeline
  void initialize(EffectiveCapabilities capabilities) {
    _allPlugins = [...]; // 所有可用插件
    
    // 只加载启用的插件
    _activePlugins = _allPlugins.where((plugin) {
      return capabilities.isEnabled(plugin.capabilityPath);
    }).toList();
    
    // 按优先级排序
    _activePlugins.sort((a, b) => a.priority.compareTo(b.priority));
    
    // 初始化启用的插件
    for (final plugin in _activePlugins) {
      plugin.initialize();
    }
  }
  
  /// 运行时动态更新能力配置
  void updateCapabilities(EffectiveCapabilities capabilities) {
    final newActivePlugins = <JacquardPlugin>[];
    
    for (final plugin in _allPlugins) {
      final isEnabled = capabilities.isEnabled(plugin.capabilityPath);
      final wasEnabled = _activePlugins.contains(plugin);
      
      if (isEnabled && !wasEnabled) {
        // 新启用的插件
        plugin.initialize();
        newActivePlugins.add(plugin);
      } else if (!isEnabled && wasEnabled) {
        // 被禁用的插件
        plugin.dispose();
      } else if (isEnabled) {
        // 保持启用
        newActivePlugins.add(plugin);
      }
    }
    
    _activePlugins = newActivePlugins..sort((a, b) => a.priority.compareTo(b.priority));
  }
}
```

### 5.3 标准插件的能力映射

| 插件 | capabilityPath | 说明 |
|------|----------------|------|
| PlannerPlugin | `jacquard.pipeline.planner` | 智能规划器 |
| SchedulerPlugin | `jacquard.pipeline.scheduler` | 调度器 |
| RagRetrieverPlugin | `jacquard.pipeline.rag_retriever` | RAG检索器 |
| ConsolidationPlugin | `jacquard.pipeline.consolidation` | 记忆整理 |
| SkeinBuilderPlugin | `jacquard.skein_building` (复合) | Skein构建 |
| TemplateRendererPlugin | (核心，不可禁用) | 模板渲染 |
| LLMInvokerPlugin | (核心，不可禁用) | LLM调用 |
| FilamentParserPlugin | (核心，不可禁用) | 协议解析 |
| StateUpdaterPlugin | (核心，不可禁用) | 状态更新 |

### 5.4 核心插件与可选插件

**核心插件** (不可禁用):
- `TemplateRendererPlugin` - 模板渲染是必需的基础功能
- `LLMInvokerPlugin` - LLM调用是系统核心
- `FilamentParserPlugin` - 协议解析是必需功能
- `StateUpdaterPlugin` - 状态更新保证数据一致性

**可选插件** (可通过能力开关控制):
- `PlannerPlugin` - 可禁用以简化流程
- `SchedulerPlugin` - 不需要定时任务时可禁用
- `RagRetrieverPlugin` - 不需要长期记忆时可禁用
- `ConsolidationPlugin` - 不需要记忆整理时可禁用

## 6. 错误处理与容错

1.  **异常捕获**: Pipeline Runner 必须用 `try-catch` 包裹每个插件的 `execute` 调用。
2.  **非致命错误**: 如果插件抛出 `NonFatalPluginException`，Pipeline 应记录日志但继续执行下一个插件。
3.  **致命错误**: 其他未捕获异常将导致 Pipeline 中断，并向 UI 返回错误状态。
4.  **能力缺失错误**: 如果插件执行时发现依赖的能力未启用，应抛出 `CapabilityMissingException`，Pipeline 可选择跳过或中断。