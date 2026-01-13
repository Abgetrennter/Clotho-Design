# SillyTavern 宏定义参考文档

本文档整理了 SillyTavern 代码库中发现的所有宏定义，并按功能进行了分类。

## 目录

1.  [核心/身份宏 (Core/Identity)](#1-核心身份宏-coreidentity)
2.  [消息/对话宏 (Message/Conversation)](#2-消息对话宏-messageconversation)
3.  [时间/日期宏 (Time/Date)](#3-时间日期宏-timedate)
4.  [变量/逻辑宏 (Variables/Logic)](#4-变量逻辑宏-variableslogic)
5.  [格式化/实用工具宏 (Formatting/Utility)](#5-格式化实用工具宏-formattingutility)
6.  [扩展/系统宏 (Extension/System)](#6-扩展系统宏-extensionsystem)
7.  [指令/上下文模板宏 (Instruct/Context Template)](#7-指令上下文模板宏-instructcontext-template)
8.  [酒馆助手扩展宏 (Tavern-Helper Extension Macros)](#8-酒馆助手扩展宏-tavern-helper-extension-macros)

---

## 1. 核心/身份宏 (Core/Identity)

这些宏用于指代对话中的角色和用户，以及他们的属性。

| 宏 (Macro) | 描述 (Description) | 代码来源/逻辑 |
| :--- | :--- | :--- |
| `{{user}}` / `<USER>` | 用户名。 | `public/script.js`, `public/scripts/macros.js` |
| `{{char}}` / `<BOT>` / `<CHAR>` | 角色名。 | `public/script.js`, `public/scripts/macros.js` |
| `{{group}}` / `<GROUP>` / `<CHARIFNOTGROUP>` | 群组成员列表（逗号分隔）或单人聊天中的角色名。 | `public/script.js`, `public/scripts/macros.js` |
| `{{groupNotMuted}}` | 同 `{{group}}`，但排除静音成员。 | `public/script.js` |
| `{{notChar}}` | 除当前说话者外的所有聊天参与者列表。 | `public/script.js` |
| `{{description}}` | 角色的描述。 | `public/script.js` |
| `{{personality}}` | 角色的个性。 | `public/script.js` |
| `{{persona}}` | 用户的角色设定 (Persona) 描述。 | `public/script.js` |
| `{{scenario}}` | 角色的场景或聊天场景覆盖。 | `public/script.js` |
| `{{charVersion}}` / `{{char_version}}` | 角色的版本号。 | `public/script.js` |
| `{{charPrompt}}` | 角色的主提示词覆盖 (Main Prompt override)。 | `public/script.js` |
| `{{charJailbreak}}` / `{{charInstruction}}` | 角色的越狱/后期历史指令覆盖。 | `public/script.js` |
| `{{charDepthPrompt}}` | 角色的深度提示词 (at-depth prompt)。 | `public/script.js` |
| `{{creatorNotes}}` | 角色的作者注释。 | `public/script.js` |
| `{{model}}` | 当前生成的模型名称。 | `public/script.js` |
| `{{mesExamples}}` | 角色的对话示例（已格式化）。 | `public/script.js` |
| `{{mesExamplesRaw}}` | 角色的对话示例（原始未分割）。 | `public/script.js` |
| `{{original}}` | 原始消息内容（用于某些替换场景）。 | `public/script.js` |

## 2. 消息/对话宏 (Message/Conversation)

这些宏用于引用对话历史中的消息或属性。

| 宏 (Macro) | 描述 (Description) | 代码来源/逻辑 |
| :--- | :--- | :--- |
| `{{lastMessage}}` | 上一条聊天消息的内容。 | `public/scripts/macros.js` |
| `{{lastMessageId}}` | 上一条聊天消息的 ID。 | `public/scripts/macros.js` |
| `{{lastUserMessage}}` | 上一条用户发送的消息。 | `public/scripts/macros.js` |
| `{{lastCharMessage}}` | 上一条角色发送的消息。 | `public/scripts/macros.js` |
| `{{firstIncludedMessageId}}` | 上下文中包含的第一条消息的 ID。 | `public/scripts/macros.js` |
| `{{firstDisplayedMessageId}}` | 聊天界面显示的第一条消息的 ID。 | `public/scripts/macros.js` |
| `{{lastSwipeId}}` | 上一条消息的 Swipe 数量（1-based ID）。 | `public/scripts/macros.js` |
| `{{currentSwipeId}}` | 当前显示消息的 Swipe ID（1-based）。 | `public/scripts/macros.js` |
| `{{lastGenerationType}}` | 上一次生成的类型（"normal", "impersonate", "regenerate" 等）。 | `public/scripts/macros.js` |
| `{{input}}` | 用户输入框中的内容。 | `public/scripts/macros.js` |

## 3. 时间/日期宏 (Time/Date)

这些宏用于插入当前时间或计算时间差。

| 宏 (Macro) | 描述 (Description) | 代码来源/逻辑 |
| :--- | :--- | :--- |
| `{{time}}` | 当前系统时间 (格式: LT)。 | `public/scripts/macros.js` |
| `{{date}}` | 当前系统日期 (格式: LL)。 | `public/scripts/macros.js` |
| `{{weekday}}` | 当前星期几 (格式: dddd)。 | `public/scripts/macros.js` |
| `{{isotime}}` | 当前 ISO 时间 (格式: HH:mm)。 | `public/scripts/macros.js` |
| `{{isodate}}` | 当前 ISO 日期 (格式: YYYY-MM-DD)。 | `public/scripts/macros.js` |
| `{{datetimeformat format}}` | 按指定格式输出当前日期/时间 (moment.js 格式)。 | `public/scripts/macros.js` |
| `{{time_UTC±X}}` | 指定 UTC 偏移量的时间。 | `public/scripts/macros.js` |
| `{{idle_duration}}` | 距离上一条用户消息的时间间隔。 | `public/scripts/macros.js` |
| `{{timeDiff::time1::time2}}` | 计算两个时间点之间的差值。 | `public/scripts/macros.js` |

## 4. 变量/逻辑宏 (Variables/Logic)

这些宏用于操作和访问聊天变量，或执行简单的逻辑。

| 宏 (Macro) | 描述 (Description) | 代码来源/逻辑 |
| :--- | :--- | :--- |
| `{{getvar::name}}` | 获取局部变量 `name` 的值。 | `public/scripts/variables.js` |
| `{{setvar::name::value}}` | 设置局部变量 `name` 的值为 `value`。 | `public/scripts/variables.js` |
| `{{addvar::name::value}}` | 将 `value` 加到局部变量 `name` 上。 | `public/scripts/variables.js` |
| `{{incvar::name}}` | 局部变量 `name` 自增 1。 | `public/scripts/variables.js` |
| `{{decvar::name}}` | 局部变量 `name` 自减 1。 | `public/scripts/variables.js` |
| `{{getglobalvar::name}}` | 获取全局变量 `name` 的值。 | `public/scripts/variables.js` |
| `{{setglobalvar::name::value}}` | 设置全局变量 `name` 的值为 `value`。 | `public/scripts/variables.js` |
| `{{addglobalvar::name::value}}` | 将 `value` 加到全局变量 `name` 上。 | `public/scripts/variables.js` |
| `{{incglobalvar::name}}` | 全局变量 `name` 自增 1。 | `public/scripts/variables.js` |
| `{{decglobalvar::name}}` | 全局变量 `name` 自减 1。 | `public/scripts/variables.js` |
| `{{var_name}}` | 直接通过变量名访问变量（动态替换）。 | `public/scripts/macros.js` |

## 5. 格式化/实用工具宏 (Formatting/Utility)

这些宏提供文本格式化、随机化和其他实用功能。

| 宏 (Macro) | 描述 (Description) | 代码来源/逻辑 |
| :--- | :--- | :--- |
| `{{newline}}` | 插入一个换行符。 | `public/scripts/macros.js` |
| `{{trim}}` | 移除宏周围的换行符。 | `public/scripts/macros.js` |
| `{{noop}}` | 无操作，替换为空字符串。 | `public/scripts/macros.js` |
| `{{random:arg1,arg2,...}}` | 从逗号分隔的列表中随机选择一项。 | `public/scripts/macros.js` |
| `{{random::arg1::arg2...}}` | 从双冒号分隔的列表中随机选择一项（支持含逗号的项）。 | `public/scripts/macros.js` |
| `{{pick::arg1::arg2...}}` | 类似于 random，但在同一回复中对相同内容保持选择一致（基于 hash）。 | `public/scripts/macros.js` |
| `{{roll:formula}}` | 掷骰子 (例如 `{{roll:d20}}`)。 | `public/scripts/macros.js` |
| `{{reverse:content}}` | 反转内容字符串。 | `public/scripts/macros.js` |
| `{{banned "word"}}` | 临时禁止特定词汇（仅限 TextGen WebUI）。 | `public/scripts/macros.js` |
| `{{// comment}}` | 注释宏，内容会被移除。 | `public/scripts/macros.js` |
| `{{isMobile}}` | 返回是否为移动设备 ("true"/"false")。 | `public/scripts/macros.js` |

## 6. 扩展/系统宏 (Extension/System)

这些宏通常由扩展使用或用于特定的系统功能。

| 宏 (Macro) | 描述 (Description) | 代码来源/逻辑 |
| :--- | :--- | :--- |
| `{{outlet::name}}` | 插入指定 World Info Outlet 的内容。 | `public/scripts/macros.js` |
| `{{maxPrompt}}` | 获取当前的最大 Context Size。 | `public/scripts/macros.js` |
| `{{pipe}}` | 用于 Slash Command 管道传递结果。 | `public/scripts/slash-commands/SlashCommandParser.js` |
| `{{anchorBefore}}` | World Info/Lorebook 插入锚点（前）。 | `public/scripts/power-user.js` |
| `{{anchorAfter}}` | World Info/Lorebook 插入锚点（后）。 | `public/scripts/power-user.js` |
| `{{wiBefore}}` / `{{loreBefore}}` | World Info 插入位置（前）。 | `public/scripts/power-user.js` |
| `{{wiAfter}}` / `{{loreAfter}}` | World Info 插入位置（后）。 | `public/scripts/power-user.js` |

## 7. 指令/上下文模板宏 (Instruct/Context Template)

这些宏主要用于构建 Prompt 模板和指令模式。

| 宏 (Macro) | 描述 (Description) | 代码来源/逻辑 |
| :--- | :--- | :--- |
| `{{system}}` | 系统提示词位置。 | `public/scripts/power-user.js` |
| `{{instructSystemPrompt}}` | 指令模式系统提示词。 | `public/scripts/instruct-mode.js` (推测) |
| `{{instructUserPrefix}}` | 用户指令前缀。 | `public/scripts/instruct-mode.js` (推测) |
| `{{instructUserSuffix}}` | 用户指令后缀。 | `public/scripts/instruct-mode.js` (推测) |
| `{{instructAssistantPrefix}}` | 助手回复前缀。 | `public/scripts/instruct-mode.js` (推测) |
| `{{instructAssistantSuffix}}` | 助手回复后缀。 | `public/scripts/instruct-mode.js` (推测) |

## 8. 酒馆助手扩展宏 (Tavern-Helper Extension Macros)

这些宏由 [酒馆助手](JS-Slash-Runner-main) 扩展提供，用于增强 SillyTavern 的宏功能。

### 变量获取宏 (Variable Get Macros)

用于获取不同作用域的变量值。

| 宏 | 描述 | 代码来源 |
| :--- | :--- | :--- |
| `{{get_message_variable::变量路径}}` | 获取指定消息楼层的变量值。 | `JS-Slash-Runner-main/src/function/macro_like.ts` |
| | - 返回类型：JSON 字符串（字符串值不加引号）。 | |
| | - 示例：`{{get_message_variable::stat_data.好感度}}` | |
| `{{get_chat_variable::变量路径}}` | 获取聊天变量（同消息楼层变量）。 | `JS-Slash-Runner-main/src/function/macro_like.ts` |
| `{{get_character_variable::变量路径}}` | 获取当前角色卡绑定的变量。 | `JS-Slash-Runner-main/src/function/macro_like.ts` |
| `{{get_preset_variable::变量路径}}` | 获取当前预设绑定的变量。 | `JS-Slash-Runner-main/src/function/macro_like.ts` |
| `{{get_global_variable::变量路径}}` | 获取全局变量。 | `JS-Slash-Runner-main/src/function/macro_like.ts` |

### 变量格式化宏 (Format Variable Macros)

用于将变量值格式化为可读性更好的格式。

| 宏 | 描述 | 代码来源 |
| :--- | :--- | :--- |
| `{{format_message_variable::变量路径}}` | 将消息变量格式化为 YAML 块（带缩进）。 | `JS-Slash-Runner-main/src/function/macro_like.ts` |
| | - 示例：`{{format_message_variable::stat_data}}` | |
| `{{format_chat_variable::变量路径}}` | 将聊天变量格式化为 YAML 块。 | `JS-Slash-Runner-main/src/function/macro_like.ts` |
| `{{format_character_variable::变量路径}}` | 将角色变量格式化为 YAML 块。 | `JS-Slash-Runner-main/src/function/macro_like.ts` |
| `{{format_preset_variable::变量路径}}` | 将预设变量格式化为 YAML 块。 | `JS-Slash-Runner-main/src/function/macro_like.ts` |
| `{{format_global_variable::变量路径}}` | 将全局变量格式化为 YAML 块。 | `JS-Slash-Runner-main/src/function/macro_like.ts` |

### 其他宏 (Other Macros)

酒馆助手提供的其他内置宏。

| 宏 | 描述 | 代码来源 |
| :--- | :--- | :--- |
| `{{userAvatar}}` | 获取用户头像路径。 | `JS-Slash-Runner-main/src/macro.ts` |

### 宏注册机制 (Macro Registration)

酒馆助手允许脚本通过以下方式注册自定义宏。

| 类型 | 描述 | 代码来源 |
| :--- | :--- | :--- |
| `registerMacroLike(regex, replace)` | 注册一个新的酒馆助手宏。 | `JS-Slash-Runner-main/src/function/macro_like.ts` |
| `registerMacros()` | 注册内置宏。 | `JS-Slash-Runner-main/src/macro.ts` |
| `_registerMacroLike(this, regex, replace)` | 在脚本中注册宏（自动在页面隐藏时注销）。 | `JS-Slash-Runner-main/src/function/macro_like.ts` |
| `unregisterMacroLike(regex)` | 注销一个已注册的宏。 | `JS-Slash-Runner-main/src/function/macro_like.ts` |

### 变量类型 (Variable Types)

酒馆助手支持的变量作用域。

| 类型 | 描述 |
| :--- | :--- |
| `message` | 消息楼层变量。 |
| `chat` | 聊天界面显示的聊天记录变量。 |
| `character` | 当前角色卡绑定的变量。 |
| `preset` | 当前预设绑定的变量。 |
| `global` | 全局变量。 |
| `script` | 脚本变量。 |
| `extension` | 扩展变量。 |
