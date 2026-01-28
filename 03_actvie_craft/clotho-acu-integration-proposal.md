# Clotho 架构演进：ACU (js-split-merged) 经验吸取与融合方案

**版本**: 1.2.0 (Revised)
**日期**: 2026-01-04
**状态**: Proposal
**目标**: 将 ACU 插件中经过实战验证的"长线叙事稳定性"与"自动化维护"模式，融入 Clotho 的原生架构中。

---

## 1. 核心理念：融合 ACU 的叙事智能

经过对 `js-split-merged` (ACU) 插件的深度分析，并结合 Clotho 现有的 **Git-like 稀疏快照机制**，我们确认 Clotho 在底层状态回溯性能上已具备显著优势。因此，本方案聚焦于 **叙事逻辑的显式化** 和 **维护流程的场景化区分**。

我们从 ACU 中提炼出三个可以直接增强 Clotho 的设计模式：

1. **显式叙事链接 (Explicit Narrative Linking)**: 解决 RAG 检索"有大概无细节"的问题。
2. **递归规划链 (Recursive Planning Chain)**: 解决长对话中"目标遗忘"的问题。
3. **场景化批处理 (Contextual Batch Processing)**: 明确区分"实时整理"与"历史回填"的边界。

---

## 2. 数据层演进 (Mnemosyne Evolution)

### 2.1 显式叙事链接 (Explicit Narrative Linking)

ACU 使用 `AMxx` (Auto-Merge ID) 强制将"详细日志"挂载到"大纲"下。Clotho 目前拥有独立的 `Event Chain` 和 `History Chain`，但两者之间的关联主要依赖时间戳投影。

**融合方案**: 增强 `GlobalEvent` Schema，建立强引用。

* **改进**: 在 Mnemosyne 的 Event Schema 中增加 `source_refs` 字段。

    ```json
    // Event Chain Entry (Mnemosyne)
    {
      "event_id": "evt_defeat_wolf",
      "summary": "击败了暗影狼，获得了核心。",
      "timestamp": 170000000,
      // 显式引用原始对话日志的 ID，类似 ACU 的 AMxx
      // 这允许系统在检索到该事件时，精确"下钻"到当时的原始对话
      "source_refs": ["msg_turn_105", "msg_turn_106"]
    }
    ```

* **价值**:
  * **RAG 精度提升**: 当 RAG 检索到一个 Event 时，系统可以顺着 `source_refs` 抓取原始对话片段，提供比 Summary 更鲜活的细节（例如具体的咒语、NPC 的原话）。
  * **证据溯源**: 在 UI 上展示 "记忆" 时，用户可以点击 "查看详情" 直接跳转到生成该记忆的那一段原始对话。

---

## 3. 编排层演进 (Jacquard Evolution)

### 3.1 递归规划上下文 (Recursive Planner Context)

ACU 将上一轮的 Plan 注入到下一轮的 `$6` 占位符，形成"短期目标记忆"。Clotho 的 `Pre-Flash` 目前主要处理当前的 Intent，缺乏跨轮次的连续性。

**融合方案**: 在 `Session State` (L3) 中开辟专用规划槽位。

1. **持久化**: 在 L3 Session State 中增加 `planner_context` 节点。

    ```json
    // L3 Session State
    "planner_context": {
      "current_goal": "探索低语森林深处",
      "pending_subtasks": ["寻找水源", "设立营地"],
      "last_thought": "玩家似乎对那个发光的蘑菇感兴趣，下一轮引导他去查看。"
    }
    ```

2. **读写循环**:
    * **Read**: Jacquard 启动时，自动将 `planner_context` 注入到 `Pre-Flash` (或 Main LLM) 的 Prompt 中。
    * **Write**: `Pre-Flash` 或 Main LLM 运行后，不仅输出当前的回复，还更新 `planner_context` 的内容，写入 Mnemosyne。
3. **价值**: 即使玩家突然打断 ("等一下，我要看背包")，`current_goal` 依然保留在 L3 State 中，AI 不会忘记原本的主线任务，增强了"地牢主 (DM)"式的控场能力。

### 3.2 批处理的场景化定位 (Contextual Batch Processing)

**现状分析**:
Clotho 的 `Post-Flash` 机制确实会在每次对话（或 Buffer 满）后触发，负责近实时的记忆整理。这对于正常的聊天流程是足够的。

**为什么还需要批处理 (Batch Processing)?**
ACU 的 `update/processor.js` 不仅服务于实时更新，更关键的是它处理**大规模非实时场景**。这在 Clotho 中同样存在，且无法被 `Post-Flash` 替代：

1. **历史导入 (History Import)**: 当用户导入一个包含 1000 条消息的 SillyTavern 聊天记录时，我们不能触发 1000 次 Post-Flash。我们需要一个 `BatchShuttle` 来分块处理（例如每 50 条一个批次），快速重建状态和事件链。
2. **长线记忆重构 (Memory Refactoring)**: 当用户觉得 AI "变笨了"，或者修改了世界设定后，可能希望对过去 500 轮的记忆进行一次"重新总结"。这是一个耗时操作，必须在后台跑批。

**融合方案**: 引入 `MaintenancePipeline` 作为 `Post-Flash` 的补充。

* **Post-Flash**: 负责 **增量 (Incremental)** 整理。跟随用户聊天节奏，高频、低延迟。
* **BatchPipeline**: 负责 **全量/批量 (Bulk)** 整理。由用户主动触发或系统闲时触发，低频、高吞吐。

---

## 4. 表现层演进 (Presentation Evolution)

### 4.1 Schema 驱动的 "Inspector"

ACU 的 Visualizer 是完全由数据定义的。Clotho 目前主要依赖原生组件。

**融合方案**: 增强 Hybrid SDUI 的 Web 轨道。

* **改进**: 允许 `Mnemosyne` 的状态树节点定义 `$meta.ui_schema`。
* **实现**:
  * 当用户打开 "Inspector" (控制台) 查看某个变量（如 `inventory`）时。
  * UI 层检查 `$meta.ui_schema`。
  * 如果有定义（例如定义了表格列宽、排序规则、图标），则通过 WebView 加载一个通用的 "Table Renderer" 组件，并传入数据。
  * 如果没有，则回退到默认的 JSON Tree 视图。
* **价值**: 复刻 ACU 的灵活性，让用户/创作者可以自定义数据的展示方式，而无需修改客户端代码。

---

## 5. 总结：融合架构图

```mermaid
graph TD
    subgraph Presentation [表现层]
        ChatUI[聊天界面]
        Inspector[数据检视器 (Schema-Driven)]
    end

    subgraph Jacquard [编排层]
        Pipeline[主交互流水线]
        BatchPipeline[后台维护流水线]
        PreFlash[Pre-Flash (读取/更新 Planner Context)]
    end

    subgraph Mnemosyne [数据层]
        L3State[L3 Session State]
        History[History Chain]
        Event[Event Chain]
    end

    ChatUI --> Pipeline
    Inspector <--> L3State
    
    Pipeline --> PreFlash
    PreFlash <--> L3State
    
    Pipeline --> History
    
    %% Post-Flash 是主流水线的一部分
    Pipeline -- Async --> PostFlash[Post-Flash (增量整理)]
    PostFlash --> Event
    
    %% BatchPipeline 独立运行
    BatchPipeline -- Bulk Op --> Event
    BatchPipeline -- Bulk Op --> L3State
    
    Event -.->|source_refs| History
```

此方案厘清了 `Post-Flash` (日常) 与 `BatchPipeline` (维护) 的边界，确保 Clotho 既能流畅聊天，又能从容应对数据迁移和重构的重型任务。
