# 技术说明文档：js-split-merged 插件架构分析

## 1. 插件概述 (Overview)

`js-split-merged`（又称 "AutoCardUpdater" 或 "神·数据库V8"）是一个运行在 SillyTavern 环境中的高级数据增强插件。

### 1.1 核心痛点与设计目的
传统的 SillyTavern 角色卡交互依赖于静态的世界书（World Info）和被动的对话历史。本插件旨在解决以下痛点：
*   **状态遗忘**: 传统的 LLM 无法长期记忆细粒度的状态（如 RPG 中的金币、物品数量、具体时间）。
*   **上下文漂移**: 随着对话进行，关键信息被挤出 Context Window。
*   **缺乏自动化**: 剧情推进往往需要用户手动修改世界书。

**设计目的**:
构建一个**自动化、持久化、结构化**的数据层。它像一个"外挂大脑"，自动分析剧情发展，将非结构化的对话文本转化为结构化的 JSON 表格数据（如状态表、任务表、背包表），并随着对话实时更新。

### 1.2 核心功能
1.  **自动化填表 (Auto-Update)**: 监听 AI 回复，触发 LLM 后台思考，自动更新数据库表格。
2.  **可视化编辑器 (Visualizer)**: 提供 Excel 风格的 UI，允许用户直接查看和修改当前状态。
3.  **剧情编排引擎 (Plot Orchestration)**: 引入 "MCTS-like" 规划机制，拦截用户输入，先生成剧情大纲（Plot）再生成正文，确保逻辑严密性。
4.  **数据隔离 (Data Isolation)**: 支持为不同角色甚至不同对话分支维护独立的数据状态，互不干扰。

---

## 2. 核心架构与工作原理 (Architecture & Mechanism)

### 2.1 宏观架构：寄生与共生

本插件采用**寄生式架构 (Parasitic Architecture)**。它没有独立的后端服务，完全运行在用户的浏览器端，依赖 `SillyTavern` 暴露的全局对象（如 `SillyTavern_API`）进行交互。

```mermaid
graph TD
    User((用户))
    subgraph Host [SillyTavern 宿主环境]
        EventBus[事件总线]
        ChatHistory[聊天记录]
        DOM[界面元素]
    end
    
    subgraph Plugin [js-split-merged 插件]
        Controller[核心控制器]
        Memory[内存状态 (JSON)]
        Visualizer[可视化编辑器]
        Planner[剧情规划器]
        Updater[数据更新器]
    end
    
    User --> DOM
    DOM --> EventBus
    EventBus -- "GENERATION_ENDED" --> Controller
    Controller --> Updater
    Updater -- "Read/Write" --> ChatHistory
    Controller --> Visualizer
    Visualizer -- "Render" --> DOM
    
    User -- "Input" --> Planner
    Planner -- "Intercept & Inject" --> Host
```

### 2.2 核心生命周期 (Core Lifecycle)

插件的生命周期紧随 SillyTavern 的页面加载与对话流程：

1.  **初始化 (Initialization)**:
    *   **Hook 注入**: 启动时，插件会 Monkey-patch（动态替换）SillyTavern 的核心函数 `TavernHelper.generate`，以便拦截用户输入。
    *   **事件监听**: 订阅 `CHAT_CHANGED` (切换聊天)、`GENERATION_ENDED` (生成结束) 等关键事件。
    *   **状态恢复**: 每次切换聊天时，插件会扫描当前聊天记录，寻找**最近一次**保存的有效数据快照，并加载到内存中。

2.  **交互循环 (Interaction Loop)**:
    *   **用户输入**: 被规划器拦截，生成剧情大纲。
    *   **AI 生成**: 携带大纲的 Prompt 发送给 LLM，生成回复。
    *   **被动更新**: 收到回复后，更新器分析内容，在后台调用 LLM 更新表格数据。
    *   **状态回写**: 新的表格数据被打包，静默附加到最新的消息对象上。

### 2.3 数据持久化与隔离 (Data Persistence & Isolation)

这是本插件最独特的设计——**基于消息元数据的"时间旅行"式存储**。

*   **存储位置**: 数据并不保存在独立的 `.json` 文件或数据库中，而是作为 **Metadata (元数据)** 附加在 Chat History 的每条消息对象中（具体字段为 `TavernDB_ACU_IsolatedData`）。
*   **快照机制**: 每一轮对话更新后，都会生成一份当前世界的**全量快照 (Snapshot)** 并保存到该轮消息中。
*   **分支友好 (Branching Friendly)**: 
    *   当你回退（Swipe/Delete）到旧消息并重新生成时，插件会读取旧消息上的旧快照。
    *   这意味着数据状态会自动"回滚"到那个时刻，完美支持 RPG 的 S/L (Save/Load) 大法。

**隔离策略**:
插件通过 `Isolation Key` 实现数据隔离。不同的角色卡、甚至同一角色的不同独立世界线（通过 Tag 区分），其数据存储在不同的命名空间下，互不污染。

### 2.4 可视化编辑器架构 (Visualizer Architecture)

编辑器采用 **SDUI (Server-Driven UI)** 的前端变体思想。

*   **Schema 驱动**: UI 不是硬编码的，而是根据内存中的 JSON 数据结构动态生成的。
*   **双向绑定**:
    *   **Render**: JSON -> HTML。
    *   **Update**: DOM Input 事件 -> 更新内存 JSON -> 触发保存逻辑。
*   **独立性**: 编辑器的 UI 渲染逻辑 (`visualizer-render.js`) 与数据处理逻辑解耦，支持不同的数据 Schema（如状态表、背包表、任务表）。

### 2.5 剧情编排引擎 (Plot Orchestration Engine)

为了解决 LLM "写着写着就崩了"的问题，插件引入了 **MCTS-like (蒙特卡洛树搜索变体)** 的规划机制。

**工作流程**:
1.  **拦截 (Intercept)**: 用户点击发送时，请求被暂停。
2.  **思考 (Thought)**: 插件构建一个特殊的 Prompt，要求 LLM **不生成正文**，而是生成 `<thought>` (思考) 和 `<plot>` (剧情大纲)。
3.  **反思 (Reflection)**: (可选) 插件可以检查生成的 Plot 是否符合约束（如字数限制、必须包含的关键词）。如果不符合，自动触发重试。
4.  **执行 (Execution)**: 只有当 Plot 满意后，才会将其作为 `[System Directive]` 注入到原始 Prompt 中，放行给 SillyTavern 进行正文生成。

### 2.6 提示词工程 (Prompt Engineering)

插件采用了**动态上下文注入 (Dynamic Context Injection)** 技术。

*   **Late Binding (晚期绑定)**: 提示词不是静态的。在发送给 LLM 的最后一毫秒，插件会扫描当前的内存数据（表格状态）和世界书。
*   **占位符机制**:
    *   `$1`: 动态插入世界书内容。
    *   `$5`: 动态插入"总体大纲表"。
    *   `$0`: 动态插入"当前所有表格数据"（用于更新任务）。
*   这种机制确保了 LLM 永远看到的是最新的、最准确的状态，而不是过期的幻觉。

---
*文档生成时间: 2025-12-28*
