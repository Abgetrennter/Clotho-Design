# `js-split-merged` 插件核心原理分析草稿 (内部)

## 1. 核心架构概述

该插件本质上是一个运行在 SillyTavern 宿主环境中的 **"数据增强与自动化编排层"**。它并不通过后端 API 修改数据库，而是利用 JS 脚本对前端状态（SillyTavern 的 DOM 和内存变量）进行拦截和操控，从而实现数据的持久化、可视化和自动化。

### 核心设计哲学
*   **寄生式架构**: 依赖 `SillyTavern_API_ACU` 等宿主提供的全局对象。
*   **混合存储**:
    *   **持久化数据 (Source of Truth)**: 并非独立的数据库文件，而是**分散隐藏在 Chat History 的消息对象**中（Metadata）。
    *   **内存缓存**: `currentJsonTableData_ACU` 作为运行时状态。
    *   **临时存储**: LocalStorage/IndexedDB 用于配置和导入缓冲。
*   **双重循环驱动**:
    *   **UI 事件驱动**: `GENERATION_ENDED`, `MESSAGE_UPDATED` 触发数据的被动更新。
    *   **主动时钟驱动**: `plot/loop.js` 维护一个独立的时钟，主动触发 LLM 进行"剧情规划"。

## 2. 关键子系统梳理

### 2.1 数据隔离与持久化 (Isolation & Persistence)
*   **隔离机制**: 核心在于 `TavernDB_ACU_IsolatedData` 字段。
    *   每个角色卡、甚至每个对话（通过标签）拥有独立的数据命名空间。
    *   **Fallback**: 若无隔离标签，则使用默认的 legacy 结构，保证兼容性。
*   **"时间旅行"般的读写**:
    *   写入：数据作为 metadata 附加在**当前最新的 AI 消息**上。
    *   读取：回溯 Chat History，查找**离当前最近**的一次有效数据快照。
    *   这实现了**分支(Branching)友好**：切回旧消息分支，数据会自动"回滚"，因为读取的是那个时间点附近的快照。

### 2.2 剧情编排引擎 (Plot Orchestration)
*   这是一个 **MCTS-like (蒙特卡洛树搜索变体)** 的实现。
*   **流程**:
    1.  **Hook 拦截**: `TavernHelper.generate` 被 monkey-patch，拦截用户输入。
    2.  **规划 (Planning)**:
        *   不直接生成回复。
        *   先调用 LLM (Silent Call) 生成 `<thought>` 和 `<plot>`。
        *   **自我反思 (Self-Reflection)**: 检查回复长度、幻觉等，失败则重试。
    3.  **注入 (Injection)**:
        *   将规划好的 Plot 作为 `[System Directive]` 注入到最终发给酒馆的 Prompt 中。
        *   **动态提示词**: 使用 `$1`, `$5` 等占位符，实时拉取当前表格状态和世界书。

### 2.3 可视化编辑器 (Visualizer)
*   **SDUI (Server-Driven UI) 的前端变体**:
    *   数据结构 (`template.js`) 定义了 UI 渲染逻辑。
    *   `renderVisualizerDataMode` 和 `renderVisualizerConfigMode` 动态生成 HTML。
*   **状态同步**:
    *   DOM `input` 事件 -> 更新内存 `_acuVisState` -> 更新 `currentJsonTableData_ACU` -> 触发保存逻辑。

### 2.4 自动化更新流水线 (Auto-Update Pipeline)
*   **触发**: 消息生成结束 / 手动点击。
*   **批处理**: 将需要更新的表格分批（Batch）处理，避免 Context Window 溢出。
*   **Prompt 组装 (`input-prep.js`)**:
    *   **Before**: 读取旧表数据。
    *   **Context**: 截取最近 N 轮对话。
    *   **Instruction**: 注入 `template.js` 中定义的 `updateNode` (更新逻辑)。
*   **执行**: 调用 LLM 生成 `insertRow` / `updateRow` 指令。
*   **回写**: 解析指令，更新内存对象，并 attach 到消息上。

## 3. 图表构思

### 3.1 数据流向图 (Data Flow)
```mermaid
graph TD
    UserInput[用户输入] --> Hook[TavernHelper Hook]
    Hook -- 拦截 --> Planner[剧情规划器]
    Planner -- 调用 LLM --> Plot[剧情大纲]
    Plot -- 注入 --> Prompt[最终 Prompt]
    Prompt --> SillyTavern[酒馆生成核心]
    SillyTavern --> AI_Reply[AI 回复]
    AI_Reply -- 触发事件 --> Updater[自动更新器]
    
    Updater -- 读取 --> ChatHistory[聊天记录 (History)]
    ChatHistory -- 恢复快照 --> Memory[内存数据 (JSON)]
    Memory -- 上下文注入 --> Updater
    Updater -- 调用 LLM (更新指令) --> NewState[新状态]
    NewState -- 附加 (Metadata) --> LatestMsg[最新消息]
    
    Memory <--> Visualizer[可视化编辑器]
```

### 3.2 存储结构图 (Storage Structure)
展示 Chat History 中消息对象如何承载数据。
`Message.TavernDB_ACU_IsolatedData[Key] -> { Tables... }`

## 4. 待解决疑问 / 需要注意的点
*   **性能瓶颈**: 每次更新都要遍历 History 查找最新快照，在大历史记录下是否有性能问题？(代码中有 `batchFoundSheets` 优化，但仍需注意)。
*   **竞态条件**: `update/processor.js` 中使用了全局锁 `isAutoUpdatingCard_ACU`，但在异步环境下（如快速连发消息）是否绝对安全？
*   **依赖脆弱性**: 强依赖 `SillyTavern_API_ACU` 和 DOM ID（如 `#send_textarea`），宿主更新可能导致插件失效。

---
*此草稿用于指导后续正式文档撰写，无需作为最终交付物。*
