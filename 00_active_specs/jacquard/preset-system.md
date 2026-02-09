# Jacquard 预设与编排系统 (Preset & Orchestration System)

**版本**: 1.0.0
**日期**: 2026-02-09
**状态**: Draft
**关联文档**:
- [`README.md`](README.md)
- [`../workflows/prompt-processing.md`](../workflows/prompt-processing.md)
- [`../protocols/filament-protocol-overview.md`](../protocols/filament-protocol-overview.md)

---

## 1. 核心理念 (Core Philosophy)

在 Clotho 架构中，**预设 (Preset)** 不再仅仅是一组静态的 API 参数或 System Prompt 字符串。它是 **Jacquard 编排层的配置蓝图 (Orchestration Blueprint)**。

### 1.1 预设的定义
预设是一个结构化的配置包，它告诉 Jacquard：
1.  **Thinking**: 如何进行认知处理（L1 - 基础能力）。
2.  **Mapping**: 如何理解角色和世界（L2 - 适配层）。
3.  **Reacting**: 如何在当前会话中动态调整（L3 - 实例层）。

### 1.2 解决的问题
*   **Prompt 结构僵化**: 传统方案难以根据上下文动态调整 Prompt 结构（例如在战斗时切换为短指令）。
*   **语义缺失**: 只有简单的文本拼接，缺乏对 Block 功能（如“破甲”、“防重复”）的语义理解，导致无法进行高级调度。
*   **配置割裂**: 模型参数、提示词模板、世界书设置分散在不同地方，难以统一管理和分享。

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
**定位**: 底层的、通用的“大脑配置”。通常由系统内置或高级用户创建（如 "Novel Writer Base", "Chat Bot Base"）。

*   **API Strategy**: 模型选择、参数预设 (Temp, TopP)、重试策略。
*   **Skein Skeleton**: 定义 Skein 的基础骨架（哪些块在前，哪些块在后）。
*   **Weaving Rules**: 定义浮动资产（如 Lorebook, RAG）的注入策略（插入位置、深度、优先级）。
*   **Block Taxonomy**: 定义可用的 Prompt Block 类型及其默认行为。
*   **Filament Config**: 协议版本、启用的标签集 (Thought, Command)。

### 2.2 L2: 角色与世界适配 (Character & World Adaptation)
**定位**: 中间层的“风格滤镜”。通常在导入角色卡或加载世界书时生成。

*   **Style Enforcement**: 具体的文风指导（提取自角色卡）。
*   **Lore Strategy**: 世界书的触发机制（关键词/向量）和插入位置。
*   **Mapping Rules**: 角色卡字段 (Description, Scenario) 如何映射到 L1 定义的 Block 中。

### 2.3 L3: 会话自定义 (Session Customization)
**定位**: 顶层的“动态补丁”。存储在会话 (Tapestry) 中。

*   **User Overrides**: 用户手动修改的指令（如“别用 XML 了”）。
*   **Ephemeral Blocks**: 临时注入的 Author's Note 或 Slash Command 结果。

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

---

## 4. 配置结构示例 (YAML Schema)

```yaml
# preset_v1.yaml

metadata:
  name: "Standard Roleplay v1"
  version: "1.0.0"
  author: "Clotho Team"

# L1 Configuration
infrastructure:
  model:
    prefer: ["gpt-4", "claude-3-opus"]
    params:
      temperature: 0.8
      max_tokens: 2048

  # 定义分组 (Groups)
  groups:
    - id: "grp_jailbreak"
      name: "Jailbreak & Safety"
      default_enabled: true
      types: ["META_JAILBREAK", "QUAL_AGENCY"]
      
    - id: "grp_style"
      name: "Stylistic Control"
      default_enabled: true
      types: ["GUIDE_STYLE", "GUIDE_NARRATIVE"]
  
  # 1. 定义 Skein 的骨架 (Skeleton)
  # 决定了 System Chain 的基本构成顺序
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

  # 2. 定义编织规则 (Weaving Rules)
  # 决定了 Floating Chain (Lorebook/RAG) 如何插入到 History 中
  weaving_rules:
    # 代理状态 (Agent Status): 插入到近几条历史中
    - type: "AGENT"
      target_chain: "history"
      position: "relative_to_message"
      depth_range: [2, 4] # 倒数第2-4条之间
      priority: 90
    
    # 背景知识 (Encyclopedia): 插入到较深的历史背景中
    - type: "ENCYCLOPEDIA"
      target_chain: "history"
      position: "relative_to_message"
      depth_range: [5, 10]
      priority: 50
      
    # 即时指令 (Directives): 紧贴用户最新的输入
    - type: "DIRECTIVE"
      target_chain: "history"
      position: "anchor_to_user"
      offset: 0 
      priority: 110

# L2 Adaptation (Default Templates)
adaptation:
  default_blocks:
    - id: "sys_identity"
      type: "META_IDENTITY"
      content: "You are {{ char }}. {{ description }}"
    
    - id: "qual_anti_repeat"
      type: "QUAL_ANTI_REPEAT"
      content: "[System: Avoid repetition. Do not reuse user's phrases.]"

# L3 Overrides (Runtime Placeholders)
session:
  allow_user_overrides: true
  inject_authors_note: true
```

---

## 5. 实现路径

1.  **数据结构**: 在 `Jacquard` 中实现 `Preset` 和 `Block` 的类定义 (TypeScript/Python)。
2.  **解析器**: 实现 YAML 配置加载器，支持 L1/L2/L3 的合并逻辑 (Deep Merge)。
3.  **编排器升级**: 改造 `SkeinBuilder`，使其支持基于 `BlockType` 的过滤和排序。
4.  **UI 支持**: 前端需要提供可视化的 Preset 编辑器，允许用户拖拽 Block 并分配类型。
