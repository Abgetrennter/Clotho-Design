# LittleWhiteBox (小白X) 集成方案

## 1. 执行摘要 (Executive Summary)

本文件详述了将 "LittleWhiteBox" (LWB) 插件的核心特性与设计模式适配到我们项目架构中的策略。经过深度分析，我们发现 LWB 在事件驱动架构、变量管理（守护者机制）、以及安全的 UI 渲染方面展现出了成熟的工程实践。这些特性与我们的 `Mnemosyne` (数据引擎)、`Jacquard` (编排引擎) 和 `The Stage` (展现层) 的发展目标高度契合。

我们的目标**不是直接复制代码**，而是**提炼并适配其设计模式**，以增强我们架构的健壮性，特别是数据模式验证、事件调度系统和安全内容渲染机制。

## 2. 功能映射与分析 (Feature Mapping)

下表展示了 LWB 的关键特性如何映射到我们的子系统中，以及适配的复杂度评估。

| LWB 特性 | LWB 实现机制 | 目标子系统 | 适配策略 | 复杂度 |
| :--- | :--- | :--- | :--- | :--- |
| **Guardian (守护者)** | `variables-core.js`: 通过 `guardValidate` 和 `rulesGetTable` 进行运行时拦截 | **Mnemosyne** | 在数据定义层实现 `VariableSchema`，支持正则、范围、类型等约束，而非外挂式拦截。 | 中 |
| **Plot-Log (剧情日志)** | `variables-core.js`: `<plot-log>` 标签解析与原子操作 | **Mnemosyne / Filament** | 扩展 `Filament` 协议以支持原子操作（`SET`, `PUSH`, `BUMP`, `DEL`）和层级路径寻址。 | 高 |
| **Snapshots (快照)** | `variables-core.js`: 基于消息ID的 `setSnapshot` 和回滚机制 | **Mnemosyne** | 实现与消息ID强绑定的 `StateSnapshot` 机制，支持对话回溯和分支管理。 | 中 |
| **Scheduled Tasks (定时任务)** | `scheduled-tasks.js`: 支持间隔（楼层计数）与事件触发 | **Jacquard** | 扩展 `Planner` 组件，支持 `RecurrentTask` (循环任务) 和 `EventTask` (事件任务)。 | 高 |
| **Story Outline (剧情大纲)** | `story-outline.js`: 维护 `outlineData` 并动态注入 Prompt | **Muse** | 在 Muse 中实现 `WorldContextProvider`，负责将世界状态动态构建为 System Prompt。 | 中 |
| **Iframe Renderer** | `iframe-renderer.js`: 使用 Blob URL 和 `postMessage` | **The Stage** | 采纳 **Blob URL** 模式用于沙箱化渲染“工件” (Artifacts) 和交互式组件。 | 低 |
| **Secure Bridge (安全桥)** | `bridges/*.js`: `call-generate` 服务 | **Muse / The Stage** | 实现强类型的 IPC 桥接协议，允许 UI 组件通过 Muse 安全请求 LLM 生成。 | 中 |

## 3. 详细适配策略 (Detailed Adaptation Strategy)

### 3.1. Mnemosyne 集成 (数据与变量)

**现状**: Mnemosyne 负责数据存储，但目前缺乏细粒度的数据模式验证（Schema Validation）和针对对话日志的原子操作记录能力。

**适配方案**:

1.  **数据模式验证层 ("Guardian" 的原生化)**:
    *   **设计**: 不再使用独立的 "Guardian" 模块，而是将验证逻辑内以此 `Mnemosyne` 的 `Asset` 或 `Variable` 定义中。
    *   **Schema 定义**:
        *   `constraints` (约束): 支持 `min/max` (数值范围), `regex` (正则匹配), `enum` (枚举值), `length` (字符串/数组长度)。
        *   **Policies (策略)**:
            *   `readOnly`: 禁止修改。
            *   `arrayPolicy`: `grow` (允许增长), `fixed` (固定长度), `set` (仅允许修改现有元素)。
            *   `objectPolicy`: `extend` (允许新增键), `strict` (仅允许修改预定义键)。
    *   **实现**: 在数据写入操作（Write Operation）前引入 `SchemaValidator` 中间件。

2.  **Filament 协议增强**:
    *   **背景**: LWB 的 `<plot-log>` 实际上是一种事务日志。我们需要让 `Filament` 协议原生支持这种日志格式。
    *   **路径寻址**: 支持 LWB 风格的深层路径寻址，例如 `characters[0].inventory.gold` 或 `world.weather.current`。
    *   **原子操作**:
        *   `SET`: 设置值（覆盖）。
        *   `PUSH`: 向数组追加元素。
        *   `BUMP`: 数值增减 (即 `INC`/`DEC`)。
        *   `DEL`: 删除键或数组元素。
    *   **解析**: 增强 Filament 解析器以识别并提取这些原子操作指令。

3.  **状态快照 (State Snapshots)**:
    *   **机制**: 为了支持对话的“撤销/重做”以及用户滑动（Swipe）导致的分支切换，Mnemosyne 必须捕获状态快照。
    *   **关联**: 每个 `MessageID` 关联一个 `SnapshotID`。
    *   **存储**: 采用增量存储（Delta Storage）或关键帧全量存储（Keyframe Storage）以优化空间。

### 3.2. Jacquard 集成 (编排与任务)

**现状**: Jacquard 拥有基于意图的 `Planner`，但缺乏基于规则的显式调度能力。

**适配方案**:

1.  **任务调度器 (Scheduler)**:
    *   **间隔逻辑**: 采纳 LWB 的精细化间隔控制：
        *   `UserFloor`: 仅在用户发送消息后计数。
        *   `ModelFloor`: 仅在模型回复后计数。
        *   `TotalFloor`: 所有消息均计数。
    *   **事件触发**: 实现 `EventTrigger` 机制，支持以下标准事件：
        *   `OnChatCreated`: 新对话开始。
        *   `OnChatLoaded`: 对话加载。
        *   `OnMessageReceived`: 收到消息（可过滤发送者）。
        *   `OnVariableChanged`: 特定变量发生变化。

2.  **逻辑执行安全**:
    *   LWB 允许执行沙箱化 JS。对于 V1 版本，为了安全性，我们将限制为执行 **预定义的 Jacquard Action** 或 **Slash Commands**。
    *   **Action 定义**: 定义标准的 `JacquardAction` 类型，例如 `UpdateVariable`, `TriggerAgent`, `ShowNotification`。

### 3.3. Presentation (The Stage) 集成 (展现层)

**现状**: The Stage 可以渲染 UI，但需要一种安全的方式来渲染动态内容（如工件、小游戏、状态栏）。

**适配方案**:

1.  **沙箱化渲染 (Sandboxed Rendering)**:
    *   **核心技术**: 严格采纳 `URL.createObjectURL(blob)` 模式创建 iframe。
    *   **优势**: Blob URL 使得 iframe 的源（Origin）为 `blob://...`，或者是 opaque origin，这天然禁止了对父窗口 DOM、Cookie 和 LocalStorage 的直接访问，提供了极高的安全性。
    *   **实现**: 创建 `ArtifactRenderer` 组件，负责将 HTML/JS 内容转换为 Blob 并注入 iframe。

2.  **安全桥接 (Secure Bridge)**:
    *   **需求**: iframe 内的内容可能需要请求 LLM 生成（例如：根据当前剧情生成新闻）。
    *   **协议**: 定义严格的 IPC (进程间通信) 桥接协议：
        *   `UI -> postMessage -> Bridge -> Muse (Agent) -> Bridge -> postMessage -> UI`
    *   **鉴权**: Bridge 必须验证请求来源，并对请求的 Prompt 进行审查或限制 Token 消耗。

### 3.4. Muse 集成 (上下文与智能)

**现状**: Muse 负责生成 Prompt。

**适配方案**:

1.  **世界上下文提供者 (World Context Provider)**:
    *   **概念**: LWB 的 `formatOutlinePrompt` 是一个典型的“上下文提供者”。
    *   **实现**: 在 Muse 中构建模块化的 `WorldContextProvider`。
    *   **功能**:
        *   读取 Mnemosyne 中的世界状态（当前地点、周边 NPC、环境描述）。
        *   应用模板引擎（如 Jinja2 或我们的宏系统）。
        *   动态生成 Markdown 格式的 System Prompt 片段。
        *   支持根据 Token 限制自动摘要或截断。

2.  **世界模拟 (World Simulation)**:
    *   **后台代理**: LWB 的“世界推演”步骤应被封装为一个 Muse 的 **后台代理 (Background Agent)**。
    *   **触发**: 该代理不直接参与对话生成，而是在后台运行（例如每 N 个回合，或当玩家“睡眠”时），更新 Mnemosyne 中的世界状态数据。

## 4. 实施路线图 (Implementation Roadmap)

### 第一阶段：基石构建 (Mnemosyne & Filament)
1.  [ ] **设计**: 在 `mnemosyne` 目录下编写 `schema-validation.md` 规范文档，定义 `VariableSchema` 结构。
2.  [ ] **开发**: 升级 `Filament` 解析器，支持 `<plot-log>` 风格的原子变量操作解析。
3.  [ ] **开发**: 在 Mnemosyne 存储层实现 `StateSnapshot` 机制，支持基于 MessageID 的状态回滚。

### 第二阶段：编排能力 (Jacquard)
4.  [ ] **设计**: 扩展 `jacquard/planner-component.md`，加入 `Scheduler` (调度器) 规范。
5.  [ ] **开发**: 实现支持间隔计数（Interval）和事件订阅（Event Bus）的任务调度器。
6.  [ ] **集成**: 将调度器与 Filament 操作结合，使任务可以触发变量变更。

### 第三阶段：展现与交互 (Presentation & Muse)
7.  [ ] **开发**: 在 The Stage 中实现基于 `Blob URL` 的 `IframeRenderer` 组件。
8.  [ ] **开发**: 定义并实现 `UI-Muse IPC Bridge`，确保 iframe 与主进程的安全通信。
9.  [ ] **开发**: 创建 Muse 的 `WorldContextProvider`，实现从数据到 Prompt 的动态转换。

## 5. 结论

对 LittleWhiteBox 的深度分析证实了我们架构方向的正确性，同时为我们提供了极具价值的实现细节参考。特别是 **Schema Validation (守护者)** 和 **Blob URL Sandbox (沙箱渲染)** 这两个模式，将被直接采纳并原生集成到我们的核心架构中。通过这种适配，我们不仅能获得 LWB 的强大功能，还能保持架构的模块化和安全性，避免了“插件地狱”带来的维护负担。
