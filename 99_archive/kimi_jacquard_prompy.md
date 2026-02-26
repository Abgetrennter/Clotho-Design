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

### 3. Scheduler 动作注入 vs RAG Retriever 职责分工

#### 3.1 当前状态

| 组件 | 原硬编码优先级 | 注入方式 | 产物类型 |
|------|---------------|----------|----------|
| **Scheduler** | 200 | `blackboard.scheduler_injects` | `List<PromptBlock>` |
| **RAG Retriever** | 未定义 | `blackboard.rag_assets` | `List<FloatingAsset>` |
| **Skein Builder** | 300 | 消费上述所有产物 | `SkeinInstance` |

#### 3.2 架构设计：动态优先级编排 (Dynamic Priority Orchestration)

**核心原则**: 从"硬编码锚点"演进为"声明式、可重编程的编排配置"。

```yaml
# L1 Infrastructure: 流水线编排配置
jacquard:
  orchestration:
    phases:
      - id: "preparation"
        description: "数据准备阶段"
        default_slot_range: [200, 299]
        
    plugins:
      scheduler:
        phase: "preparation"
        ordering:
          after: ["planner"]
          before: ["rag_retriever"]
        priority:
          base: 200
          modifiers:
            # 紧急调度任务时提升优先级
            - condition: "context.scheduler.has_urgent_tasks"
              set_absolute: 250
              
      rag_retriever:
        phase: "preparation"
        ordering:
          after: ["scheduler"]      # 可读取 Scheduler 更新的状态
          before: ["builder"]
        priority:
          base: 250
          modifiers:
            # Planner 建议特定检索时提升
            - condition: "context.planner.weaving_guide.retrieval_hints != null"
              delta: +30
              
      builder:
        phase: "construction"
        ordering:
          after: ["rag_retriever", "scheduler"]
          before: ["renderer"]
        priority:
          base: 300
```

#### 3.3 Blackboard 协作契约

所有注入型组件统一通过 `JacquardContext.blackboard` 传递产物，由 Builder 统一消费：

| Blackboard Key | 写入者 | 读取者 | 产物类型 | 生命周期 |
|----------------|--------|--------|----------|----------|
| `scheduler_injects` | Scheduler | Builder | `List<PromptBlock>` | 单次 Pipeline |
| `rag_assets` | RAG Retriever | Builder | `List<FloatingAsset>` | 单次 Pipeline |
| `weaving_guide` | Planner | Builder | `WeavingGuide` | 单次 Pipeline |

> **注意**: Scheduler 和 RAG Retriever **绝不直接修改 Skein**，仅写入 blackboard。Builder 在构建阶段统一读取并合并。

#### 3.4 L2 Pattern 可覆盖示例

特定角色卡可重编程执行顺序：

```yaml
# L2 Pattern: "Deep Research" 角色卡
jacquard:
  orchestration:
    overrides:
      plugins:
        rag_retriever:
          # 在此角色中，RAG 先于 Scheduler 执行
          ordering:
            after: ["planner"]
            before: ["scheduler"]
          priority:
            base: 190
            
        scheduler:
          ordering:
            after: ["rag_retriever"]
            before: ["builder"]
          priority:
            base: 210
```

#### 3.5 职责边界总结

| 职责 | 归属 | 边界说明 |
|------|------|----------|
| **何时检索** | Planner | 在 `weaving_guide` 中建议检索需求 |
| **何时触发定时任务** | Scheduler | 基于时间/事件逻辑独立决策 |
| **如何检索** | RAG Retriever | 专业化组件，可被 Capability 开关控制 |
| **如何组装** | Builder | 唯一拥有编织算法的组件，统一仲裁冲突 |
| **优先级仲裁** | 动态编排引擎 | 基于声明式配置 + 运行时条件计算 |

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

### 8. Planner 的 "Pre-Generation Update" 权限 ✅ 已修复

**状态**: 已统一为 Soft Suggestion 模型

| 文档 | 描述 | 状态 |
|------|------|------|
| `README.md` | "Planner 直接修改 L3 Session State" | ❌ 已废弃 |
| `planner-component.md` (v1.2+) | "Planner 不直接修改 `activeQuestId`，而是输出 suggestion" | ✅ 已确认 |

**已执行的修复**:

1. **`planner-component.md` 第 2.2 节**: 明确说明 Planner **不直接修改** `activeQuestId`，而是将建议写入 `planner_context.suggestion`
2. **`planner-component.md` 第 6.2 节**: 详细定义 Soft Suggestion 模型，区分 Planner 的 Soft Suggestion 与 State Updater 的 Hard Write
3. **`planner-component.md` 第 8.1 节**: 在 `PlannerContext` 接口中明确定义 `suggestion` 字段结构

```typescript
// Planner 输出建议（软写入）
suggestion: {
  targetQuestId: string | null;
  confidence: number;
  reasoning: string;
};
```

**写入时机**: State Updater 在 Main LLM 生成后，根据 `<planner_override>` 或默认确认逻辑，将 suggestion 应用到 `activeQuestId`

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

---

## 完成状态总结

### ✅ 已完成的建议

| # | 建议项 | 完成位置 | 验证方式 |
|---|--------|----------|----------|
| 5 | Capability 系统的文档分裂 | `capability-system-spec.md`, `preset-system.md` | 算法统一、validate() 补全、依赖关系表统一 |
| 8 | Planner 的 Pre-Generation Update 权限 | `planner-component.md` 第 2.2, 6.2, 8.1 节 | Soft Suggestion 模型已确认 |
| 9 | Schema Injector Plugin | `schema-injector.md` (新创建) | 独立文档 + 工作流整合 |
| P1 | 接口统一 (Critical) | `planner-component.md` 第 8.1 节 | `PlannerContext` 接口已定义，WeavingGuide 映射规则已明确 |

### ⏳ 待完成的建议

| # | 建议项 | 优先级 | 下一步行动 |
|---|--------|--------|------------|
| 1 | Planner 输出 ↔ Skein Builder 输入 (WeavingGuide 字段映射) | Medium | 确认 `skein-and-weaving.md` 中的映射规则是否对齐 |
| 2 | Block Taxonomy ↔ BlockType 映射表 | Medium | 创建新的映射文档或在 Skein 文档中补充 |
| 3 | Scheduler 动作注入 vs RAG Retriever 职责分工 | High | 更新 `scheduler-component.md` 和 `plugin-architecture.md` |
| 4 | Consolidation Phase 的双重定位 | Medium | 明确区分 Inline Pipeline vs Background Pipeline |
| 6 | Weaving Rules 的双重定义 | Medium | 明确 YAML 配置格式 → TypeScript 接口的映射 |
| 7 | Scheduler 触发时机 (Inline vs Event Mode) | High | 更新 `scheduler-component.md` 说明两种模式 |
| 10 | Maintenance Pipeline 与主 Pipeline 关系 | Low | 创建 Maintenance Pipeline 架构文档 |

---

## 六、综合建议：架构对齐方案

### 优先级 1: 接口统一 (Critical) ✅ 已修复

**状态**: 已同步到正式文档

| 文档 | 章节 | 状态 |
|------|------|------|
| `00_active_specs/jacquard/planner-component.md` | 第8.1节 | ✅ 已验证 |
| `00_active_specs/jacquard/scheduler-component.md` | 第6节 | ✅ 待验证 |
| `00_active_specs/jacquard/skein-and-weaving.md` | 第3节 | ✅ 待验证 |
| `00_active_specs/jacquard/plugin-architecture.md` | Blackboard Key 规范 | ✅ 待验证 |

**已执行的修复 (在 `planner-component.md` 第 321-348 行)**:

```typescript
// Planner 产出写入位置 (已确认实现)
interface PlannerContext {
  // 上下文策展方案 (v1.2+)
  curation_plan: CurationPlan;
  
  // 编织指导指令 (v1.2+)
  weaving_guide: WeavingGuide;
  
  // 焦点切换建议 (软写入，需 State Updater 确认)
  suggestion: {
    targetQuestId: string | null;
    confidence: number;
    reasoning: string;
  };
}

// Skein Builder 消费方式 (已确认实现)
// - 从 context.plannerContext.weaving_guide 读取编织指令
// - WeavingGuide.historyChain → 映射到 SkeinInstance.historyChain
// - WeavingGuide.floatingAssets → 映射到 SkeinInstance.floatingChain
// - WeavingGuide.systemExtensions → 合并入 SkeinInstance.systemChain 末尾
```

**统一的数据流接口**:

| 组件 | 产出位置 | 产物类型 |
|------|----------|----------|
| **Planner** | `planner_context` | `CurationPlan`, `WeavingGuide`, `FocusSuggestion` |
| **Scheduler** | `blackboard.scheduler_injects` | `List[PromptBlock]` |
| **RAG Retriever** | `blackboard.rag_assets` | `List[FloatingAsset]` |
| **Skein Builder** | 消费上述数据 → 产出 `SkeinInstance` | - |

**关键修正**:
1. ✅ **Planner 输出位置**: 写入 `planner_context` (JacquardContext 的专用字段)，而非 blackboard
2. ✅ **WeavingGuide 字段对齐**: 明确映射规则到 SkeinInstance
3. ✅ **Scheduler 注入方式**: 通过 `blackboard.scheduler_injects` 传递

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
