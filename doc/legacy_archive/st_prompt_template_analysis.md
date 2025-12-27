# ST-Prompt-Template 架构深度分析

## 1. 项目概览 (Project Overview)

`ST-Prompt-Template` 是一个为 SillyTavern 设计的扩展，它集成了一个强大的模板引擎 (EJS)，允许用户在聊天消息、世界书 (World Info) 和提示词 (Prompt) 中使用动态脚本。这使得创建复杂的角色行为、动态游戏机制和条件式叙事成为可能。

核心理念是将静态的文本替换为可执行的 EJS 模板，并在特定的生命周期钩子中进行评估。

## 2. 核心模块 (Core Modules)

项目代码结构清晰，主要分为以下几个逻辑模块：

*   **生命周期管理 (Lifecycle Management):** `src/index.ts`, `src/modules/handler.ts`
    *   负责扩展的初始化、事件监听和清理。
    *   作为与 SillyTavern 主程序的桥梁，拦截关键事件。
*   **模板引擎包装器 (Template Engine Wrapper):** `src/function/ejs.ts`
    *   封装了 `ejs` 库。
    *   提供 `evalTemplate` 函数，负责编译和执行模板。
    *   构建执行上下文 (`prepareContext`)，将大量工具函数和变量注入到模板作用域中。
*   **变量管理系统 (Variable Management):** `src/function/variables.ts`
    *   实现了一个分层级的变量存储系统 (Global, Local, Message, Initial)。
    *   处理变量的持久化，将其同步到 SillyTavern 的聊天元数据中。
*   **提示词注入系统 (Prompt Injection System):** `src/features/inject-prompt.ts`
    *   解析世界书条目中的特殊指令 (`@INJECT`)。
    *   实现基于位置 (`pos`)、目标 (`target`) 和正则 (`regex`) 的动态消息插入。
*   **数据访问层 (Data Access Layer):** `src/function/chat.ts`, `src/function/characters.ts`
    *   提供便捷的 API 来获取聊天历史、角色数据、头像等。

## 3. 架构与依赖分析 (Dependencies & Architecture)

### 依赖关系
*   **External:** `ejs` (模板引擎), `jquery` (DOM 操作/SillyTavern API), `lodash` (工具库).
*   **Host (SillyTavern):** 强依赖于 SillyTavern 的全局对象 (`SillyTavern.getContext()`, `eventSource`, `chat`, `characters` 等)。

### 数据流向
1.  **事件触发:** SillyTavern 触发事件 (如 `GENERATE_AFTER_COMMANDS`)。
2.  **上下文准备:** `handler` 调用 `ejs.prepareContext`，聚合当前状态 (变量、聊天记录、角色信息)。
3.  **模板执行:** `ejs.evalTemplate` 在沙箱中执行模板代码。
4.  **副作用应用:** 模板执行结果可能修改变量 (`setvar`) 或返回处理后的文本。
5.  **结果反馈:** 修改后的 Prompt 或 UI 内容返回给 SillyTavern。

## 4. 业务逻辑详解 (Business Logic)

### 4.1 动态提示词生成 (Dynamic Prompt Generation)
**文件:** `src/modules/handler.ts` -> `handleGenerateBefore`, `handleGenerateAfter`

*   **流程:**
    1.  **Before:** 在发送请求给 LLM 之前，触发 `GENERATE_AFTER_COMMANDS`。
        *   扫描所有启用的世界书条目，寻找 `@@generate_before` 装饰器。
        *   执行这些条目的内容，结果通常用于设置变量或准备环境。
    2.  **Processing:**
        *   遍历当前上下文中的聊天消息。
        *   对每条消息的内容执行 `evalTemplateHandler`，允许消息内容本身包含 EJS 代码。
        *   处理 `@@generate_before [index]` 和 `@@generate_after [index]` 装饰器的世界书，允许在特定消息前后插入内容。
    3.  **After:** 收集所有生成的 Prompt 片段，组装成最终发送给 LLM 的 Prompt。

### 4.2 动态聊天渲染 (Dynamic Chat Rendering)
**文件:** `src/modules/handler.ts` -> `handleMessageRender`

*   **目的:** 在 UI 上显示消息时，解析其中的 EJS 模板，实现动态显示 (如根据变量显示不同内容)。
*   **流程:**
    1.  监听 `MESSAGE_UPDATED`, `USER_MESSAGE_RENDERED` 等事件。
    2.  获取消息的原始文本 (`message.mes`)。
    3.  准备渲染上下文 (`runType: 'render'`).
    4.  执行 `evalTemplateHandler`。
    5.  如果开启了 `raw_message_evaluation_enabled`，可能会永久修改消息内容。
    6.  将渲染后的 HTML 更新到 DOM 中。
    7.  支持 `@@render_before` 和 `@@render_after` 钩子。

### 4.3 提示词注入 (Prompt Injection)
**文件:** `src/features/inject-prompt.ts`

*   **机制:** 利用世界书 (World Info) 作为配置载体。
*   **触发:** 在 `handleGenerateAfter` 阶段调用 `handleInjectPrompt`。
*   **解析逻辑:**
    *   过滤出评论 (Comment) 以 `@INJECT` 开头的世界书条目。
    *   支持概率触发 (`useProbability`).
    *   解析指令参数:
        *   `role`: 注入消息的角色 (system, user, assistant)。
        *   `pos=N`: 绝对位置注入。
        *   `target=role`: 相对目标角色注入 (支持 `index` 和 `at=before/after`)。
        *   `regex=pattern`: 正则匹配内容注入。
    *   **排序:** 根据计算出的最终位置 (`finalPos`) 和 `order` 参数对注入指令进行排序，确保注入顺序的确定性。
    *   **执行:** 将构造好的消息对象插入到 `data.prompt` 数组中。

### 4.4 变量管理 (Variable Management)
**文件:** `src/function/variables.ts`

*   **作用域 (Scopes):**
    *   `global`: 全局变量，跨聊天共享 (存从 `extension_settings`)。
    *   `local`: 聊天内变量，当前聊天有效 (存于 `chat_metadata`)。
    *   `message`: 消息级变量，绑定到特定消息 (`chat[i].variables`)。
    *   `initial`: 初始变量，预设值。
    *   `cache`: 运行时缓存，用于提高读取性能。
*   **API:**
    *   `getvar(key, scope?)`: 获取变量。
    *   `setvar(key, value, scope?)`: 设置变量。
    *   `incvar/decvar`: 数值增减。
    *   `precacheVariables`: 在每一轮处理开始前，从各个存储源加载变量到内存缓存 (`STATE.cacheVars`)。
    *   `clonePreviousMessage`: 在新消息生成时，继承上一条消息的变量状态 (如果需要)。

## 5. 迁移至 Flutter 的建议 (Migration Notes)

*   **Dart 对应:**
    *   需要寻找或实现一个 Dart 版的 EJS 引擎，或者使用 Dart 原生的字符串插值/模板功能 (如果是为了兼容性，可能需要嵌入 JavaScript 引擎如 `flutter_js` 或 `quickjs_dart`)。鉴于 EJS 是 JS 特有的，直接在 Dart 中运行 JS 代码可能是兼容现有 ST 扩展生态的最快路径。
    *   **变量系统:** 需要在 Dart 端复刻 `variables.ts` 的分层存储逻辑，利用本地数据库 (如 Isar, Hive) 或文件存储来持久化。
    *   **事件总线:** Flutter 应用内部需要构建类似的 Event Bus 机制来解耦业务逻辑。
    *   **正则处理:** Dart 的正则引擎与 JS 略有不同 (特别是 Lookbehind 支持)，迁移正则注入功能时需注意。
