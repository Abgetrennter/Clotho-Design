# Jacquard 能力系统规范 (Capability System Specification)

**版本**: 1.0.0
**日期**: 2026-02-13
**状态**: Draft
**作者**: 资深系统架构师
**关联文档**:
- [`preset-system.md`](preset-system.md) - 预设系统总览
- [`plugin-architecture.md`](plugin-architecture.md) - 插件架构
- [`../mnemosyne/abstract-data-structures.md`](../mnemosyne/abstract-data-structures.md) - 数据结构

---

## 1. 概述 (Overview)

### 1.1 设计目标

能力系统 (Capability System) 是 Clotho 的**功能开关与配置管理框架**，旨在：

1. **统一配置入口**: 所有功能开关集中在 Preset 中管理
2. **渐进式复杂度**: 从极简到完整，按需启用功能
3. **自描述能力**: Pattern (织谱) 声明自身需求，自动适配
4. **依赖清晰**: 明确功能间的依赖和互斥关系
5. **运行时动态**: 支持会话中实时调整功能配置

### 1.2 核心概念

| 术语 | 定义 | 示例 |
|------|------|------|
| **Capability** | 系统的某个功能模块或特性 | `rag_retriever`, `turn_summary` |
| **Capability Path** | 能力的分层命名路径 | `mnemosyne.memory.turn_summary` |
| **Effective Capabilities** | 运行时生效的能力配置 | 三层合并后的结果 |
| **Required Capabilities** | L2 Pattern 声明必需的能力 | `["quest_system", "vwd_mode"]` |
| **Capability Patches** | L3 Session 的动态补丁 | `{ "semantic_search.enabled": false }` |

---

## 2. 能力命名空间 (Capability Namespace)

### 2.1 命名规范

能力采用分层命名空间，格式为：

```
{domain}.{component}.{feature}.{subfeature}
```

**域名 (Domain)**:
- `jacquard` - 编排层能力
- `mnemosyne` - 数据引擎能力
- `filament` - 协议层能力

### 2.2 Jacquard 能力

```
jacquard
├── pipeline                    # 流水线插件
│   ├── planner                 # 智能规划器
│   ├── scheduler               # 调度器
│   ├── rag_retriever           # RAG检索器
│   └── consolidation           # 记忆整理
└── skein_building              # Skein构建
    ├── depth_injection         # 深度注入
    ├── lorebook_routing        # 世界书路由
    └── dynamic_pruning         # 动态裁剪
```

### 2.3 Mnemosyne 能力

```
mnemosyne
├── state_management            # 状态管理
│   ├── mode                    # 模式 (simple/standard/full)
│   ├── vwd_descriptions        # VWD描述
│   ├── schema_templates        # 模板继承
│   ├── schema_validation       # 模式验证
│   └── acl_scopes              # ACL作用域
├── memory                      # 记忆系统
│   ├── turn_summary            # 回合摘要
│   ├── macro_narrative         # 宏观叙事
│   ├── event_extraction        # 事件提取
│   ├── reflection              # 角色反思
│   └── head_state_persistence  # Head State持久化
├── retrieval                   # 检索系统
│   ├── vector_storage          # 向量存储
│   ├── semantic_search         # 语义搜索
│   ├── keyword_search          # 关键词搜索
│   └── search_scope            # 搜索范围配置
├── quest_system                # 任务系统
│   ├── enabled                 # 总开关
│   ├── objective_tracking      # 子目标追踪
│   └── spotlight_focus         # 聚光灯聚焦
└── scheduler                   # 调度系统
    ├── enabled                 # 总开关
    ├── floor_counters          # 楼层计数器
    └── event_triggers          # 事件触发器
```

---

## 3. 能力配置 Schema

### 3.1 完整配置结构

```yaml
# 能力配置 Schema
capabilities:
  # ═══════════════════════════════════════════════════════════════════
  # Jacquard 编排能力
  # ═══════════════════════════════════════════════════════════════════
  jacquard:
    pipeline:
      planner:
        enabled: boolean           # 是否启用
        # 插件特定配置
        config:
          focus_detection: boolean
          goal_planning: boolean
      
      scheduler:
        enabled: boolean
      
      rag_retriever:
        enabled: boolean
        # 当 enabled=false 时，weaving_rules 中依赖此能力的规则自动跳过
      
      consolidation:
        enabled: boolean
    
    skein_building:
      depth_injection: boolean     # 深度注入开关
      lorebook_routing: boolean    # 世界书路由开关
      dynamic_pruning: boolean     # Token不足时自动裁剪
  
  # ═══════════════════════════════════════════════════════════════════
  # Mnemosyne 数据能力
  # ═══════════════════════════════════════════════════════════════════
  mnemosyne:
    state_management:
      mode: enum                   # "simple" | "standard" | "full"
      vwd_descriptions: boolean    # [Value, Description] 格式
      schema_templates: boolean    # $meta.template继承
      schema_validation: boolean   # 严格验证
      acl_scopes: boolean          # Global/Shared/Private作用域
    
    memory:
      turn_summary:
        enabled: boolean
        trigger: enum              # "post_flash" | "manual"
        custom_prompt: string|null
      
      macro_narrative:
        enabled: boolean
        interval_turns: integer    # 每N回合生成
      
      event_extraction:
        enabled: boolean
        strategy: enum             # "llm" | "rule_based" | "hybrid"
      
      reflection:
        enabled: boolean
        trigger: enum              # "buffer_full" | "session_end"
      
      head_state_persistence:
        enabled: boolean
        write_back: boolean        # 每回合回写
    
    retrieval:
      vector_storage:
        enabled: boolean
        backend: enum              # "sqlite_vec" | "chromadb"
      
      semantic_search:
        enabled: boolean
        top_k: integer
        threshold: float           # 相似度阈值
        sources:                   # 检索源选择
          turn_summaries: boolean
          macro_narratives: boolean
          lorebooks: boolean
      
      keyword_search:
        enabled: boolean
        search_scope:
          history_window: integer  # 最近N条消息
          lorebooks: boolean
          events: boolean
    
    quest_system:
      enabled: boolean
      objective_tracking: boolean  # 子目标追踪
      spotlight_focus: boolean     # 聚光灯聚焦
      auto_archive: boolean        # 自动归档
    
    scheduler:
      enabled: boolean
      floor_counters: boolean      # 楼层计数器
      event_triggers: boolean      # 事件触发器
```

### 3.2 运行时能力对象

```dart
/// 运行时有效能力配置
@immutable
class EffectiveCapabilities {
  final JacquardCapabilities jacquard;
  final MnemosyneCapabilities mnemosyne;
  
  const EffectiveCapabilities({
    required this.jacquard,
    required this.mnemosyne,
  });
  
  /// 检查特定能力是否启用
  bool isEnabled(String capabilityPath) {
    final parts = capabilityPath.split('.');
    return _getValue(parts) == true;
  }
  
  /// 获取能力配置值
  dynamic getValue(String capabilityPath) {
    final parts = capabilityPath.split('.');
    return _getValue(parts);
  }
  
  /// 验证所有依赖关系
  ValidationResult validate() {
    return CapabilityValidator.validate(this);
  }
}

class JacquardCapabilities {
  final PipelineCapabilities pipeline;
  final SkeinBuildingCapabilities skeinBuilding;
  
  bool get plannerEnabled => pipeline.planner?.enabled ?? false;
  bool get schedulerEnabled => pipeline.scheduler?.enabled ?? false;
  bool get ragRetrieverEnabled => pipeline.ragRetriever?.enabled ?? false;
}

class MnemosyneCapabilities {
  final StateManagementCapabilities stateManagement;
  final MemoryCapabilities memory;
  final RetrievalCapabilities retrieval;
  final QuestSystemCapabilities questSystem;
  final SchedulerCapabilities scheduler;
  
  bool get isSimpleMode => stateManagement.mode == 'simple';
  bool get vwdEnabled => stateManagement.vwdDescriptions ?? false;
}
```

---

## 4. 依赖关系系统

### 4.1 依赖类型

| 依赖类型 | 说明 | 处理方式 |
|----------|------|----------|
| **Requires** | 能力A需要能力B才能工作 | 自动启用B，禁用B时警告 |
| **Recommends** | 能力A推荐配合能力B | 提示建议，不强制 |
| **Conflicts** | 能力A与能力B互斥 | 启用A时自动禁用B |
| **One Of** | 必须从多个选项中选择一个 | 单选约束 |

### 4.2 依赖规则定义

```yaml
# capability-dependencies.yaml
dependencies:
  # ─────────────────────────────────────────────────────────────────
  # Requires: 强制依赖
  # ─────────────────────────────────────────────────────────────────
  mnemosyne.retrieval.semantic_search:
    requires:
      - capability: "mnemosyne.retrieval.vector_storage"
        severity: "error"              # error | warning
        auto_fix: true                 # 自动启用依赖
        message: "语义搜索需要启用向量存储"
  
  mnemosyne.memory.macro_narrative:
    requires:
      - capability: "mnemosyne.memory.turn_summary.enabled"
        severity: "warning"
        auto_fix: true
        message: "宏观叙事建议配合回合摘要使用"
  
  # ─────────────────────────────────────────────────────────────────
  # Mode Constraints: 模式约束
  # ─────────────────────────────────────────────────────────────────
  mnemosyne.state_management.vwd_descriptions:
    requires:
      - capability: "mnemosyne.state_management.mode"
        one_of: ["standard", "full"]
        severity: "error"
        auto_fix: false                # 无法自动修复，需用户决策
        message: "VWD描述需要标准或完整状态管理模式"
  
  mnemosyne.state_management.acl_scopes:
    requires:
      - capability: "mnemosyne.state_management.mode"
        equals: "full"
        severity: "error"
        auto_fix: false
        message: "ACL作用域需要完整状态管理模式"
  
  # ─────────────────────────────────────────────────────────────────
  # Conflicts: 互斥关系
  # ─────────────────────────────────────────────────────────────────
  mnemosyne.state_management.mode:
    conflicts:
      - condition: "value == 'simple'"
        with_capabilities: 
          - "mnemosyne.state_management.vwd_descriptions"
          - "jacquard.pipeline.planner"
          - "jacquard.pipeline.scheduler"
        severity: "error"
        message: "简单模式不支持VWD描述、规划器和调度器"
  
  # ─────────────────────────────────────────────────────────────────
  # Quest System Dependencies
  # ─────────────────────────────────────────────────────────────────
  mnemosyne.quest_system.spotlight_focus:
    requires:
      - capability: "jacquard.pipeline.planner.enabled"
        severity: "error"
        auto_fix: true
        message: "聚光灯聚焦需要启用规划器"
```

### 4.3 关键能力依赖表

| 能力路径 | 依赖 | 互斥 | 自动修复 | 验证失败后果 |
|----------|------|------|----------|--------------|
| `mnemosyne.retrieval.semantic_search` | `vector_storage` | - | 是 | 禁用语义搜索 |
| `mnemosyne.memory.macro_narrative` | `turn_summary` | - | 是 | 降级为普通摘要 |
| `mnemosyne.quest_system.spotlight_focus` | `planner` | - | 是 | 禁用聚焦功能 |
| `mnemosyne.state_management.vwd_descriptions` | `mode: standard/full` | `mode: simple` | 否 | 配置错误 |
| `jacquard.pipeline.planner` | `mode: standard/full` | `mode: simple` | 否 | 配置错误 |
| `jacquard.pipeline.scheduler` | `mode: standard/full` | `mode: simple` | 否 | 配置错误 |
| `mnemosyne.state_management.acl_scopes` | `mode: full` | `mode: simple/standard` | 否 | 配置错误 |

**注**: `auto_fix: false` 的依赖表示需要用户手动解决，系统抛出 `CapabilityConfigurationException`。

### 4.4 依赖验证器

```dart
class CapabilityValidator {
  /// 验证能力配置
  /// 
  /// 返回 ValidationResult，包含错误、警告和自动修复建议
  static ValidationResult validate(EffectiveCapabilities caps) {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];
    final autoFixes = <String, dynamic>{};
    
    // ─────────────────────────────────────────────────────────────────
    // 1. 检查 Requires 依赖
    // ─────────────────────────────────────────────────────────────────
    for (final rule in DependencyRegistry.requiredRules) {
      if (!rule.isSatisfied(caps)) {
        final message = "'${rule.capability}' requires '${rule.dependsOn}'";
        
        if (rule.autoFix) {
          // 可自动修复：记录修复建议
          autoFixes[rule.dependsOn] = rule.fixValue ?? true;
          warnings.add(ValidationWarning(
            type: WarningType.autoFixableDependency,
            capability: rule.capability,
            message: "$message (will be auto-enabled)",
          ));
        } else {
          // 不可自动修复：记录错误
          errors.add(ValidationError(
            type: ErrorType.missingDependency,
            capability: rule.capability,
            dependsOn: rule.dependsOn,
            message: rule.message ?? message,
          ));
        }
      }
    }
    
    // ─────────────────────────────────────────────────────────────────
    // 2. 检查模式约束 (one_of, equals)
    // ─────────────────────────────────────────────────────────────────
    for (final rule in DependencyRegistry.modeConstraints) {
      final actualValue = caps.getValue(rule.capabilityPath);
      
      if (rule.oneOf != null && !rule.oneOf.contains(actualValue)) {
        errors.add(ValidationError(
          type: ErrorType.invalidMode,
          capability: rule.targetCapability,
          constraint: "${rule.capabilityPath} must be one of ${rule.oneOf}",
          actualValue: actualValue,
          message: rule.message,
        ));
      }
      
      if (rule.equals != null && actualValue != rule.equals) {
        errors.add(ValidationError(
          type: ErrorType.invalidMode,
          capability: rule.targetCapability,
          constraint: "${rule.capabilityPath} must be '${rule.equals}'",
          actualValue: actualValue,
          message: rule.message,
        ));
      }
    }
    
    // ─────────────────────────────────────────────────────────────────
    // 3. 检查互斥关系
    // ─────────────────────────────────────────────────────────────────
    for (final conflict in DependencyRegistry.conflicts) {
      if (conflict.isTriggered(caps)) {
        final enabledCapabilities = conflict.getEnabledConflicts(caps);
        errors.add(ValidationError(
          type: ErrorType.capabilityConflict,
          capabilities: enabledCapabilities,
          message: conflict.message ?? 
            "Mutually exclusive capabilities: ${enabledCapabilities.join(', ')}",
        ));
      }
    }
    
    // ─────────────────────────────────────────────────────────────────
    // 4. 检查循环依赖
    // ─────────────────────────────────────────────────────────────────
    final cycle = DependencyGraph.detectCycle(caps);
    if (cycle != null) {
      errors.add(ValidationError(
        type: ErrorType.circularDependency,
        cycle: cycle,
        message: "Circular dependency detected: ${cycle.join(' -> ')}",
      ));
    }
    
    return ValidationResult(
      errors: errors,
      warnings: warnings,
      autoFixes: autoFixes,
      isValid: errors.isEmpty,
    );
  }
  
  /// 应用自动修复
  /// 
  /// 仅修复 auto_fix: true 的依赖问题
  static EffectiveCapabilities applyAutoFixes(
    EffectiveCapabilities caps,
    ValidationResult validation,
  ) {
    if (validation.autoFixes.isEmpty) {
      return caps;
    }
    
    var fixed = caps;
    for (final entry in validation.autoFixes.entries) {
      final path = entry.key;
      final value = entry.value;
      
      fixed = fixed.setValue(path, value);
      log.info("Auto-fixed: enabled '$path' = $value");
    }
    
    // 递归验证，确保修复没有引入新问题
    final revalidation = validate(fixed);
    if (!revalidation.isValid) {
      log.warning("Auto-fix introduced new issues: ${revalidation.errors}");
    }
    
    return fixed;
  }
}

/// 验证结果
class ValidationResult {
  final List<ValidationError> errors;
  final List<ValidationWarning> warnings;
  final Map<String, dynamic> autoFixes;
  final bool isValid;
  
  ValidationResult({
    required this.errors,
    required this.warnings,
    this.autoFixes = const {},
    required this.isValid,
  });
  
  /// 序列化为 JSON (用于调试和 UI 展示)
  Map<String, dynamic> toJson() => {
    'valid': isValid,
    'error_count': errors.length,
    'warning_count': warnings.length,
    'errors': errors.map((e) => e.toJson()).toList(),
    'warnings': warnings.map((w) => w.toJson()).toList(),
    'auto_fixes': autoFixes,
  };
}
```

---

## 5. 三层合并机制

### 5.1 合并算法

```dart
class CapabilityMerger {
  /// 合并三层配置生成有效能力
  EffectiveCapabilities merge({
    required InfrastructurePreset l1,
    required PatternPreset l2,
    required SessionPreset l3,
  }) {
    // 1. 从 L1 获取基础配置
    var base = l1.capabilities;
    
    // 2. 检查 L2 的必需能力
    for (final required in l2.requiredCapabilities) {
      if (!base.isEnabled(required)) {
        // Pattern (织谱) 需要但基础预设禁用的能力
        // 策略：自动启用并记录警告
        base = base.withCapabilityEnabled(required);
        log.warning(
          "Pattern '${l2.name}' requires '$required' which is disabled "
          "in base preset '${l1.name}'. Auto-enabling."
        );
      }
    }
    
    // 3. 应用 L2 的能力覆盖
    base = base.merge(l2.capabilityOverrides);
    
    // 4. 应用 L3 的实时补丁
    base = base.merge(l3.capabilityPatches);
    
    // 5. 验证并自动修复依赖
    final validation = base.validate();
    if (validation.hasErrors) {
      throw CapabilityConfigurationException(validation.errors);
    }
    
    return base;
  }
}
```

### 5.2 合并优先级

```
运行时有效配置 = L1 Infrastructure (基础默认值)
                ⊕ L2 Required (强制启用必需能力)
                ⊕ L2 Overrides (Pattern 覆盖)
                ⊕ L3 Patches (用户实时调整)
                → Validation (验证依赖)
```

### 5.3 合并策略详解

| 配置项类型 | 合并策略 | 示例 |
|------------|----------|------|
| `boolean` | OR 逻辑（任一启用则启用） | `planner.enabled` |
| `enum` | 后者覆盖 | `state_management.mode` |
| `integer` | 后者覆盖 | `semantic_search.top_k` |
| `object` | 深度合并 | `search_scope` |
| `array` | 后者覆盖 | `pipeline.plugins` |

```dart
/// 深度合并两个能力配置
Capabilities deepMerge(Capabilities base, Capabilities override) {
  final result = base.clone();
  
  for (final entry in override.entries) {
    final key = entry.key;
    final value = entry.value;
    
    if (value is Map && result[key] is Map) {
      // 递归合并对象
      result[key] = deepMerge(result[key], value);
    } else if (value is bool && result[key] is bool) {
      // boolean 使用 OR 逻辑
      result[key] = result[key] || value;
    } else {
      // 其他类型：后者覆盖
      result[key] = value;
    }
  }
  
  return result;
}
```

---

## 6. 运行时动态调整

### 6.1 Patches 机制

L3 Session 通过 Patches 机制动态调整能力配置：

```dart
class SessionCapabilities {
  /// 当前有效配置
  EffectiveCapabilities effective;
  
  /// 用户应用的补丁
  final Map<String, dynamic> patches;
  
  /// 应用能力补丁
  void applyPatch(String path, dynamic value) {
    patches[path] = value;
    _recalculateEffective();
    
    // 通知相关系统配置变更
    _notifyCapabilityChanged(path, value);
  }
  
  /// 重新计算有效配置
  void _recalculateEffective() {
    effective = CapabilityMerger.merge(
      l1: basePreset,
      l2: patternPreset,
      l3: SessionPreset(capabilityPatches: patches),
    );
  }
}
```

### 6.2 变更通知与热重载

```dart
/// 能力变更事件
class CapabilityChangedEvent {
  final String capabilityPath;
  final dynamic oldValue;
  final dynamic newValue;
  final ChangeEffect effect;
}

enum ChangeEffect {
  immediate,      // 立即生效
  nextTurn,       // 下回合生效
  sessionReload,  // 需要重载会话
}

/// 变更影响映射
final changeEffectMap = {
  "jacquard.pipeline.*": ChangeEffect.nextTurn,
  "mnemosyne.state_management.mode": ChangeEffect.sessionReload,
  "mnemosyne.retrieval.*": ChangeEffect.immediate,
  "mnemosyne.memory.*": ChangeEffect.nextTurn,
};
```

### 6.3 UI 实时响应

```dart
class CapabilityToggleWidget extends StatelessWidget {
  final String capabilityPath;
  
  @override
  Widget build(BuildContext context) {
    return Consumer<SessionCapabilities>(
      builder: (context, caps, child) {
        final isEnabled = caps.effective.isEnabled(capabilityPath);
        
        return Switch(
          value: isEnabled,
          onChanged: (value) {
            // 检查依赖
            final deps = DependencyResolver.check(capabilityPath, value);
            if (deps.hasUnmetRequirements) {
              _showDependencyDialog(context, deps);
              return;
            }
            
            // 应用补丁
            context.read<SessionCapabilities>().applyPatch(
              capabilityPath,
              value,
            );
          },
        );
      },
    );
  }
}
```

---

## 7. 性能优化

### 7.1 能力检查缓存

```dart
class CapabilityCache {
  final Map<String, bool> _cache = {};
  EffectiveCapabilities _lastCapabilities;
  
  bool isEnabled(String path, EffectiveCapabilities caps) {
    // 如果配置未变更，直接返回缓存
    if (identical(caps, _lastCapabilities)) {
      return _cache[path] ?? false;
    }
    
    // 重新计算并缓存
    final result = caps.isEnabled(path);
    _cache[path] = result;
    _lastCapabilities = caps;
    return result;
  }
  
  void invalidate() {
    _cache.clear();
    _lastCapabilities = null;
  }
}
```

### 7.2 懒加载机制

对于资源密集型的能力，采用懒加载：

```dart
class MnemosyneEngine {
  VectorStore _vectorStore;
  
  VectorStore get vectorStore {
    if (_vectorStore == null && capabilities.retrieval.vectorStorage.enabled) {
      _vectorStore = VectorStore.initialize(
        backend: capabilities.retrieval.vectorStorage.backend,
      );
    }
    return _vectorStore;
  }
  
  void onCapabilityChanged(String path, dynamic value) {
    if (path == "mnemosyne.retrieval.vector_storage.enabled" && value == false) {
      // 释放向量存储资源
      _vectorStore?.dispose();
      _vectorStore = null;
    }
  }
}
```

---

## 8. 调试与诊断

### 8.1 能力配置导出

```dart
class CapabilityDiagnostics {
  /// 导出完整的能力配置报告
  static Map<String, dynamic> exportReport(EffectiveCapabilities caps) {
    return {
      "effective_capabilities": caps.toJson(),
      "enabled_features": caps.listEnabledCapabilities(),
      "disabled_features": caps.listDisabledCapabilities(),
      "dependencies": DependencyResolver.analyze(caps),
      "validation": caps.validate().toJson(),
    };
  }
}
```

### 8.2 能力冲突检测

```dart
class CapabilityConflictDetector {
  /// 检测潜在的能力冲突
  static List<CapabilityConflict> detectConflicts(
    EffectiveCapabilities caps,
    PatternPreset pattern,
  ) {
    final conflicts = <CapabilityConflict>[];
    
    // 检查 Pattern 需求与实际配置的冲突
    for (final required in pattern.requiredCapabilities) {
      if (!caps.isEnabled(required)) {
        conflicts.add(CapabilityConflict(
          type: ConflictType.missingRequiredCapability,
          capability: required,
          message: "Pattern 需要 '$required' 但当前配置未启用",
        ));
      }
    }
    
    return conflicts;
  }
}
```

---

## 9. 附录

### 9.1 完整能力清单

| 能力路径 | 类型 | 默认值 | 依赖 |
|----------|------|--------|------|
| `jacquard.pipeline.planner.enabled` | boolean | true | - |
| `jacquard.pipeline.scheduler.enabled` | boolean | true | - |
| `jacquard.pipeline.rag_retriever.enabled` | boolean | false | - |
| `jacquard.pipeline.consolidation.enabled` | boolean | false | turn_summary |
| `jacquard.skein_building.depth_injection` | boolean | true | - |
| `jacquard.skein_building.lorebook_routing` | boolean | true | - |
| `mnemosyne.state_management.mode` | enum | "standard" | - |
| `mnemosyne.state_management.vwd_descriptions` | boolean | true | mode != simple |
| `mnemosyne.state_management.schema_templates` | boolean | true | - |
| `mnemosyne.state_management.schema_validation` | boolean | false | - |
| `mnemosyne.state_management.acl_scopes` | boolean | false | mode == full |
| `mnemosyne.memory.turn_summary.enabled` | boolean | true | - |
| `mnemosyne.memory.macro_narrative.enabled` | boolean | false | turn_summary |
| `mnemosyne.memory.event_extraction.enabled` | boolean | false | turn_summary |
| `mnemosyne.memory.reflection.enabled` | boolean | false | - |
| `mnemosyne.memory.head_state_persistence.enabled` | boolean | true | - |
| `mnemosyne.retrieval.vector_storage.enabled` | boolean | false | - |
| `mnemosyne.retrieval.semantic_search.enabled` | boolean | false | vector_storage |
| `mnemosyne.retrieval.keyword_search.enabled` | boolean | true | - |
| `mnemosyne.quest_system.enabled` | boolean | false | - |
| `mnemosyne.quest_system.objective_tracking` | boolean | false | quest_system |
| `mnemosyne.quest_system.spotlight_focus` | boolean | false | quest_system, planner |
| `mnemosyne.scheduler.enabled` | boolean | true | - |
| `mnemosyne.scheduler.floor_counters` | boolean | true | scheduler |
| `mnemosyne.scheduler.event_triggers` | boolean | false | scheduler |

### 9.2 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0.0 | 2026-02-13 | 初始版本，定义能力系统架构 |

---

*本文档版本: 1.0.0 | 最后更新: 2026-02-13*
