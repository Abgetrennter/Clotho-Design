# 第二章：系统核心架构与编排层 (Jacquard Layer)

**版本**: 1.0.0
**日期**: 2025-12-23
**状态**: Draft
**作者**: 资深系统架构师 (Architect Mode)
**源文档**: `system_architecture.md`, `mvu_integration_design.md`

---

## 1. 编排层概览 (Jacquard Overview)

**Jacquard** 是逻辑层的核心，它被重新设计为一个 **Pipeline Runner**。它不包含具体的业务逻辑，而是负责按顺序执行注册的插件。它是系统的“大脑”，通过确定性的编排来驾驭概率性的 LLM 生成。

### 1.1 核心职责

1. **流程调度**: 协调 Prompt 组装、API 调用、结果解析等步骤。
2. **Skein 构建**: 维护上下文容器，支持动态裁剪。
3. **模板渲染**: 集成 Jinja2 引擎，支持高级宏逻辑和动态内容组装。
4. **协议解析**: 实时解析 Filament 协议流，分发事件。

### 1.2 架构拓扑

```mermaid
graph TD
    classDef orch fill:#fff3e0,stroke:#e65100,stroke-width:2px;
    
    subgraph Jacquard [Jacquard Pipeline]
        Bus[Jacquard 总线]:::orch
        
        subgraph NativePlugins [原生插件流水线]
            PreFlash[Pre-Flash (Planner) Plugin]:::orch
            Builder[Skein Builder]:::orch
            Renderer[Template Renderer (Jinja2)]:::orch
            Assembler[Prompt Assembler]:::orch
            Invoker[LLM Invoker]:::orch
            Parser[Filament Parser]:::orch
            Updater[State Updater]:::orch
            PostFlash[Post-Flash (Consolidation) Worker]:::orch
        end
    end
```

---

## 2. 插件化流水线 (Pipeline Mechanics)

Jacquard 维护一个插件列表，每个插件实现特定的接口。这种设计允许系统灵活扩展，甚至支持用户自定义逻辑。

### 2.1 核心插件定义

1. **Pre-Flash (Planner) Plugin**:
    * **职责**: 意图分流与长短期目标规划。
    * **短期规划**: 识别用户意图是“日常数值交互”还是“关键剧情事件”。
    * **长期规划 (新增)**: 读取并更新 L3 Session State 中的 `planner_context`，确保跨轮次的叙事连贯性。
* **动作**: 如果是数值交互，直接计算结果并短路后续流程；如果是事件，则规划使用哪个 Skein 模板，并更新 `planner_context`。
* **产出**: `PlanContext` (包含模板 ID、初始指令、更新后的 `planner_context`)。

2. **Skein Builder Plugin**:
    * 职责: 向数据层 (Mnemosyne) 请求快照 (`Punchcards`)。
    * 产出: 初始化的 `Skein` 对象。

3. **Template Renderer Plugin (Jinja2)**:
    * **原 PromptASTExecutor**: 已升级为标准的模板渲染引擎。
    * **职责**: 编译并执行 Skein 中的 Jinja2 模板（支持 `{% if %}`, `{% set %}` 等逻辑）。
    * **输入**: 包含 Jinja2 语法的 Skein。
    * **上下文**: 注入 `Mnemosyne` 状态树（只读）和 `Skein` 元数据。
    * **产出**: 逻辑处理完毕、变量已替换的纯文本 Skein。

4. **LLM Invoker Plugin**:
    * 职责: 调用 LLM API，获取流式响应。
    * 输入: 最终渲染的 Prompt 字符串。

5. **Filament Parser Plugin**:
    * 职责: 实时解析 LLM 的 Filament 输出。
    * 动作: 提取 `<reply>` 推送给 UI，提取 `<state_update>` 准备后续处理。

6. **State Updater Plugin**:
    * 职责: 收集所有状态变更指令。
    * 动作: 调用 Mnemosyne 更新状态，并持久化历史。

7. **Post-Flash (Consolidation) Worker**:
    * **职责**: 记忆整合与归档（异步执行）。负责处理 **增量、近实时** 的记忆整理。
    * **动作**: 在会话结束或缓冲区满时，提取关键事件存入 Event Chain，生成角色反思，并归档原始日志。

8. **Batch Processor Shuttle (新增)**:
    * **职责**: 负责处理 **批量、非实时** 的重型维护任务。
    * **场景**: 导入外部长篇聊天记录、对历史记忆进行大规模重构或重新总结。
    * **动作**: 在独立的后台 `MaintenancePipeline` 中运行，分块读取历史，模拟 AI “阅读”并批量提交更新。

9. **Schema Injector Plugin**:
    * **职责**: 管理协议 Schema 的动态注入。
    * **动作**: 扫描角色卡配置和动态协议标签 (`<use_protocol>`)，加载对应的 YAML Schema，并将其 `instruction` 和 `examples` 合并到 Skein 中。

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
2. **History Chain**: 标准的对话历史记录 (Linear Chat History)。
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

1. **扫描**: Jacquard 扫描当前角色卡配置 + 活跃的动态协议列表。
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

1. **Prompt 组装**: Skein Builder 使用 Filament 格式组装 System Prompt、Character Card、World State 等内容。
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
