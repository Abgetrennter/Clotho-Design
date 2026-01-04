# `js-split-merged` 插件技术分析计划

为了对 `参考文件/数据库/js-split-merged` 进行深度的源码级分析并输出高质量的技术文档，我制定了以下计划：

1.  **深入代码结构分析**:
    *   **核心模块 (`core/`)**: 重点分析 `main-initialize.js`, `storage.js` (IndexedDB/LocalStorage 混合策略), `config.js` (常量配置) 的实现细节。
    *   **数据管理 (`data/`)**: 研究 `initialization.js` (首次加载逻辑), `template.js` (表结构定义), `format.js` (数据格式化) 以及 `data-merge.js` (合并策略)。
    *   **编排与交互 (`ai/`, `prompt/`)**: 分析 `ai-call-direct.js`, `input-prep.js` 如何构建 Prompt，以及 `prompt-manager.js` 如何管理提示词。
    *   **可视化编辑器 (`visualizer/`)**: 剖析 `visualizer-main.js` (UI 框架), `visualizer-state.js` (状态管理) 及 `visualizer-render.js` (动态渲染)。
    *   **外部集成 (`external/`, `import/`)**: 理解 `external-api.js` 和导入逻辑。
    *   **剧情驱动 (`plot/`)**: 分析 `plot/loop.js`, `plot/optimization.js` (MCTS-like 逻辑) 如何驱动剧情发展。

2.  **核心机制拆解**:
    *   **流水线 (Pipeline)**: 追踪从用户输入 -> 拦截 (`TavernHelper` hook) -> 规划 (Planner) -> 提示词构建 -> LLM 调用 -> 结果解析 -> 状态更新 (`update/`) 的完整链路。
    *   **存储与隔离**: 分析数据如何在 `localStorage`, `IndexedDB` 和 `Chat History` (SillyTavern 消息元数据) 之间流转与同步，特别是数据隔离机制。
    *   **可视化编辑**: 理解 DOM 操作与数据状态的双向绑定机制。

3.  **文档撰写**:
    *   基于上述分析，按照用户要求的结构（插件概述、核心架构与工作原理）撰写 Markdown 文档。
    *   重点是将代码逻辑转化为通俗易懂的原理说明，避免简单罗列代码。
    *   使用 Mermaid 图表辅助说明复杂流程（如数据流、状态机）。

4.  **最终交付**:
    *   输出一份完整的 Markdown 技术文档，保存至指定路径（例如 `doc/technical_specs/js-split-merged-analysis.md`）。

---

## 待办事项 (Todo List)

[ ] **阶段一：核心代码深度阅读**
    [ ] 分析 `core/` 目录：重点关注 `main-initialize.js` (事件钩子), `storage.js` (存储抽象)
    [ ] 分析 `data/` 目录：重点关注 `template.js` (Schema 定义), `initialization.js` (启动流程)
    [ ] 分析 `ai/` 与 `prompt/` 目录：重点关注 Prompt 组装与 LLM 交互流程
    [ ] 分析 `visualizer/` 目录：重点关注编辑器状态管理与渲染逻辑
    [ ] 分析 `plot/` 目录：重点关注剧情循环与优化算法
    [ ] 分析 `update/` 目录：重点关注数据更新与回写机制

[ ] **阶段二：架构梳理与图表绘制**
    [ ] 梳理系统整体架构图 (System Architecture Diagram)
    [ ] 梳理数据流向图 (Data Flow Diagram) - 重点是 Chat History <-> Memory <-> UI 的同步
    [ ] 梳理剧情推进流水线 (Plot Pipeline Sequence Diagram)

[ ] **阶段三：文档撰写 (Drafting)**
    [ ] 撰写 **1. 插件概述 (Overview)**: 功能定义、解决痛点
    [ ] 撰写 **2. 核心架构与工作原理 (Architecture & Mechanism)**
        [ ] **核心生命周期 (Core Lifecycle)**: 初始化、事件监听、销毁
        [ ] **数据持久化与隔离 (Data Persistence & Isolation)**: 混合存储策略
        [ ] **可视化编辑器架构 (Visualizer Architecture)**: SDUI/DOM 操作
        [ ] **剧情编排引擎 (Plot Orchestration Engine)**: 拦截、规划、执行
        [ ] **提示词工程 (Prompt Engineering)**: 动态构建、上下文注入

[ ] **阶段四：审阅与优化**
    [ ] 检查文档是否符合"通俗易懂"原则，减少直接代码引用
    [ ] 确保 Mermaid 图表清晰准确
    [ ] 最终格式调整与输出
