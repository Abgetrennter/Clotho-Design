# ACU 插件集成与架构启示 (ACU Integration Insights)

**版本**: 1.0.0
**日期**: 2026-01-03
**状态**: Draft
**背景**: 对比 ACU 插件（基于浏览器 JS 的实现）与 Clotho 架构（Jacquard/Mnemosyne），提取有价值的模式。

---

## 1. 核心总结 (Executive Summary)

本文档旨在从现有的 "Auto Card Updater" (ACU) 插件中提炼架构经验，以增强 "Clotho" 系统。Clotho 虽然拥有更先进的原生架构（Jacquard 流水线、Mnemosyne 数据引擎），但 ACU 在处理 **长线数据维护**、**记忆一致性** 和 **错误恢复** 方面积累了大量经过实战检验的模式。

我们的目标是将 ACU 的“智能层”逻辑适配到 Clotho 的“编排层”和“数据层”中，同时保持 Clotho 架构的整洁性。

---

## 2. 流水线架构：批处理与异步 (Batching & Asynchrony)

### 2.1 ACU 的模式：显式批处理
ACU 采用严格的线性流水线 (`Trigger -> Index Collection -> Batching -> Execution`)。它最关键的设计是将大量需要处理的消息（例如导入的长聊天记录）切分为小的 **批次 (Batches)**（例如每批 2 条消息），并增量更新状态。
*   **快速失败 (Fail-Fast)**: 如果 Batch N 失败，流程立即停止，防止错误累积导致数据污染。
*   **微型合并 (Mini-Merge)**: 每个批次在处理前，都会先加载该批次起始点**之前**的最新状态，确保因果关系正确。

### 2.2 Clotho 的缺口
Jacquard 目前主要是为了 **请求-响应 (Request-Response)** 模式设计的 (`Pre-Flash -> Invoker -> Parser`)。它擅长实时交互，但缺乏一种明确的模式来处理：
*   导入历史记录时的回填 (Backfilling)。
*   延迟执行的后台任务（例如：每隔 50 轮对最近剧情进行总结）。

### 2.3 集成建议
**在 Jacquard 中引入 `BatchProcessorShuttle` 和 `AsyncWorker`。**

1.  **异步编排 (Async Orchestration)**:
    *   创建一个专门用于后台维护的 Jacquard Pipeline。
    *   该 Pipeline 由 Mnemosyne 的 `PostFlash` 触发，但在主 UI 线程之外独立运行。
2.  **状态回溯 (State Rehydration)**:
    *   借鉴 ACU 的“微型合并”概念。在处理历史批次时，Mnemosyne 必须支持 `projectionAt(timePointer)`，能够精准提供**那个时间点**的上下文，而不是只提供当前的最新状态。

```mermaid
graph TD
    subgraph ACU_Batching [ACU 批处理模式]
        B1[Batch 1: Load State T0 -> Update] -->|State T1| B2[Batch 2: Load State T1 -> Update]
        B2 -->|State T2| B3[Batch 3: Load State T2 -> Update]
    end

    subgraph Clotho_Adaptation [Clotho 适配方案]
        PostFlash[Post-Flash Worker] -->|Queue Task| JobQueue
        JobQueue -->|Pick Job| BatchShuttle[Batch Processor Shuttle]
        BatchShuttle -->|1. Rehydrate (T)| Mnemosyne
        BatchShuttle -->|2. Process| LLM
        BatchShuttle -->|3. Commit Delta| Mnemosyne
    end
```

---

## 3. 记忆结构：层级链接 (AMxx)

### 3.1 ACU 的模式：强链接
ACU 维护了两张核心叙事表：
*   **总结表 (Summary Table)**: 详细记录每几轮发生的具体对话。
*   **大纲表 (Outline Table)**: 高度概括的故事主线。
*   **链接机制**: 它使用显式的 `AMxx` (Auto Merge ID) 索引，强制将具体的总结条目“挂载”到某一个大纲条目下。这使得 AI 在回忆时，可以从模糊的大纲“下钻”到精确的细节，有效减少幻觉。

### 3.2 Clotho 的缺口
Mnemosyne 虽然有 `History Chain` (详细) 和 `Event Chain` (宏观/事件驱动)，但两者之间的关联通常是隐式的（基于时间戳），缺乏显式的强引用。

### 3.3 集成建议
**增强 Event Chain，支持显式 Ref-ID。**

1.  **Schema 更新**:
    在 `Global Event` 的 Schema 中增加 `linked_logs` 或 `ref_ids` 字段。
    ```json
    {
      "event_id": "evt_climax_01",
      "summary": "击败了暗影狼。",
      "linked_logs": ["log_turn_105", "log_turn_106"] // 显式链接到具体的原始日志
    }
    ```
2.  **检索逻辑**:
    当 RAG 检索到一个 "Global Event" 时，如果上下文需要高精度细节，系统可以顺着 `linked_logs` 抓取原始记录，完美复刻 ACU 的鲁棒性。

---

## 4. 智能交互：递归规划循环 ($6)

### 4.1 ACU 的模式：短期记忆链
ACU 会将**上一轮**生成的剧情规划（Plan），注入到**当前轮**的 Prompt 中（作为 `$6` 占位符）。
*   **作用**: 这创造了一个跨越轮次的“思维链”。AI 能“记得”它上一步打算做什么，即使玩家突然打断说了一句无关的话（比如“看那只猫”），AI 也不会丢失原本“揭露叛徒”的计划。

### 4.2 Clotho 的缺口
Jacquard 的 `Pre-Flash` (Planner) 目前是无状态的。它只分析**当前**的用户输入。如果用户转移话题，Pre-Flash 可能会忘记 2 轮前规划好的宏大剧情。

### 4.3 集成建议
**在 Mnemosyne 中实现 `PlannerState`。**

1.  **持久化**:
    在 Mnemosyne 的 `Session State` (L3) 中开辟一个保留槽位 `planner_context`。
2.  **反馈循环**:
    *   **Write**: 当 Pre-Flash 生成计划时（例如：“目标：3轮内揭露叛徒”），将其写入 `planner_context`。
    *   **Read**: 在下一轮，将 `planner_context` 作为输入注入到 Pre-Flash 的 Skein 中。
    *   **Update**: Pre-Flash 根据当前情况更新计划（例如：“目标：揭露叛徒 - 步骤1已完成”）。

---

## 5. 可靠性：美杜莎协议与自我修正 (Medusa Protocol)

### 5.1 ACU 的模式：清单校验
ACU 的 "Medusa Protocol" 强制 LLM 在输出操作指令后，紧接着输出一个 `Checklist` (校验清单)。
*   "ID 是否匹配？" [Yes]
*   "列是否对齐？" [Yes]
这种机制迫使模型在生成的最后阶段“回头看”自己的输出，或者允许第二阶段的验证器进行解析和校验。

### 5.2 Clotho 的缺口
Filament 协议依赖 `Parser` 处理流式输出。如果 LLM 生成了格式错误的 `<state_update>`（例如路径错误），Parser 可能会直接丢弃或报错，缺乏“自愈”能力。

### 5.3 集成建议
**引入 `ValidatorShuttle` 和自我修正 Prompt。**

1.  **Prompt 工程 (Skein)**:
    更新 `Filament` 的系统提示词，在 `<thought>` 块内部或在最终提交前增加一个 `<verify>` 步骤。
2.  **Shuttle 逻辑**:
    在 `Filament Parser` 之后引入 `ValidatorShuttle`。
    *   如果 `Parser` 检测到 Schema 违规 -> `ValidatorShuttle` 构造一个包含错误信息的 "Correction Prompt" -> 触发 `Invoker` 重试（Retry）。
    *   这正式化了 ACU 代码中的重试逻辑。

---

## 6. 可视化与元数据

### 6.1 ACU 的模式：Schema 驱动 UI
ACU 的可视化编辑器是完全由数据驱动的。它不硬编码“生命值”或“法力值”；JSON 里有什么表头，它就渲染什么表头。

### 6.2 Clotho 的对齐
Clotho 的 `Hybrid SDUI` 理念与此高度一致。我们需要确保 Mnemosyne 的 `$meta.template` 能直接驱动 UI 渲染，允许像 ACU 那样灵活：用户添加一个“腐化值”统计，UI 上立刻就能显示出来，无需修改代码。

---

## 7. 结论

通过集成这些 ACU 的模式，Clotho 将从一个“无状态的执行者”进化为“有状态的战略家”：

1.  **批处理** 解决了历史数据的稳健管理。
2.  **显式链接** 巩固了记忆的可靠性。
3.  **递归规划** 保证了叙事的连贯性。
4.  **自我修正** 确保了数据的完整性。

这种混合方案结合了 Clotho 的架构纯洁性与 ACU 的工程实用性。
