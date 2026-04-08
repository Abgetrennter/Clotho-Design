# LittleWhiteBox (小白X) 技术架构深度分析报告

## 1. 概述 (Overview)

LittleWhiteBox（小白X）是一个为 SillyTavern 设计的高级叙事辅助扩展，旨在通过结构化的“剧情大纲”与“世界沙盒”系统，增强 Roleplay（角色扮演）体验的连贯性与深度。其核心技术架构采用了 **动态提示词组装**、**UAUA 交互模式** 以及 **世界状态注入** 等机制，将复杂的剧情逻辑解耦为可管理的 JSON 数据流，从而实现对 LLM 输出的精确控制与上下文管理。

## 2. 动态提示词组装 (Dynamic Prompt Assembly)

核心逻辑位于 `modules/story-outline/story-outline-prompt.js`。该模块采用了一种基于 JavaScript 模板字面量（Template Literals）的动态组装策略，而非静态文本文件。

### 组装逻辑
提示词被定义为一个配置对象 `PROMPTS`，其中每个功能（如 `sms`, `worldGenStep1`, `sceneSwitch`）都包含一套完整的交互脚本（Script）。

```javascript
const DEFAULT_PROMPTS = {
    sms: {
        u1: v => `...${v.variable}...`, // 初始指令
        a1: v => `...`,                 // 模拟确认
        u2: v => `...`,                 // 实际负载
        a2: v => `...`                  // 引导输出
    },
    // ... 其他功能
};
```

### 变量注入 (`${v.variable}`)
所有提示词函数都接收一个上下文对象 `v` (vars)。
- **动态替换**：通过 JS 的模板字符串语法 `${v.variable}` 直接将运行时数据（如角色名、当前地点、历史记录数量）注入到 Prompt 中。
- **条件渲染**：利用三元运算符（如 `${v.storyOutline ? ... : ''}`）实现根据数据是否存在来动态调整 Prompt 结构，避免了空字段产生的幻觉干扰。

### 模板结构
为了保证 LLM 输出的机器可读性，系统定义了严格的 `JSON_TEMPLATES`。这些模板不仅作为 Prompt 的一部分展示给 LLM，还明确了字段的语义和类型。

## 3. UAUA 结构与预填模式 (UAUA & Prefill Pattern)

为了在复杂任务中获得高质量、遵循格式的输出，LittleWhiteBox 广泛采用了 **User-Assistant-User-Assistant (UAUA)** 的交互流设计。

### 流程解构
以 `sms`（短信生成）为例：

1.  **U1 (User)**: **设定身份与规则**。定义 LLM 的角色（如“短信模拟器”），注入世界观 (`worldInfo`)、剧情大纲 (`storyOutline`) 和历史 (`history`)，并给出 JSON 模板。
2.  **A1 (Assistant)**: **思维链确认**。模拟 Assistant 理解任务并准备执行（如 "明白，我将分析并以...身份回复..."）。这不仅加强了指令遵循，还通过思维链（CoT）暗示了处理逻辑。
3.  **U2 (User)**: **提供即时输入**。传入具体的触发事件（如“用户发来的新短信”或“当前场景信息”）。
4.  **A2 (Assistant)**: **预填引导 (Prefill)**。这是关键的一步。User 模拟 Assistant 的开头，强制规定输出格式。

### JSON 格式强制 (Prefill Enforce)
`a2` 环节通常以如下形式结束：
```javascript
a2: v => `了解，我是${v.contactName}，并以模板：${JSON_TEMPLATES.sms}生成JSON:`
// 或者
a2: () => `JSON output start:`
```
这种 **Prefill Pattern** 利用了 LLM 的补全特性。当 Prompt 以 `JSON output start:` 结尾时，LLM 极大概率会直接开始输出 `{`，从而跳过废话，直接进入 JSON 数据生成阶段。这极大提高了解析的成功率。

## 4. 世界状态集成 (World State Integration)

`modules/story-outline/story-outline.js` 负责维护和序列化世界状态，确保 LLM 始终“记得”当前的剧情背景。

### 序列化逻辑 (`formatOutlinePrompt`)
`formatOutlinePrompt` 函数是将结构化的内存数据 (`outlineData`) 转换为自然语言 Prompt 的核心转换器。它将 JSON 数据序列化为 Markdown 格式：

*   **世界真相 (Truth)**: 转换为 `> 注意：以下信息仅供生成逻辑参考...` 块。
*   **环境信息 (Environment)**: 提取当前 `playerLocation` 对应的 `outdoor` 或 `indoor` 节点描述。
*   **剧情 (Scene)**: 将 `Facade` (表现) 和 `Undercurrent` (暗流) 格式化为列表。
*   **角色 (Characters)**: 列出当前场景的联系人和陌生人。

这种 **JSON -> Markdown** 的转换使得结构化数据能以 LLM 更易理解的文本形式存在于 Context 中。

### 系统提示词注入
通过 `promptManager`（SillyTavern 的 Prompt 管理服务），LittleWhiteBox 动态注册一个 ID 为 `lwb_story_outline` 的 Prompt Item。
- **动态更新**：每当世界状态发生变更（如地点移动、NPC 生成），系统会调用 `updatePromptContent` 重新生成 Markdown 描述，并实时更新到 System Prompt 中。
- **无缝集成**：这使得剧情大纲成为“系统级”的记忆，无需用户在每次对话中手动提及。

## 5. 上下文窗口管理 (Context Window Management)

在有限的 Context Window 中，LittleWhiteBox 采取了明确的优先级策略。

### 优先级策略 (Priority Strategy)
**World State > Recent History**
在构建 Prompt（特别是 `U1` 部分）时，`worldInfo` 和 `storyOutline` 通常被放置在 `history` 之前：
```javascript
`${wrap('story_outline', v.storyOutline)}...${worldInfo}\n\n${history(v.historyCount)}`
```
这意味着 **全局设定（世界观、大纲）被视为更重要的“长期记忆”**，而对话历史被视为“短期记忆”。如果 Context 超长，尾部的历史记录更容易被截断，但核心的世界观设定得以保留。

### `{$historyN}` 截断机制
系统利用 SillyTavern 的宏 `{$historyN}` 来精确控制引入的历史消息数量。
- 在 `story-outline-prompt.js` 中定义：`const history = n => <chat_history>\n{$history${n}}\n</chat_history>;`
- 默认配置（`commSettings.historyCount`）通常为 50 条。
- 这种机制允许开发者根据任务的复杂度和 Token 消耗预期，动态调整引入的对话历史长度，防止 Prompt 溢出，同时保证 LLM 拥有足够的最近上下文来维持对话的连续性。
