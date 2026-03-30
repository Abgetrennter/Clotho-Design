# 第二章：系统核心架构与编排层 (Jacquard Layer)

**版本**: 1.1.0
**日期**: 2026-03-11
**状态**: Active
**作者**: 资深系统架构师 (Architect Mode)
**源文档**: `system_architecture.md`, `mvu_integration_design.md`

---

## 📖 术语使用说明

本文档混合使用**隐喻术语**和**技术术语**：

| 隐喻术语 (架构概念) | 技术术语 (代码实现) | 说明 |
|-------------------|-------------------|------|
| Skein (绞纱) | **PromptBundle** (提示词包) | Prompt 组装容器 |
| Shuttle (梭子) | **Plugin** (插件) | 流水线功能单元 |
| Weaving (编织) | **Assemble** (组装) | Prompt 构建过程 |
| Tapestry (织卷) | **Session** (会话) | 运行时实例 |

在代码实现时，请使用 [`../naming-convention.md`](../naming-convention.md) 中定义的技术术语。

---

## 1. 编排层概览 (Jacquard Overview)

**Jacquard** 是逻辑层的核心，它被重新设计为一个 **Pipeline Runner**。它不包含具体的业务逻辑，而是负责按顺序执行注册的插件。它是系统的“大脑”，通过确定性的编排来驾驭概率性的 LLM 生成。

### 1.1 核心职责

1. **流程调度**: 协调 Prompt 组装、API 调用、结果解析等步骤。
2. **Skein 构建**: 维护上下文容器，支持动态裁剪。
3. **模板渲染与格式化**: 集成 Jinja2 引擎，负责将 Mnemosyne 的原生数据对象转换为适合 LLM 的文本格式（如 YAML），并进行动态组装。
4. **意图与焦点管理**: 通过 Planner Plugin 实现任务分流与长线记忆的聚焦。
5. **协议解析**: 实时解析 Filament 协议流，分发事件。

### 1.2 架构拓扑

```mermaid
graph TD
    classDef orch fill:#fff3e0,stroke:#e65100,stroke-width:2px;
    
    subgraph Jacquard [Jacquard Pipeline]
        Bus[Jacquard 总线]:::orch
        
        subgraph NativePlugins [原生插件流水线]
            Planner[Planning Phase (Planner) Plugin]:::orch
            Scheduler[Scheduler Shuttle]:::orch
            Builder[Skein Builder]:::orch
            Renderer[Template Renderer (Jinja2)]:::orch
            Assembler[Prompt Assembler]:::orch
            Invoker[LLM Invoker]:::orch
            Parser[Filament Parser]:::orch
            Updater[State Updater]:::orch
            Consolidation[Consolidation Phase (Worker)]:::orch
        end

        subgraph Maintenance [维护流水线]
            BatchPipeline[Batch Processor Shuttle]:::orch
        end
    end
```

---

## 2. 插件化流水线 (Pipeline Mechanics)

Jacquard 维护一个插件列表，每个插件实现特定的接口。这种设计允许系统灵活扩展，甚至支持用户自定义逻辑。

### 2.0 动态优先级编排 (Dynamic Priority Orchestration)

不同于传统的硬编码优先级系统，Jacquard 采用**声明式、可重编程的优先级编排**：

| 特性 | 硬编码系统 | 动态编排系统 |
|------|-----------|-------------|
| 配置方式 | 代码常量 | YAML 声明式配置 |
| 执行顺序 | 固定 | 基于 `after`/`before` 约束自动拓扑排序 |
| 优先级调整 | 静态 | 支持运行时条件表达式动态计算 |
| Pattern (织谱) 定制 | 不支持 | L2 Pattern 可覆盖默认编排 |

**核心机制**:
1. **阶段 (Phase)**: 将流水线划分为 `decision` → `preparation` → `construction` → `execution` → `processing`
2. **相对顺序 (Ordering)**: 通过 `after`/`before` 声明依赖关系，而非硬编码数字
3. **动态优先级 (Dynamic Priority)**: `base + modifiers`，支持基于运行时状态的调整

详见 [`plugin-architecture.md`](plugin-architecture.md#43-动态优先级编排)。

### 2.1 核心插件定义

1. **Planning Phase (Planner) Plugin**:
    * **定位**: 系统的"副官 (Adjutant)"，在生成开始前负责决策"本轮聊什么"以及"如何聊"。
    * **核心职责 (The 3 Pillars)**:
        * **1. 聚焦管理 (Focus Management)**: **聚光灯 (Spotlight)** 机制。检测用户是否想切换话题，据此更新 `state.planner_context.activeQuestId`，实现任务的挂起与激活。
        * **2. 目标规划 (Goal Planning)**: 在进入 Skein 构建前，直接写入 L3 State 的 `planner_context`，更新 `current_goal` 和 `pending_subtasks`，为 Main LLM 设定具体的战术目标。
        * **3. 策略选型 (Strategy)**: 决定使用哪个 Prompt Template (Skein ID)（如"日常模式"、"战斗模式"、"回忆模式"）。
    * **数据权限**:
        * **Read**: History, Active Quests, Lorebook Metadata.
        * **Write**: `planner_context` (Pre-Generation Update). 这是一个特殊的权限，允许 Planner 在 LLM 介入前直接修改逻辑上下文。
    * **决策流**:
        ```mermaid
        graph TD
            UserInput[用户输入] --> Planner[Planning Phase Planner]
            
            subgraph "Planner Decision Brain"
                CheckFocus{1. Intent Change?}
                
                CheckFocus -- "Switch Topic" --> Switch[Update activeQuestId\nSuspend Old Quest]
                CheckFocus -- "Continue" --> Keep[Keep Focus]
                
                Switch & Keep --> SetGoal[2. Update current_goal\n(Write to L3 Context)]
                SetGoal --> SelectTempl[3. Select Template ID]
            end
            
            SelectTempl --> SkeinBuilder[Proceed to Skein Builder]
        ```
    * **产出**: `PlanContext` (包含模板 ID、初始指令、更新后的 `planner_context`)。

2. **Scheduler Shuttle Plugin**:
    * **定位**: 自动化任务执行器。
    * **职责**: 基于时间（楼层）或事件（变量变更）触发预定义任务。
    * **动作**: 维护全局计数器 (`scheduler_context`)，执行注入 Prompt 或更新状态的动作。
    * **输出**: 写入 `blackboard.scheduler_injects` (`List<PromptBlock>`)。
    * **优先级**: 默认 200 (`preparation` 阶段)，可通过动态编排调整。
    * **详情**: 参见 [`scheduler-component.md`](scheduler-component.md)。

3. **RAG Retriever Plugin**:
    * **定位**: 长期记忆检索器。
    * **职责**: 基于用户输入语义检索相关历史 (Turn Summaries, Macro Narratives) 和 Lorebook。
    * **动作**: 执行向量相似度搜索，产出 `FloatingAsset` 列表。
    * **输出**: 写入 `blackboard.rag_assets` (`List<FloatingAsset>`)。
    * **优先级**: 默认 250 (`preparation` 阶段)，通常位于 Scheduler 之后、Builder 之前。
    * **与 Scheduler 关系**: 两者同属 `preparation` 阶段，通过动态编排可调整先后顺序。
    * **详情**: 参见 [`scheduler-component.md`](../scheduler-component.md#7-与-rag-retriever-的职责分工)。

4. **Skein Builder Plugin**:
    * **职责**: 向数据层 (Mnemosyne) 请求快照 (`Punchcards`)，并整合所有 Blackboard 产物。
    * **输入来源**:
        * `planner_context.weaving_guide` (Planner 产出)
        * `blackboard.scheduler_injects` (Scheduler 产出)
        * `blackboard.rag_assets` (RAG Retriever 产出)
    * **Routing Logic**: v1.2 引入了基于 `LorebookCategory` 的分流装填逻辑。
        * **Axiom**: 注入到 `System Chain` (Extension Block)。
        * **Agent**: 注入到 `Floating Chain` (High Priority, Depth 3-5)。
        * **Encyclopedia**: 注入到 `Floating Chain` (Standard Priority, Depth 5-10)。
        * **Directive**: 注入到 `Instruction Block` (紧邻 User Input)。
    * **产出**: 初始化的 `Skein` 对象。
    * **优先级**: 300 (`construction` 阶段)。

5. **Template Renderer Plugin (Jinja2)**:
    * **原 PromptASTExecutor**: 已升级为标准的模板渲染引擎。
    * **职责**: 编译并执行 Skein 中的 Jinja2 模板（支持 `{% if %}`, `{% set %}` 等逻辑）。
    * **输入**: 包含 Jinja2 语法的 Skein。
    * **上下文**: 注入 `Mnemosyne` 状态树（只读）和 `Skein` 元数据。
    * **产出**: 逻辑处理完毕、变量已替换的纯文本 Skein。

6. **LLM Invoker Plugin**:
    * 职责: 调用 LLM API，获取流式响应。
    * 输入: 最终渲染的 Prompt 字符串。

7. **Filament Parser Plugin**:
    * 职责: 实时解析 LLM 的 Filament 输出。
    * 动作: 提取 `<reply>` 推送给 UI，提取 `<state_update>` 准备后续处理。

8. **State Updater Plugin**:
    * 职责: 收集所有状态变更指令。
    * 动作: 调用 Mnemosyne 更新状态，并持久化历史。

9. **Consolidation Phase (Worker)**:
    * **职责**: 记忆整合与归档（异步执行）。负责处理 **增量 (Incremental)、近实时** 的记忆整理。
    * **动作**: 在会话结束或缓冲区满时，提取关键事件存入 Event Chain，生成角色反思，并归档原始日志。

10. **维护流水线 (MaintenancePipeline & BatchShuttle)**:
    * **职责**: 负责处理 **批量 (Bulk)、非实时** 的重型维护任务。这是 Consolidation Phase 的必要补充。
    * **场景**:
        * **历史导入 (History Import)**: 处理外部导入的成百上千条聊天记录，分块快速重建状态和事件链。
        * **长线记忆重构 (Memory Refactoring)**: 当用户修改世界设定或觉得 AI 变笨时，对过去的历史记忆进行一次全量的“重新总结”。
    * **动作**: 在独立的后台 `MaintenancePipeline` 中运行，分块读取历史，模拟 AI “阅读”并批量提交更新，低频高吞吐。

11. **[Schema Injector Plugin](schema-injector.md)**:
    * **职责**: 管理协议 Schema 的动态注入。
    * **动作**: 扫描 Pattern (织谱) 配置和动态协议标签 (`<use_protocol>`)，加载对应的 YAML Schema，并将其 `instruction` 和 `examples` 合并到 Skein 中。
    * **优先级**: 350 (位于 Skein Builder 之后、Template Renderer 之前)

### 2.2 宏与脚本沙箱 (Macro & Script Sandbox)

为了支持用户自定义扩展和安全的逻辑控制，系统采用了双层沙箱策略：

1. **Jinja2 Sandbox (Macro Layer)**:
    * 用于 Prompt 组装阶段的文本生成和简单逻辑控制。
    * 特性: 语法简洁，天然无副作用（无法修改 Mnemosyne），适合处理“动态开关”和“内容注入”。
2. **QuickJS/LuaJIT (Script Layer)**:
    * 用于复杂的业务逻辑计算（如伤害公式）。
    * 特性: 功能强大，但受限于严格的 API 白名单。

---

## 3. Skein (绞纱) - 结构化 Prompt 容器

**Skein** 是 Jacquard 流水线处理的核心数据对象。它是一个 **异构容器 (Heterogeneous Container)**，模块化地管理 System Prompt, Lore, User Input 等内容。

详细的数据结构定义与编织算法请参阅 **[Skein 编织系统设计规范](skein-and-weaving.md)**。

### 3.1 为什么需要 Skein?

传统的字符串拼接方式（String Concatenation）在处理复杂上下文时难以维护且容易出错。Skein 允许我们以“块 (Block)”为单位管理 Prompt，支持动态排序、裁剪和优先级控制。
**结合 Jinja2**: 每个 Block 都可以是一段 Jinja2 模板，在渲染阶段动态求值。

### 3.2 深度注入 (Depth Injection) 与块结构

为了支持类似 SillyTavern 的高级注入机制（如“在倒数第3条消息前插入 World Info”），Skein 被重新设计为基于 **PromptBlock** 的复合结构。

#### 3.2.1 PromptBlock 定义

每个 Block 不再仅仅是字符串，而是包含元数据的原子单元：

* **Content**: 文本内容或 Jinja2 模板。
* **Role**: 语义角色 (System, User, Assistant, Tool)，最终映射到 API 格式。
* **InjectionConfig**: (可选) 定义该 Block 的注入策略。
  * `position`: `relativeToStart` (从头数) 或 `relativeToEnd` (从尾数/深度)。
  * `depth`: 具体的偏移量索引。

#### 3.2.2 Skein 链网结构

Skein 内部维护三条逻辑链：

1. **System Chain**: 固定的头部指令 (System Prompt, Main Scenario)。
2. **History Chain**: 标准的 Threads (丝络) (Linear Chat History)。
3. **Floating Chain (浮动链)**: 尚未确定最终位置的注入块 (World Info, Author's Note, RAG 结果)。这些块带有 `InjectionConfig`，将在编织阶段被“缝合”进历史链。

### 3.3 编织 (Weaving) 算法

在 `Assembler` 阶段之前，必须执行 **Weaving** 操作，将 `Floating Chain` 合并入 `History Chain`。

1. **Clone**: 复制当前的 History Chain。
2. **Sort**: 根据 `depth` 和 `priority` 对 Floating Chain 进行排序。
3. **Inject**: 遍历 Floating Chain，根据 `relativeToEnd` 计算目标索引，将其插入到 History Chain 的特定位置。
4. **Output**: 生成最终的有序 Block 列表供 Assembler 使用。

---

## 5. 注入与处理流程 (Injection Workflow)

### 5.1 Jacquard 组装流程

1. **扫描**: Jacquard 扫描当前 Pattern (织谱) 配置 + 活跃的动态协议列表。
2. **加载**: 从 `data/schemas` 读取对应的 YAML 文件。
3. **合并**:
    * 将 `instruction` 内容按优先级合并到 System Prompt 的 `Extension Block` 区域。
    * 将 `examples` 合并到 Few-shot Examples 区域。
4. **注册**: 将 `parser_hints` 注册到 Filament Parser 的配置中，确保流式解析器知道如何处理新出现的标签（例如 `<live>`）。

### 5.2 冲突解决

* 如果多个 Schema 定义了相同的 `parser_hints.root_tag`，优先级高的覆盖优先级低的。
* 如果同时激活了多个 `type: override` 的 Schema，系统应发出警告或仅使用优先级最高的一个。

---

## 6. Filament 协议 (Filament Protocol)

**Filament 协议**是 Clotho 系统的通用交互语言，贯穿于系统的所有交互环节。由于协议的复杂性和广泛的应用范畴，Filament 协议已独立为专门的章节进行详细阐述。

### 6.1 协议定位

* **输入端**: 使用 **XML + YAML** 格式构建结构化 Prompt，确保 LLM 理解内容的层级与边界。
* **输出端**: 使用 **XML + JSON** 格式定义意图和参数，实现确定性的机器解析。

### 6.2 在 Jacquard 中的应用

Jacquard 编排层作为 Filament 协议的主要使用者和分发者：

1. **Prompt 组装**: Skein Builder 使用 Filament 格式组装 System Prompt、Pattern (织谱)、World State 等内容。
2. **输出解析**: Filament Parser 插件实时解析 LLM 的流式输出，识别并分发不同的标签。
3. **状态更新**: 将 `<state_update>` 标签中的 JSON 指令传递给 Mnemosyne 执行。
4. **UI 事件**: 将 `<ui_component>` 标签中的组件请求发送给表现层渲染。

### 6.3 详细文档

Filament 协议的完整规范、标签体系、解析流程、版本演进等内容请参阅 **[Filament 协议概述](../protocols/filament-protocol-overview.md)**。

**关键章节索引**:

* **输入协议**: [Filament 输入格式](../protocols/filament-input-format.md) - 提示词构建
* **输出协议**: [Filament 输出格式](../protocols/filament-output-format.md) - 指令与响应
* **Jinja2 宏系统**: [Jinja2 宏系统](../protocols/jinja2-macro-system.md) - 动态提示词构建
* **Schema 库规范**: [Schema 库规范](../protocols/schema-library.md) - 协议库存储与引用
* **解析流程**: [Filament 解析流程](../protocols/filament-parsing-workflow.md) - 协议解析流程
* **最佳实践与约束**: 请参阅输出格式文档中的最佳实践章节
* **性能优化**: 请参阅解析流程文档中的性能优化章节