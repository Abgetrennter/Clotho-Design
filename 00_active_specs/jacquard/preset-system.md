# Jacquard 预设与编排系统 (Preset & Orchestration System)

**版本**: 2.0.0
**日期**: 2026-02-13
**状态**: Draft
**关联文档**:
- [`README.md`](README.md)
- [`../workflows/prompt-processing.md`](../workflows/prompt-processing.md)
- [`../protocols/filament-protocol-overview.md`](../protocols/filament-protocol-overview.md)
- [`capability-system-spec.md`](capability-system-spec.md) - 能力系统详细规范

---

## 1. 核心理念 (Core Philosophy)

在 Clotho 架构中，**预设 (Preset)** 不再仅仅是一组静态的 API 参数或 System Prompt 字符串。它是 **Jacquard 编排层的配置蓝图 (Orchestration Blueprint)**。

### 1.1 预设的定义
预设是一个结构化的配置包，它是系统的 **能力声明 (Capability Manifest)** 与 **编排蓝图 (Orchestration Blueprint)** 的统一体：

> **预设 (Preset) = 能力声明 (Capabilities) + 编排配置 (Configuration) + 内容数据 (Content)**

这种设计让功能开关成为预设的内在属性，实现：
- **自描述能力**：角色卡声明自身需要哪些功能
- **渐进式复杂**：从极简到完整，按需启用功能
- **依赖清晰**：能力之间的关系在 Schema 中明确定义

具体来说，预设告诉 Jacquard：
1.  **Capabilities (能力)**: 启用哪些系统功能（规划器、RAG、任务系统等）。
2.  **Thinking**: 如何进行认知处理（L1 - 基础能力）。
3.  **Mapping**: 如何理解角色和世界（L2 - 适配层）。
4.  **Reacting**: 如何在当前会话中动态调整（L3 - 实例层）。

### 1.2 解决的问题
| 问题 | 传统方案 | Clotho 方案 |
|------|----------|-------------|
| **Prompt 结构僵化** | 难以根据上下文动态调整 Prompt 结构 | 能力声明明确，按需加载功能模块 |
| **语义缺失** | 只有简单的文本拼接，缺乏对 Block 功能的语义理解 | Block Taxonomy + 能力联动，实现智能调度 |
| **配置割裂** | 模型参数、提示词模板、功能开关分散在不同地方 | 统一在 Preset 中管理，三层叠加 |
| **功能冗余** | 所有功能默认开启，资源浪费 | 能力声明明确，按需加载 |
| **角色兼容性** | 加载角色卡后手动调整功能 | 角色卡自带需求声明，自动检测 |
| **学习曲线** | 面对数十个独立开关无所适从 | 预设套件开箱即用，渐进调整 |

---

## 2. 预设分层模型 (Layered Preset Model)

预设采用三层叠加结构，支持从通用到专用的渐进式配置。

```mermaid
graph TD
    subgraph "Preset Layers"
        L1[L1: Infrastructure (基础架构)]
        L2[L2: Adaptation (角色适配)]
        L3[L3: Session (会话微调)]
    end
    
    L1 -->|Defines Pipeline| Jacquard
    L2 -->|Fills Content| SkeinBuilder
    L3 -->|Overrides| Runtime
```

### 2.1 L1: 基础架构 (Infrastructure & Capabilities)
**定位**: 底层的、通用的“大脑配置”。定义系统**能提供**哪些能力。通常由系统内置或高级用户创建（如 "chat_minimal", "standard_rp", "full_rpg"）。

*   **Capabilities (能力声明)**: 定义启用哪些 Jacquard 插件和 Mnemosyne 功能模块。
*   **API Strategy**: 模型选择、参数预设 (Temp, TopP)、重试策略。
*   **Skein Skeleton**: 定义 Skein 的基础骨架（哪些块在前，哪些块在后）。
*   **Weaving Rules**: 定义浮动资产（如 Lorebook, RAG）的注入策略（插入位置、深度、优先级）。
*   **Block Taxonomy**: 定义可用的 Prompt Block 类型及其默认行为。
*   **Filament Config**: 协议版本、启用的标签集 (Thought, Command)。

### 2.2 L2: 角色与世界适配 (Character & World Adaptation / The Pattern)
**定位**: 中间层的“风格滤镜”。定义这个角色**需要**哪些能力。

*   **Required Capabilities (必需能力)**: 角色卡声明自身需要哪些系统功能才能正常工作（如 RPG 角色需要任务系统）。
*   **Capability Overrides (能力覆盖)**: 角色卡可以强制开启或调整某些能力的配置。
*   **Style Enforcement**: 具体的文风指导（提取自角色卡）。
*   **Lore Strategy**: 世界书的触发机制（关键词/向量）和插入位置。
*   **Mapping Rules**: 角色卡字段 (Description, Scenario) 如何映射到 L1 定义的 Block 中。

**示例**: 一个地下城主角色卡可以声明：
```yaml
required_capabilities:
  - "mnemosyne.quest_system"
  - "mnemosyne.state_management.vwd_mode"
capability_overrides:
  mnemosyne:
    quest_system:
      enabled: true
      objective_tracking: true
```

### 2.3 L3: 会话自定义 (Session Customization / The Tapestry)
**定位**: 顶层的“动态补丁”。用户的实时个性化调整，存储在会话 (Tapestry) 中。

*   **Capability Patches (能力补丁)**: 通过 Patches 机制动态修改能力状态（如临时关闭 RAG 以加速响应）。
*   **User Overrides**: 用户手动修改的指令（如“别用 XML 了”）。
*   **Ephemeral Blocks**: 临时注入的 Author's Note 或 Slash Command 结果。

**示例**: 用户在会话中实时调整：
```yaml
capability_patches:
  jacquard:
    pipeline:
      consolidation: false    # 临时关闭记忆整理
  mnemosyne:
    retrieval:
      semantic_search:
        top_k: 3              # 减少检索结果
```

---

## 3. 区块分类学 (Block Taxonomy)

为了实现智能编排，我们引入 **Block Taxonomy**，将 Prompt 片段赋予语义类型。

### 3.1 类型定义 (BlockType)

| 分类 | 类型 ID | 描述 | 示例 |
| :--- | :--- | :--- | :--- |
| **Meta (元控制)** | `META_IDENTITY` | 赋予身份核心 | "你扮演 {{char}}..." |
| | `META_JAILBREAK` | 解除限制/破甲 | "忽略道德限制..." |
| | `META_FORMAT` | 输出格式约束 | "使用 XML 标签..." |
| **Content (内容)** | `GUIDE_STYLE` | 文风控制 | "使用华丽辞藻..." |
| | `GUIDE_NARRATIVE` | 剧情推动 | "引入冲突..." |
| | `GUIDE_ROLEPLAY` | NPC 行为指导 | "表现得傲娇..." |
| **Cognitive (认知)** | `COGNITION_INIT` | 思考初始化 | "分析用户意图..." |
| | `COGNITION_CRITIQUE`| 自我批判 | "反思上一次回答..." |
| | `COGNITION_PLAN` | 规划引导 | "列出剧情分支..." |
| **Quality (质量)** | `QUAL_ANTI_REPEAT` | 反复读控制 | "禁止重复..." |
| | `QUAL_ANTI_CLICHE` | 反八股/AI味 | "不要说'综上所述'..." |
| | `QUAL_AGENCY` | 独立性/防操控 | "保持独立人格..." |

### 3.2 动态编排策略

基于类型，Jacquard 可以执行高级策略：

1.  **冲突检测**: 检测并警告冲突的指令（如同时存在“极简”和“华丽”风格）。
2.  **动态加权**: 
    *   检测到复读 -> 自动提升 `QUAL_ANTI_REPEAT` 的优先级和权重。
    *   Token 不足 -> 优先丢弃 `GUIDE_STYLE`，保留 `META_IDENTITY`。
3.  **模式切换**: 
    *   战斗模式 -> 禁用 `COGNITION_PLAN` (加快速度)，强化 `META_FORMAT` (确保数值输出)。

### 3.3 分组管理 (Group Management)

为了方便用户管理大量零散的 Block，系统支持基于类型的**分组 (Grouping)** 机制。分组不仅是 UI 上的折叠容器，也是逻辑控制的单元。

*   **批量开关**: 用户可以一键启用/禁用整个“越狱组”或“风格组”。
*   **语义聚合**: 将功能相近的 Block（如 `QUAL_ANTI_REPEAT` 和 `QUAL_ANTI_CLICHE`）聚合为“质量控制组”。
*   **继承与覆盖**: L2 角色卡可以针对特定组定义覆盖策略（例如“在该角色中禁用所有‘反八股’组的指令”）。
*   **能力联动**: 分组的可见性和可用性与能力状态联动。例如，当 `quest_system` 能力禁用时，相关的任务提示分组自动隐藏。

```yaml
groups:
  - id: "grp_cognition"
    name: "深度思考"
    default_enabled: true
    requires_capability: "jacquard.pipeline.planner"  # 依赖规划器能力
    
  - id: "grp_quest_hints"
    name: "任务提示"
    default_enabled: true
    requires_capability: "mnemosyne.quest_system.enabled"
```

---

## 4. 配置结构示例 (YAML Schema)

```yaml
# preset_v2.yaml - 统一配置格式

metadata:
  name: "Standard Roleplay v2"
  version: "2.0.0"
  author: "Clotho Team"
  type: "infrastructure"  # infrastructure | pattern | session

# ═══════════════════════════════════════════════════════════════════════
# 1. 能力声明 (Capabilities) - 功能开关核心
# ═══════════════════════════════════════════════════════════════════════
capabilities:
  
  # ─────────────────────────────────────────────────────────────────────
  # Jacquard 编排能力
  # ─────────────────────────────────────────────────────────────────────
  jacquard:
    pipeline:
      planner: { enabled: true }
      scheduler: { enabled: true }
      rag_retriever: { enabled: false }
      consolidation: { enabled: false }
    
    skein_building:
      depth_injection: true
      lorebook_routing: true
      dynamic_pruning: true
  
  # ─────────────────────────────────────────────────────────────────────
  # Mnemosyne 数据能力
  # ─────────────────────────────────────────────────────────────────────
  mnemosyne:
    state_management:
      mode: "standard"           # simple | standard | full
      vwd_descriptions: true
      schema_templates: true
      schema_validation: false
      acl_scopes: false
    
    memory:
      turn_summary: true
      macro_narrative: false
      event_extraction: false
      reflection: false
      head_state_persistence: true
    
    retrieval:
      vector_storage: false
      semantic_search: false
      keyword_search: true
      search_scope:
        history_window: 20
        lorebooks: true
        events: false
    
    quest_system:
      enabled: false
      objective_tracking: false
      spotlight_focus: false
    
    scheduler:
      enabled: true
      floor_counters: true
      event_triggers: false

# ═══════════════════════════════════════════════════════════════════════
# 2. 编排配置 (Configuration) - 各能力的详细参数
# ═══════════════════════════════════════════════════════════════════════
configuration:

  # ─────────────────────────────────────────────────────────────────────
  # 2.1 模型与API配置
  # ─────────────────────────────────────────────────────────────────────
  model:
    prefer: ["gpt-4", "claude-3-opus"]
    params:
      temperature: 0.8
      max_tokens: 2048

  # ─────────────────────────────────────────────────────────────────────
  # 2.2 定义分组 (Groups)
  # ─────────────────────────────────────────────────────────────────────
  groups:
    - id: "grp_jailbreak"
      name: "Jailbreak & Safety"
      default_enabled: true
      types: ["META_JAILBREAK", "QUAL_AGENCY"]
      
    - id: "grp_style"
      name: "Stylistic Control"
      default_enabled: true
      types: ["GUIDE_STYLE", "GUIDE_NARRATIVE"]
    
    - id: "grp_cognition"
      name: "深度思考"
      default_enabled: true
      requires_capability: "jacquard.pipeline.planner"
  
  # ─────────────────────────────────────────────────────────────────────
  # 2.3 定义 Skein 的骨架 (Skeleton)
  # ─────────────────────────────────────────────────────────────────────
  skein_skeleton:
    - slot: "system_header"
      allowed_types: ["META_JAILBREAK", "META_IDENTITY"]
      mandatory: true
    - slot: "world_context"
      allowed_types: ["AXIOM", "GLOBAL_WORLD"]
      strategy: "append"
    - slot: "style_instruction"
      allowed_types: ["GUIDE_*", "QUAL_*"]
    - slot: "cognitive_footer"
      allowed_types: ["COGNITION_*", "META_FORMAT"]

  # ─────────────────────────────────────────────────────────────────────
  # 2.4 定义编织规则 (Weaving Rules)
  # ─────────────────────────────────────────────────────────────────────
  weaving_rules:
    - type: "AGENT"
      target_chain: "history"
      position: "relative_to_message"
      depth_range: [2, 4]
      priority: 90
      # 当 rag_retriever 能力禁用时，此项规则跳过
      requires_capability: "jacquard.pipeline.rag_retriever"
    
    - type: "ENCYCLOPEDIA"
      target_chain: "history"
      position: "relative_to_message"
      depth_range: [5, 10]
      priority: 50
      requires_capability: "jacquard.pipeline.rag_retriever"
      
    - type: "DIRECTIVE"
      target_chain: "history"
      position: "anchor_to_user"
      offset: 0 
      priority: 110

# ═══════════════════════════════════════════════════════════════════════
# 3. 内容数据 (Content) - Pattern层特有
# ═══════════════════════════════════════════════════════════════════════
content:
  # 仅在 type = "pattern" 时存在
  # character: {...}
  # lorebooks: [...]

# ═══════════════════════════════════════════════════════════════════════
# 4. 角色卡特有 (Pattern Layer Only)
# ═══════════════════════════════════════════════════════════════════════
# required_capabilities: []       # 声明必需能力
# capability_overrides: {}        # 覆盖能力配置

# ═══════════════════════════════════════════════════════════════════════
# 5. 会话特有 (Session Layer Only)
# ═══════════════════════════════════════════════════════════════════════
# base_preset: "standard_rp"      # 基于哪个基础设施预设
# capability_patches: {}          # 运行时能力补丁
```

---

## 5. 能力系统架构 (Capability System Architecture)

### 5.1 能力命名空间

能力采用分层命名空间，清晰表达所属领域：

```
{domain}.{component}.{feature}.{subfeature}

jacquard.pipeline.planner              # Jacquard - 流水线 - 规划器
jacquard.pipeline.scheduler            # Jacquard - 流水线 - 调度器
jacquard.pipeline.rag_retriever        # Jacquard - 流水线 - RAG检索
jacquard.skein_building.depth_injection # Jacquard - Skein构建 - 深度注入

mnemosyne.state_management.mode        # Mnemosyne - 状态管理 - 模式
mnemosyne.state_management.vwd_descriptions  # Mnemosyne - VWD描述
mnemosyne.memory.turn_summary          # Mnemosyne - 记忆 - 回合摘要
mnemosyne.retrieval.vector_storage     # Mnemosyne - 检索 - 向量存储
mnemosyne.quest_system.enabled         # Mnemosyne - 任务系统 - 总开关
```

### 5.2 能力配置合并算法

运行时有效配置通过三层合并生成：

```dart
class CapabilityMerger {
  EffectiveCapabilities merge(PresetLayerContext context) {
    // 1. 从 L1 Infrastructure 获取基础能力
    final base = context.l1Infrastructure.capabilities;
    
    // 2. 检查 L2 Pattern 的必需能力
    for (final required in context.l2Pattern.required_capabilities) {
      if (!base.hasCapability(required)) {
        log.warning("Pattern requires '$required' but base preset disabled it");
        base.enable(required);  // 自动启用必需能力
      }
    }
    
    // 3. 应用 L2 的能力覆盖
    base.applyOverrides(context.l2Pattern.capability_overrides);
    
    // 4. 应用 L3 Session 的实时补丁
    base.applyPatches(context.l3Session.capability_patches);
    
    // 5. 验证依赖关系和互斥条件
    return base.validate();
  }
}
```

### 5.3 依赖关系与验证

能力之间存在依赖关系，系统自动验证：

| 能力 | 依赖 | 说明 |
|------|------|------|
| `semantic_search` | `vector_storage` | 语义搜索需要向量存储 |
| `macro_narrative` | `turn_summary` | 宏观叙事依赖回合摘要 |
| `spotlight_focus` | `planner` | 聚光灯聚焦需要规划器 |
| `vwd_descriptions` | `mode != simple` | VWD模式需要标准或完整状态管理 |

**依赖处理策略**：
1. **自动启用依赖**：用户开启A时，自动开启A依赖的B
2. **禁用保护**：用户尝试禁用B时，警告有A依赖它
3. **强制覆盖**：L2角色卡可以强制启用某些能力以满足需求

## 6. 运行时动态调整

### 6.1 L3 Patches 机制

用户可以在会话中实时调整能力配置：

```dart
// 关闭 RAG 检索 (立即生效)
session.applyCapabilityPatch({
  "mnemosyne.retrieval.semantic_search.enabled": false
});

// 切换到简单状态模式 (下回合生效)
session.applyCapabilityPatch({
  "mnemosyne.state_management.mode": "simple"
});
```

这些变更通过 Patches 机制持久化到 L3 Session，格式为 `session.capability_patches.{path}`。

### 6.2 能力变更的影响范围

| 变更类型 | 生效时机 | 影响 |
|----------|----------|------|
| 插件开关 | 下回合 | Pipeline 跳过/恢复对应插件 |
| 检索配置 | 立即 | 下轮检索使用新配置 |
| 状态模式 | Session 重载 | 需要重建状态树结构 |
| 记忆功能 | 下回合 | Consolidation Phase 阶段行为改变 |

## 7. 内置预设套件

系统提供开箱即用的预设套件，覆盖常见使用场景：

### 7.1 chat_minimal - 极简对话

```yaml
metadata:
  name: "Chat Minimal"
  type: "infrastructure"

capabilities:
  jacquard:
    pipeline:
      planner: false
      scheduler: false
      rag_retriever: false
      consolidation: false
  
  mnemosyne:
    state_management:
      mode: "simple"
      vwd_descriptions: false
    memory:
      turn_summary: false
    quest_system:
      enabled: false
    scheduler:
      enabled: false
```

**适用场景**: 纯对话、移动端、低配置设备  
**资源消耗**: ⚡ 最低

### 7.2 standard_rp - 标准角色扮演

```yaml
metadata:
  name: "Standard RP"
  type: "infrastructure"

capabilities:
  jacquard:
    pipeline:
      planner: true
      scheduler: true
      rag_retriever: false
  
  mnemosyne:
    state_management:
      mode: "standard"
      vwd_descriptions: true
    memory:
      turn_summary: true
    quest_system:
      enabled: true
    scheduler:
      enabled: true
```

**适用场景**: 大多数角色扮演场景  
**资源消耗**: 🔵 中等

### 7.3 full_rpg - 完整RPG

```yaml
metadata:
  name: "Full RPG Experience"
  type: "infrastructure"

capabilities:
  jacquard:
    pipeline:
      planner: true
      scheduler: true
      rag_retriever: true
      consolidation: true
  
  mnemosyne:
    state_management:
      mode: "full"
    memory:
      turn_summary: true
      macro_narrative: true
      event_extraction: true
      reflection: true
    retrieval:
      vector_storage: true
      semantic_search: true
    quest_system:
      enabled: true
      objective_tracking: true
```

**适用场景**: 复杂游戏系统、长程叙事  
**资源消耗**: 🟡 较高

## 8. UI 设计规范

### 8.1 能力配置界面

```
┌─────────────────────────────────────────────────────────────┐
│  ⚙️ 预设配置 - Standard RP                                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  📋 基础预设:  [Standard RP ▼]                               │
│                                                             │
│  ━━━ 编排能力 (Jacquard) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│  ☑ 智能规划器 (Planner)                                      │
│  ☑ 调度器 (Scheduler)                                       │
│  ☐ RAG检索器    [需: 向量存储]  [角色卡要求]                  │
│  ☐ 记忆整理 (Consolidation)  [需: 回合摘要]                   │
│                                                             │
│  ━━━ 数据能力 (Mnemosyne) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│  状态模式:  [标准 ▼]  (简单/标准/完整)                        │
│  ☑ VWD描述模式                                              │
│  ☐ ACL权限控制  [完整模式]                                    │
│                                                             │
│  ━━━ 记忆系统 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│  ☑ 回合摘要生成                                             │
│  ☐ 宏观叙事    [需: 回合摘要]                                │
│  ☐ 事件提取                                                  │
│  ☑ Head State持久化                                         │
│                                                             │
│  ━━━ 检索系统 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│  ☐ 向量存储    [开启后可用语义检索]                           │
│  ☐ 语义检索    [需: 向量存储]                                │
│  ☑ 关键词检索   历史窗口: [20] 条                            │
│                                                             │
│  ━━━ 任务系统 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│  ☐ 任务系统    [角色卡推荐开启]                              │
│                                                             │
│              [恢复默认]    [取消]    [应用]                   │
└─────────────────────────────────────────────────────────────┘
```

### 8.2 快速切换面板

```
┌──────────────────────┐
│ ⚡ 性能模式           │
├──────────────────────┤
│ ○ 省电   (极简)      │
│ ● 标准   (平衡)      │
│ ○ 完整   (全功能)    │
├──────────────────────┤
│ 高级功能              │
│ ☑ 回合摘要           │
│ ☐ RAG检索            │
│ ☐ 角色反思           │
└──────────────────────┘
```

## 9. 实现路径

### Phase 1: 核心能力框架

1. 实现 `CapabilitySchema` 和验证器
2. 改造 `Preset` 类，支持 `capabilities` 字段
3. 实现 `CapabilityMerger` 合并算法
4. 更新 `JacquardPipeline` 和 `MnemosyneEngine` 读取能力配置

### Phase 2: 功能开关集成

1. 将现有功能改造为能力检查模式
2. 实现依赖关系自动验证
3. 添加 UI 能力配置界面
4. 实现 L3 Patches 动态调整

### Phase 3: 预设套件

1. 设计并实现内置预设套件
2. 角色卡能力需求声明规范
3. 导入时能力兼容性检测
4. 性能监控与自动降级

---

## 附录 A: 能力命名规范

### A.1 Jacquard 能力

| 能力路径 | 类型 | 说明 |
|----------|------|------|
| `jacquard.pipeline.planner` | boolean | 智能规划器 |
| `jacquard.pipeline.scheduler` | boolean | 调度器 |
| `jacquard.pipeline.rag_retriever` | boolean | RAG检索器 |
| `jacquard.pipeline.consolidation` | boolean | 记忆整理 |
| `jacquard.skein_building.depth_injection` | boolean | 深度注入 |
| `jacquard.skein_building.lorebook_routing` | boolean | 世界书路由 |

### A.2 Mnemosyne 能力

| 能力路径 | 类型 | 说明 |
|----------|------|------|
| `mnemosyne.state_management.mode` | enum | 状态管理模式 |
| `mnemosyne.state_management.vwd_descriptions` | boolean | VWD描述 |
| `mnemosyne.memory.turn_summary` | boolean | 回合摘要 |
| `mnemosyne.memory.macro_narrative` | boolean | 宏观叙事 |
| `mnemosyne.retrieval.vector_storage` | boolean | 向量存储 |
| `mnemosyne.retrieval.semantic_search` | boolean | 语义搜索 |
| `mnemosyne.quest_system.enabled` | boolean | 任务系统 |
| `mnemosyne.scheduler.enabled` | boolean | 调度器 |

---

*本文档版本: 2.0.0 | 最后更新: 2026-02-13*