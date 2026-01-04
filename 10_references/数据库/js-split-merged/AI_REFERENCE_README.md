# 神·数据库 V8 (AutoCardUpdater) 代码结构与依赖说明文档

本文档旨在帮助 AI 检索和理解 `js-split-merged` 目录下的代码结构、模块依赖关系及核心功能流转。

## 1. 项目架构概览

本项目采用 **全局函数式架构**，主要特征如下：
*   **模块化文件**：功能被拆分到不同的子目录和文件中。
*   **全局作用域**：所有核心函数和变量均挂载在全局作用域（`window`）下，以后缀 `_ACU` (AutoCardUpdater) 命名，以避免命名冲突。
*   **隐式依赖**：文件之间不存在显式的 `import` 或 `require` 语句。依赖关系由运行时的加载顺序和全局变量的存在性决定。
*   **入口点**：
    *   **概念入口**: `main.js` (作为文件清单和功能概览)
    *   **执行入口**: `core/main-initialize.js` 中的 `mainInitialize_ACU()` 函数。

## 2. 核心全局变量

AI 在分析代码时，应重点关注以下全局变量，它们维持了插件的运行状态：

*   `settings_ACU`: 存储插件的所有配置项（自动更新开关、API设置、绘图设置等）。
*   `SillyTavern_API_ACU`: 提供了对 SillyTavern 主程序的接口访问（聊天记录、事件监听等）。
*   `TavernHelper_API_ACU`: 提供了辅助功能（获取 Lorebook、触发 Slash 命令等）。
*   `popupInstance_ACU`: 当前打开的设置面板/可视化编辑器的 jQuery 对象实例。
*   `currentJsonTableData_ACU`: 当前聊天上下文中加载的数据库核心数据对象（JSON格式）。
*   `loopState_ACU`: 剧情推进循环的状态管理对象。
*   `SCRIPT_ID_PREFIX_ACU`: 插件的唯一标识符前缀（通常为 `shujuku_v80`）。

## 3. 目录结构与功能模块

### 3.1 Core (核心层)
负责插件的初始化、配置加载、API 桥接和基础工具。

| 文件 | 描述 | 关键依赖/被依赖 |
| :--- | :--- | :--- |
| `main-initialize.js` | **核心启动文件**。注册菜单、绑定 SillyTavern 事件 (CHAT_CHANGED, GENERATION_ENDED)。 | 依赖 `api-loader.js`, `settings-loader.js` |
| `api-loader.js` | 负责加载和校验 SillyTavern 及 TavernHelper 的 API。 | 被 `main-initialize.js` 调用 |
| `config.js` | 定义全局常量 (ID, 前缀, 默认模板, 默认设置)。 | 被所有模块引用 |
| `utils.js` | 通用工具函数 (正则转义, 文本处理)。 | 被多个模块引用 |
| `storage.js` | 封装 localStorage 和 IndexedDB 操作。 | 被 `settings-loader.js`, `import` 模块引用 |

### 3.2 Chat & Data (数据处理层)
负责聊天记录读取、数据清洗、合并和格式化。

| 文件 | 描述 | 关键依赖/被依赖 |
| :--- | :--- | :--- |
| `chat/loader.js` | `loadAllChatMessages_ACU`。从 ST 获取完整聊天记录。 | 被 `core`, `data-merge` 引用 |
| `data/data-merge.js` | `refreshMergedDataAndNotify_ACU`。核心逻辑：合并分散在聊天记录中的 JSON 数据块。 | 依赖 `chat/loader.js` |
| `data/format.js` | JSON 与人类可读文本 (Readable Format) 的相互转换。 | 被 `update`, `worldbook` 引用 |
| `data/isolation.js` | 数据隔离逻辑，处理不同世界线/分支的数据存取。 | 被 `data-merge`, `update` 引用 |
| `data/initialization.js` | 检查并初始化新聊天的数据库结构。 | 被 `main-initialize.js` 引用 |

### 3.3 Update & AI (更新与智能层)
负责调用 AI 进行数据更新、剧情推进和自动填表。

| 文件 | 描述 | 关键依赖/被依赖 |
| :--- | :--- | :--- |
| `update/processor.js` | `processUpdates_ACU`。处理数据更新的核心流程控制。 | 依赖 `ai/api-call.js` |
| `update/auto-update-trigger.js` | 判断是否触发自动更新 (Token 阈值/轮次检测)。 | 被 `main-initialize.js` 引用 |
| `ai/api-call.js` | `callCustomOpenAI_ACU`。封装对 LLM 的 API 请求。 | 依赖 `api/api-config.js` |
| `ai/input-prep.js` | 准备发送给 AI 的 Prompt (包含当前数据、聊天记录、更新指令)。 | 被 `update/processor.js` 引用 |
| `plot/optimization.js` | `runOptimizationLogic_ACU`。剧情推进/逻辑优化的核心算法。 | 被 `main-initialize.js` 引用 |

### 3.4 Visualizer & UI (界面交互层)
负责可视化编辑器、设置面板和弹窗交互。

| 文件 | 描述 | 关键依赖/被依赖 |
| :--- | :--- | :--- |
| `visualizer/visualizer-main.js` | 可视化编辑器的主入口和布局渲染。 | 依赖 `visualizer-render.js` |
| `visualizer/visualizer-render.js` | 渲染具体的表格数据和配置界面。 | 被 `visualizer-main.js` 引用 |
| `ui/popup-html.js` | 生成设置面板的 HTML 结构。 | 被 `core/main-initialize.js` 引用 |
| `ui/popup-events.js` | 绑定设置面板内的所有交互事件。 | 依赖 `settings`, `export` 等模块 |

### 3.5 Worldbook (世界书集成层)
负责将数据库内容同步到 SillyTavern 的世界书 (World Info) 系统。

| 文件 | 描述 | 关键依赖/被依赖 |
| :--- | :--- | :--- |
| `worldbook/worldbook-updater.js` | 将表格数据转换为世界书条目 (Entries)。 | 被 `data-merge` 引用 |
| `worldbook/worldbook.js` | 管理世界书的创建、读取和清理。 | 被 `worldbook-updater.js` 引用 |

## 4. 关键功能流转 (AI 检索指引)

### 场景 A: 自动更新流程是如何触发的？
1.  **监听**: `core/main-initialize.js` 监听 `GENERATION_ENDED` 事件。
2.  **判断**: 调用 `update/auto-update-trigger.js` -> `triggerAutomaticUpdateIfNeeded_ACU()`。
3.  **执行**: 若满足条件，调用 `update/processor.js` -> `processUpdates_ACU()`。
4.  **AI交互**: 准备 Prompt (`ai/input-prep.js`) -> 调用 API (`ai/api-call.js`) -> 解析结果 (`table/table-edit.js`)。
5.  **保存**: 写入聊天记录 (`data/isolation.js` -> `saveIndependentTableToChatHistory_ACU`)。

### 场景 B: 可视化编辑器是如何加载数据的？
1.  **入口**: 用户点击按钮 -> `visualizer/visualizer-main.js` -> `openNewVisualizer_ACU()`。
2.  **数据源**: 读取全局变量 `currentJsonTableData_ACU` (由 `data/data-merge.js` 维护)。
3.  **渲染**: 调用 `visualizer/visualizer-render.js` 生成 DOM。
4.  **保存**: 用户点击保存 -> `visualizer/visualizer-save.js` -> `saveVisualizerChanges_ACU()` -> 更新全局数据并写回历史。

### 场景 C: 剧情推进 (Plot) 是如何工作的？
1.  **拦截**: `core/main-initialize.js` 拦截用户发送 (`TavernHelper.generate` hook 或 `GENERATION_AFTER_COMMANDS`)。
2.  **规划**: 调用 `plot/optimization.js` -> `runOptimizationLogic_ACU()`。
3.  **循环**: 若开启循环模式，状态由 `loopState_ACU` 管理，逻辑在 `plot/loop.js`。

## 6. 详细数据处理流程

为了帮助 AI 更好地理解数据如何在系统中流转，以下是核心数据处理流程的详细说明：

### 6.1 数据流转总览

系统采用 "分散存储，动态合并" 的策略。数据并不存储在一个单一的 JSON 文件中，而是分散存储在每条聊天记录的 `TavernDB_ACU_IsolatedData` 字段中。

```mermaid
graph TD
    A[聊天记录 (SillyTavern Chat History)] -->|1. 加载 & 遍历| B(data/data-merge.js<br>mergeAllIndependentTables_ACU)
    B -->|2. 合并最新数据| C{内存对象<br>currentJsonTableData_ACU}
    C -->|3a. 触发更新| D[update/processor.js<br>processUpdates_ACU]
    D -->|4. 调用 AI| E[AI API]
    E -->|5. 解析结果| F[table/table-edit.js]
    F -->|6. 保存回聊天记录| G[data/isolation.js<br>saveIndependentTableToChatHistory_ACU]
    C -->|3b. 同步世界书| H[worldbook/worldbook-updater.js<br>updateReadableLorebookEntry_ACU]
    H -->|7. 生成/更新条目| I[SillyTavern World Info]
```

### 6.2 关键环节详解

1.  **加载与合并 (`data/data-merge.js`)**:
    *   `loadAllChatMessages_ACU()`: 获取当前上下文的所有消息。
    *   `mergeAllIndependentTables_ACU()`: 倒序遍历聊天记录。对于每个表格（Sheet），找到其最后一次出现的版本（基于 `TavernDB_ACU_IsolatedData` 或旧版兼容字段）。
    *   **结果**: 生成一个包含所有表格最新状态的完整 JSON 对象 `currentJsonTableData_ACU`。

2.  **触发更新 (`update/processor.js`)**:
    *   `processUpdates_ACU()`: 接收需要更新的消息索引列表。
    *   **批处理**: 将更新任务分批（Batch），每批单独处理。
    *   **上下文构建**: 为每一批次构建仅包含该批次增量内容的 Prompt，但会基于"当前批次之前的最新数据库状态"作为基底。

3.  **保存数据 (`data/isolation.js`)**:
    *   `saveIndependentTableToChatHistory_ACU()`: 将更新后的表格数据写入到目标消息（通常是 AI 回复的楼层）的隐藏字段中。
    *   **数据隔离**: 根据 `settings_ACU.dataIsolationCode`，数据被存储在独立的隔离槽中，互不干扰（支持多时间线/分支）。

4.  **同步世界书 (`worldbook/worldbook-updater.js`)**:
    *   `updateReadableLorebookEntry_ACU()`: 将 JSON 数据格式化为 Markdown 表格。
    *   **注入**: 创建或更新 World Info 条目（如 `TavernDB-ACU-ReadableDataTable`），供 AI 在后续对话中读取。
    *   **Wrapper**: 自动维护 `WrapperStart` 和 `WrapperEnd` 条目，确保数据在 Prompt 中的优先级。

## 7. 开发注意事项

*   **函数命名**: 新增函数必须添加 `_ACU` 后缀。
*   **jQuery 使用**: 统一使用 `jQuery_API_ACU` 而非 `$`，以确保在不同加载环境下的兼容性。
*   **Toast 通知**: 使用 `showToastr_ACU` 进行用户提示。
*   **日志**: 使用 `logDebug_ACU`, `logWarn_ACU`, `logError_ACU` 封装函数，受 `DEBUG_MODE_ACU` 控制。
