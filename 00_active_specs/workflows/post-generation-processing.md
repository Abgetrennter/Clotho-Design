# 生成后处理工作流 (Post-Generation Processing Workflow)

**版本**: 1.0.0
**日期**: 2026-02-11
**状态**: Active
**关联文档**:

- 提示词处理工作流 [`prompt-processing.md`](prompt-processing.md)
- Filament 解析流程 [`../protocols/filament-parsing-workflow.md`](../protocols/filament-parsing-workflow.md)
- Schema 注入器 [`../jacquard/schema-injector.md`](../jacquard/schema-injector.md)
- Jacquard 编排层 [`../jacquard/README.md`](../jacquard/README.md)
- Mnemosyne 存储架构 [`../mnemosyne/sqlite-architecture.md`](../mnemosyne/sqlite-architecture.md)

---

## 1. 工作流概览 (Workflow Overview)

本工作流定义了从 LLM 开始输出第一个 Token，到最终将数据持久化到数据库并完成记忆整合的全过程。

如果说 **[提示词处理](prompt-processing.md)** 是 Clotho 的"吸气"（构建上下文），那么 **生成后处理** 就是 Clotho 的"呼气"（解析响应、更新状态、形成记忆）。

整个流程由 **Jacquard** 编排层监控，核心原则是：
1.  **流式响应 (Streaming First)**: 尽可能快地向用户展示内容。
2.  **原子提交 (Atomic Commit)**: 确保回合数据（消息、状态、事件）的一致性。
3.  **异步整合 (Async Consolidation)**: 繁重的记忆整理工作在后台进行，不阻塞前台。

### 1.1 核心流程图

```mermaid
graph TD
    LLM[LLM Stream] --> Parser[Filament Parser]
    
    subgraph "Phase 1: 实时解析与路由"
        Parser -->|Text Stream| UI_Buffer[UI Render Buffer]
        Parser -->|Tag Stream| Router[Tag Router]
        
        Router -->|thought| ThoughtHandler[思维处理器]
        Router -->|content| ContentHandler[内容处理器]
        Router -->|variable_update| StateHandler[状态处理器]
        Router -->|tool_call| ToolExecutor[工具执行器]
    end
    
    subgraph "Phase 2: 数据收集 (In-Memory)"
        ThoughtHandler --> Accumulator[Turn Accumulator]
        ContentHandler --> Accumulator
        StateHandler --> Accumulator
        ToolExecutor -->|Result| Accumulator
    end
    
    subgraph "Phase 3: 原子提交 (Sync)"
        Accumulator -->|Turn Completed| Transaction[DB Transaction]
        Transaction -->|Write| Tables[(Mnemosyne DB)]
        Tables --> Turns[Turns Table]
        Tables --> Msgs[Messages Table]
        Tables --> OpLogs[State OpLogs]
        Tables --> Events[Events Table]
    end
    
    subgraph "Phase 4: 异步后处理 (Async)"
        Transaction -->|Success| Consolidation[Consolidation Phase (Worker)]
        Consolidation -->|Generate| Summary[Turn Summary]
        Consolidation -->|Update| VectorDB[Vector Store]
        Consolidation -->|Check| Scheduler[Scheduler Triggers]
    end
```

---

## 2. 第一阶段：流式解析与路由 (Streaming Parsing & Routing)

**组件**: `Filament Parser Plugin` (Jacquard)

**输入**: LLM 的 Raw Token Stream。

### 2.1 容错解析状态机

解析器是一个**容错状态机 (Fault-Tolerant State Machine)**，它实时扫描流中的 `<` 符号。
- **模糊修正**: 自动补全缺失的标签头，推断未闭合的标签。
- **流式分发**: 一旦识别出标签类型，立即将内容流导向对应的 Handler，而不需要等待标签闭合。
- **动态标签注册**: 从 `JacquardContext.blackboard['parser_hints']` 读取 Schema Injector 注册的动态标签定义（如 `<live>`, `<variable_update>`）。

### 2.2 处理与渲染

| 标签类型 | Handler | 行为 | UI 表现 | 来源 |
| :--- | :--- | :--- | :--- | :--- |
| `<content>` | ContentHandler | 接收正文文本，执行 Markdown 渲染和 HTML 白名单过滤。 | **实时打字机效果** | Core Schema |
| `<thought>` | ThoughtHandler | 接收思维链文本。 | **默认折叠/隐藏** | Core Schema |
| `<variable_update>` | VariableParser | 累积 JSON 字符串，尝试增量解析。 | **不显示** (后台处理) | Extension Schema |
| `<status_bar>` | StatusBarRenderer | 解析动态标签。 | **刷新状态栏** | Extension Schema |
| `<choice>` | ChoiceRenderer | 解析选项结构。 | **显示交互按钮** | Extension Schema |
| `<ui_component>` | UIJSONParser | 解析组件参数。 | **渲染原生组件** | Extension Schema |
| `<live>` / 自定义 | DynamicHandler | 根据 `parser_hints` 动态路由 | 按 Schema 定义 | Mode/Custom Schema |

**动态标签处理**:
Schema Injector 在生成阶段前向 `blackboard['parser_hints']` 注册动态标签（如直播模式的 `<live>`）。Filament Parser 在初始化时读取这些 hints，动态扩展标签路由表。

---

## 3. 第二阶段：回合数据收集 (Turn Accumulation)

**组件**: `Turn Accumulator` (In-Memory)

在 LLM 生成的过程中，所有解析出的有价值数据都不会立即写入数据库，而是暂存在内存中的 `Turn Accumulator` 对象里。

**收集内容**:
*   **Messages List**: 
    *   `User Message` (输入)
    *   `Assistant Content` (输出正文)
    *   `Assistant Thought` (输出思维)
*   **State Deltas**: 由 `<variable_update>` 解析出的 `OpLog` 列表 (JSON Patch)。
*   **Events**: 由逻辑触发的游戏事件 (如 `item_get`, `quest_complete`)。
*   **Tool Calls**: 工具调用的请求与结果。

**状态预览 (State Preview)**:
在此阶段，内存中的 `ActiveState` 会被实时修补 (Patched)，以便 UI 组件（如HP条）能实时反映变化，但此时数据库中的数据尚未改变。

---

## 4. 第三阶段：原子提交 (Atomic Commit)

**组件**: `State Updater` (Mnemosyne)

**触发时机**: LLM 输出结束标志 (`<EOS>`) 或用户手动停止生成。

这是数据持久化的关键步骤，必须在一个**数据库事务**中完成，以保证 ACID 特性。

### 4.1 提交步骤

1.  **开启事务**: `BEGIN TRANSACTION`
2.  **创建 Turn**: 在 `turns` 表中插入新行 (`turn_index = N + 1`)。
3.  **写入消息**: 将收集到的所有消息批量写入 `messages` 表，外键关联到新 Turn。
4.  **写入 OpLogs**: 将所有状态变更日志写入 `state_oplogs` 表。
5.  **写入事件**: 将所有触发的事件写入 `events` 表。
6.  **快照检查**: 
    *   检查 `turn_index % SNAPSHOT_INTERVAL == 0`。
    *   若满足，序列化当前完整状态树，写入 `state_snapshots` 表。
7.  **更新热缓存**: 更新 `active_states` 表中的 Head State，确保下次 Session 启动速度。
8.  **提交事务**: `COMMIT`

**异常处理**: 如果写入过程中发生任何错误（如约束冲突），回滚事务 (`ROLLBACK`)，并在 UI 提示"保存失败"，状态回退到生成前。

---

## 5. 第四阶段：整合阶段 (Consolidation Phase)

**组件**: `Consolidation Worker` (Jacquard)

**触发时机**: 事务提交成功后。

此阶段的任务是**计算密集型**或**IO密集型**的，因此在后台线程执行，不阻塞用户继续输入。

### 5.1 记忆整合 (Consolidation)

1.  **生成摘要**: 调用轻量级 LLM (或复用主模型) 为当前 Turn 生成一句话摘要 (`Turn Summary`)。
2.  **更新摘要**: 将生成的摘要异步更新到 `turns` 表的 `summary` 字段。

### 5.2 向量化 (Vectorization)

1.  **Embedding**: 将 `Turn Summary` 发送给 Embedding 模型，获取向量。
2.  **存储**: 将向量写入向量数据库 (sqlite-vec)，关联 `turn_id`。

### 5.3 调度器检查 (Scheduler Check)

1.  **触发监听**: `Scheduler` 检查本回合产生的 `Events` 和 `State Changes`。
2.  **任务执行**: 如果满足条件（如 `floor > 100` 或 `hp < 20`），将相应的预设任务压入队列，可能在下一回合自动触发 Prompt 注入。

---

## 6. 异常与边界情况 (Exceptions & Corner Cases)

### 6.1 生成中断
如果用户在生成中途点击"停止"：
*   **截断**: Parser 停止解析。
*   **部分提交**: `Turn Accumulator` 中已收集到的内容（截至停止点）会被提交。
*   **标记**: 该 Turn 会被标记为 `interrupted`。

### 6.2 严重幻觉 (Severe Hallucination)
如果 LLM 输出无法解析的乱码或死循环：
*   **熔断**: Parser 检测到 Token 速率异常或格式严重错误，强制中断生成。
*   **回退**: 丢弃本次生成的 `Assistant` 部分，回滚内存中的 State Preview。
*   **重试**: 自动或提示用户重试。

---

**最后更新**: 2026-02-11
**维护者**: Clotho 架构团队