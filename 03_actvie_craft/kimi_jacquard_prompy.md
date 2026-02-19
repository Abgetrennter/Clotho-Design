基于对所有文档的深入分析，我发现以下几类问题：**接口不一致**、**职责重叠**、**概念重复**、**时序模糊**。以下是详细分析：

---

## 一、接口不一致 (Interface Mismatches)

### 1. Planner 输出 ↔ Skein Builder 输入

| 文档 | 定义 | 问题 |
|------|------|------|
| `planner-component.md` | Planner 产出 `CurationPlan` 和 `WeavingGuide` | WeavingGuide 包含 `historyChain`, `floatingAssets`, `systemExtensions` |
| `skein-and-weaving.md` | Skein Builder 操作 `SkeinInstance` | 包含 `systemChain`, `historyChain`, `floatingChain` |
| `README.md` | Builder 根据 "Planner 指定的 `templateId`" 组装 | 但未说明是否接受 WeavingGuide |

**冲突点**:
- WeavingGuide 的 `floatingAssets` 需要映射到 SkeinInstance 的 `floatingChain`，但字段名和结构不完全一致
- WeavingGuide 的 `systemExtensions` 在 SkeinInstance 中没有直接对应槽位

**建议**: 需要在 Skein 文档中明确 WeavingGuide 的映射规则，或统一术语。

---

### 2. Block Taxonomy ↔ BlockType

| 文档 | 定义 | 问题 |
|------|------|------|
| `preset-system.md` | Block Taxonomy: `META_IDENTITY`, `GUIDE_STYLE`, `COGNITION_INIT`, `QUAL_ANTI_REPEAT` | 分类维度：Meta/Content/Cognitive/Quality |
| `skein-and-weaving.md` | `BlockType`: `META_IDENTITY`, `CHAT_HISTORY`, `FLOATING_ASSET` | 分类维度：功能位置 (System/History/Floating) |

**冲突点**:
- Taxonomy 是"语义类型"，BlockType 是"位置类型"，两者是正交维度，但文档未说明如何映射
- 例如 `GUIDE_STYLE` (Taxonomy) 应该映射到什么 BlockType？`AXIOM`? `DIRECTIVE`?

**建议**: 需要一张映射表：

| Taxonomy | 默认 BlockType | 可覆盖 |
|----------|---------------|--------|
| `META_IDENTITY` | `AXIOM` (System Chain) | 否 |
| `GUIDE_STYLE` | `DIRECTIVE` (Floating, User Anchor) | 是 |
| `COGNITION_PLAN` | `DIRECTIVE` (Floating, Depth 2) | 是 |

---

## 二、职责重叠 (Overlapping Responsibilities)

### 3. Scheduler 动作注入 vs RAG Retriever

| 组件 | 职责 | 注入方式 |
|------|------|----------|
| **Scheduler** (优先级 200) | 触发时向 Skein 注入 Prompt | 通过修改 `JacquardContext.skein`? |
| **RAG Retriever** (优先级 350) | 检索记忆并注入 Skein | 输出到 `blackboard`，Builder 读取? |
| **Skein Builder** (优先级 300) | 组装 Skein | 读取各种输入 |

**冲突点**:
- Scheduler 优先级 200 < Builder 300，所以 Scheduler 的注入应该在 Builder 之前
- 但文档未明确 Scheduler 如何修改 Skein (直接修改 context.skein? 还是写入 blackboard?)
- 如果 Scheduler 直接修改 `context.skein`，那 Builder 的职责是什么？

**建议**: 明确分工：
- Scheduler: 写入 `context.blackboard['scheduler_injects']`
- RAG Retriever: 写入 `context.blackboard['rag_results']`
- Builder: 统一读取 blackboard 并组装 Skein

---

### 4. Consolidation Phase 的双重定位

| 文档 | 定位 | 问题 |
|------|------|------|
| `README.md` | 第 8 个插件，"Consolidation Phase (Worker)"，异步执行 | 放在 NativePlugins 中，但未给优先级 |
| `plugin-architecture.md` | 能力 `jacquard.pipeline.consolidation`，可选插件 | 优先级未定义 |
| `capability-system-spec.md` | `mnemosyne.memory.*` 下的功能 | 归属 Mnemosyne 而非 Jacquard? |

**冲突点**:
- Consolidation 是 Pipeline 插件还是后台 Worker？
- 如果是后台 Worker，为什么和 Planner/Builder 放在同一列表？
- 能力路径不一致：`jacquard.pipeline.consolidation` vs `mnemosyne.memory.*`

**建议**: 
- 明确区分：**Inline Pipeline** (同步) vs **Background Pipeline** (异步)
- Consolidation 属于 Background，不应该在 NativePlugins 顺序中

---

## 三、概念重复 (Redundant Concepts) ✅ 已修复

### 5. Capability 系统的文档分裂

**状态**: 已统一，`preset-system.md` 已改为引用 `capability-system-spec.md`

| 文档 | 当前职责 | 处理方式 |
|------|----------|----------|
| `capability-system-spec.md` | **权威规范**: 完整算法、命名空间、合并策略、Validation | 保持完整 |
| `preset-system.md` | **概览引用**: 5.2节改为引用链接，保留高层概念说明 | 删除重复实现细节 |

**已执行的修复**:

1. **算法统一** (`capability-system-spec.md` 第5节):
   - 采用 `merge({l1, l2, l3})` 方法签名
   - 统一使用 `withCapabilityEnabled()` 和 `merge()` 
   - 异常处理：抛出 `CapabilityConfigurationException`

2. **validate() 补全** (`capability-system-spec.md` 第4.4节):
   - 添加完整的验证流程：Requires → Mode Constraints → Conflicts → Cycle Detection
   - 添加 `autoFixes` 机制支持可自动修复的依赖
   - 添加 `ValidationResult.toJson()` 用于调试和UI展示

3. **依赖关系表统一** (`capability-system-spec.md` 第4.3节):
   | 能力 | 依赖 | 互斥 | 自动修复 |
   |------|------|------|----------|
   | `semantic_search` | `vector_storage` | - | 是 |
   | `macro_narrative` | `turn_summary` | - | 是 |
   | `spotlight_focus` | `planner` | - | 是 |
   | `vwd_descriptions` | `mode: standard/full` | `mode: simple` | 否 |
   | `planner` | `mode: standard/full` | `mode: simple` | 否 |

4. **文档引用关系**:
   - `preset-system.md` 5.2节简化为概览，添加链接引用 `capability-system-spec.md`
   - 删除 `preset-system.md` 中的 `CapabilityMerger` 详细实现代码

---

### 6. Weaving Rules 的双重定义

| 文档 | 定义 | 问题 |
|------|------|------|
| `preset-system.md` | `weaving_rules` 配置项，定义 AGENT/ENCYCLOPEDIA/DIRECTIVE 的注入策略 | YAML 配置格式 |
| `skein-and-weaving.md` | `WeavingRule` 接口定义，注入策略 | TypeScript 接口 |

**冲突点**:
- 配置格式 vs 运行时结构未明确映射
- `requires_capability` 字段在 preset 中有，但在 WeavingRule 接口中无

**建议**: 明确说明 `weaving_rules` YAML 如何解析为 `WeavingRule[]`

---

## 四、时序模糊 (Timing Ambiguities)

### 7. Scheduler 触发时机不明确

**问题**:
- `scheduler-component.md` 的架构图显示 Scheduler 订阅 `OnMessageReceived` 事件
- 但 `plugin-architecture.md` 的优先级系统显示 Scheduler 是 Pipeline 插件 (优先级 200)
- 这两个触发方式冲突：
  - 如果是事件订阅，应该在任何 Pipeline 执行前触发
  - 如果是 Pipeline 插件，只在主动执行 Pipeline 时触发

**建议**: 明确 Scheduler 的两种模式：
- **Inline Mode**: 作为 Pipeline 插件 (优先级 200)，每轮执行
- **Event Mode**: 订阅系统事件，触发额外的 Pipeline 执行

---

### 8. Planner 的 "Pre-Generation Update" 权限

| 文档 | 描述 | 问题 |
|------|------|------|
| `README.md` | "Planner 直接修改 L3 Session State" | Hard Write |
| `planner-component.md` (v1.2) | "Planner 不直接修改 `activeQuestId`，而是输出 suggestion" | Soft Suggestion |

**冲突点**: 文档版本不一致，权限模型冲突

**建议**: 统一为 v1.2 的 Soft Suggestion 模型，更新 README.md

---

## 五、关联性薄弱的模块

### 9. Schema Injector Plugin ✅ 已修复 (已整合)

**状态**: 已创建独立文档并与工作流整合

**已执行的修复**:

1. **创建独立文档**: `00_active_specs/jacquard/schema-injector.md`
   - 完整定义 Schema Injector 的职责、数据结构和执行流程
   - 明确优先级 350（Skein Builder 300 → Schema Injector 350 → Template Renderer 400）

2. **与 Block Taxonomy 的映射** (`schema-injector.md` 第5节):
   | Schema 内容 | BlockType | 注入位置 |
   |-------------|-----------|----------|
   | `instruction` (extension) | `META_FORMAT` | System Chain 末尾 |
   | `instruction` (mode/override) | `META_FORMAT_OVERRIDE` | System Chain 起始 |
   | `examples` | `COGNITION_EXAMPLE` | History Chain 前 |
   | `lore_context` | `ENCYCLOPEDIA` | Floating Chain |

3. **与 Skein 的集成** (`schema-injector.md` 第6节):
   - 定义 `PositionStrategy` 枚举：system_start/end, before/after_history, floating
   - 提供 `_injectIntoSkein()` 完整实现
   - Block 携带 Schema 元数据（schema_id, version, type）

4. **冲突解决机制** (`schema-injector.md` 第7节):
   - Root Tag 冲突：优先级高的覆盖
   - Override 互斥：仅保留优先级最高的
   - Core 版本冲突：抛出异常
   - Max Concurrent 超限：按优先级截断

5. **更新 README.md**: 添加指向新文档的链接

6. **与工作流文档整合** (详见 `integration_analysis_schema_injector.md`):
   - `prompt-processing.md`: 更新第 2.2 阶段，添加 Schema Injector 说明
   - `post-generation-processing.md`: 更新 Filament Parser 说明，添加动态标签注册
   - `schema-injector.md`: 添加 workflow 文档反向链接

**整合验证结果**:
- ✅ 流水线位置一致（优先级 350）
- ✅ BlockType 映射一致
- ✅ Blackboard Key 一致（`parser_hints`）
- ✅ Weaving 流程兼容

---

### 10. Maintenance Pipeline 与主 Pipeline 关系不明

- `README.md` 提到 Maintenance Pipeline 是独立后台流程
- 但与主 Pipeline 如何协调？共享哪些资源？
- 是否有独立的 Capability 控制？

**建议**: 需要明确 Maintenance Pipeline 的架构文档

---

## 六、综合建议：架构对齐方案

### 优先级 1: 接口统一 (Critical) ✅ 已修复

**状态**: 已同步到正式文档
- `00_active_specs/jacquard/planner-component.md` - 第8.1节
- `00_active_specs/jacquard/scheduler-component.md` - 第6节
- `00_active_specs/jacquard/skein-and-weaving.md` - 第3节
- `00_active_specs/jacquard/plugin-architecture.md` - Blackboard Key 规范

```yaml
# 统一的数据流接口 (已对齐正式规范)

Planner (产出 → planner_context):
  - planner_context.curation_plan: CurationPlan   # 上下文策展方案
  - planner_context.weaving_guide: WeavingGuide   # 编织指导指令
  - planner_context.suggestion: FocusSuggestion   # 焦点切换建议 (软写入)

Scheduler (产出 → blackboard):
  - blackboard.scheduler_injects: List[PromptBlock]   # 定时任务注入块

RAG Retriever (产出 → blackboard):
  - blackboard.rag_assets: List[FloatingAsset]        # 检索到的浮动资产

Skein Builder (消费):
  - 从 planner_context: curation_plan, weaving_guide
  - 从 blackboard: scheduler_injects, rag_assets
  - 产出: SkeinInstance
```

**关键修正**:
1. **Planner 输出位置**: 写入 `planner_context` (JacquardContext 的专用字段)，而非 blackboard
2. **WeavingGuide 字段对齐**: 
   - `historyChain` → 映射到 SkeinInstance.historyChain
   - `floatingAssets` → 映射到 SkeinInstance.floatingChain
   - `systemExtensions` → 合并入 systemChain 末尾
3. **Scheduler 注入方式**: 通过 `blackboard.scheduler_injects` 传递，Skein Builder 在构建阶段读取并合并

### 优先级 2: 文档合并/引用 (High)

| 内容 | 主文档 | 其他文档 |
|------|--------|----------|
| Capability 完整规范 | `capability-system-spec.md` | `preset-system.md` 引用即可 |
| Weaving 完整规范 | `skein-and-weaving.md` | `preset-system.md` 引用即可 |
| Block Type 映射 | 新建文档或在 Skein 中补充 | Taxonomy 和 BlockType 的映射表 |

### 优先级 3: 架构图统一 (Medium)

建议绘制一张统一的端到端数据流图，标注：
- 每个组件的输入/输出
- Blackboard 的 Key 规范
- Capability 的开关影响点
