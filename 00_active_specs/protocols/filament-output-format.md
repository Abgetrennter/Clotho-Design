# 输出格式：XML+JSON (Output Format: XML+JSON)

**版本**: 2.3.0  
**日期**: 2025-12-28  
**状态**: Draft  
**作者**: 资深系统架构师 (Architect Mode)  
**关联文档**:

- 概述 [`filament-protocol-overview.md`](filament-protocol-overview.md)
- 输入格式 [`filament-input-format.md`](filament-input-format.md)
- 解析流程 [`filament-parsing-workflow.md`](filament-parsing-workflow.md)

---

## 概述 (Introduction)

LLM 的所有输出必须包裹在特定的 Filament 标签中，确保机器可解析。v2.1 版本引入了更多语义化标签以支持复杂交互。输出端遵循 **"XML + JSON"** 格式：XML 标签定义意图，JSON 描述具体参数。

## Core 标签（始终可用）

Core 仅包含两个标签，**所有角色卡默认支持**，无需声明：

### `<think>` - 思维链

用于推理、规划与自我反思。

```xml
<think>
用户询问了关于森林的危险性。我需要：
1. 回忆森林中的主要威胁
2. 根据当前时间（午夜）调整危险程度
3. 考虑用户的装备水平
4. 提供建议而非直接命令
</think>
```

**特性**:
- 此内容默认对用户隐藏，或折叠显示
- 可通过用户设置切换为完全隐藏或完全显示
- 不计入最终输出 Token

### `<content>` - 最终回复

直接展示给用户的对话内容。

```xml
<content>
　　「在这片黑暗森林中，你要特别小心。」
<!-- consider: (角色对白模拟插入) -->
</content>
```

**特性**:
- 直接展示在聊天界面
- 支持 Markdown 格式
- **支持 HTML 注释**: 允许嵌入 `<!-- ... -->` 格式的注释，用于内部模拟
- **支持受限的行内 HTML**: 特定白名单标签（见下方）

### 受限 HTML 白名单 (HTML Sanitization Whitelist)

为了安全起见，Clotho 仅允许以下 HTML 标签和属性：

| 标签 | 允许属性 | 用途 |
|------|----------|------|
| `<span>` | `style` (仅限 color, background-color, font-weight 等安全样式) | 文本高亮、改色 |
| `<br>` | 无 | 换行 |
| `<b>`, `<strong>`, `<i>`, `<em>`, `<u>`, `<s>` | 无 | 基础排版 |
| `<ruby>` | 无 | 注音 |

**安全机制**:
- 前端渲染器（Flutter `HtmlWidget` 或 WebView）必须集成 Sanitize 模块（如 `DOMPurify`）。
- 任何不在白名单中的标签（如 `<script>`, `<iframe>`, `onclick`）将被剥离或转义。

## Extension 标签（需显式启用）

> **重要**: 以下标签**不属于 Core**。角色卡必须在 `configuration.protocols` 中显式启用对应的 Extension，Parser 才会识别这些标签。未启用的 Extension 标签将被视为普通文本。

### `<variable_update>` - 变量更新 (Extension: `variable_update`)

**启用方式**:
```yaml
configuration:
  protocols:
    - variable_update
```

**描述**: 状态变更指令，支持 JSON OpCode 格式。

**注意**: 如果未启用 `variable_update` Extension，LLM 输出的 `<variable_update>` 标签将被视为普通文本，**不会**触发状态更新。

```xml
<variable_update>
  <analysis>
    - 角色对白模拟插入
    - 嫉妒乐奈受到的"特别待遇"，对源的执念更深
  </analysis>
  [
    [SET, 纯田真奈.好感度, 2],       <!-- v2.4 简化格式 (Bare Word) -->
    [ADD, mood.value, 1],
    [SET, desc, "She is angry"]     <!-- 含空格字符串仍需引号 -->
  ]
</variable_update>
```

**结构**:

1. `<analysis>` (可选): 文本形式的分析，解释为何进行这些状态变更。
2. `JSON Array` (必填): 执行状态变更的操作码列表。支持 **Bare Word OpCode** (省略不必要的引号)。

**操作码 (OpCode) 定义**:

| OpCode | 含义 | 参数示例 | 说明 |
|--------|------|----------|------|
| `SET` | 设置值 | `[SET, path, value]` | 覆盖指定路径的值 |
| `ADD` | 加法 | `[ADD, path, number]` | 数值相加 |
| `SUB` | 减法 | `[SUB, path, number]` | 数值相减 |
| `MUL` | 乘法 | `[MUL, path, number]` | 数值相乘 |
| `DIV` | 除法 | `[DIV, path, number]` | 数值相除 |
| `PUSH` | 追加到数组 | `[PUSH, array_path, value]` | 向数组末尾添加元素 |
| `POP` | 弹出数组 | `[POP, array_path]` | 移除数组末尾元素 |
| `DELETE` | 删除字段 | `[DELETE, path]` | 删除指定路径的字段 |

### 语义化操作标签 (Semantic Operation Tags) - v2.3

引入 ERA 风格的语义化标签作为 OpCode 的高级封装，提供更直观的意图表达。

- **`<variable_insert>`**: 非破坏性插入，支持模板应用。

    ```xml
    <variable_insert>
      <path>player.inventory.potion</path>
      <value>{ name: "Potion", count: 1 }</value>
    </variable_insert>
    ```

- **`<variable_edit>`**: 破坏性更新，支持权限校验与表达式。

    ```xml
    <variable_edit>
      <path>player.hp</path>
      <value>-= 20</value> <!-- 支持数学表达式 -->
    </variable_edit>
    ```

- **`<variable_delete>`**: 删除节点，支持删除保护。

    ```xml
    <variable_delete>
      <path>player.inventory.empty_bottle</path>
    </variable_delete>
    ```

### `<tool_call>` - 工具调用

请求执行特定的工具或函数。

```xml
<tool_call name="weather_forecast">
{
  "location": "Ancient Ruins",
  "days": 3,
  "units": "celsius"
}
</tool_call>
```

### `<tool_call>` - 工具调用 (Extension: `tool_call`)

**启用方式**:
```yaml
configuration:
  protocols:
    - tool_call
```

请求执行特定的工具或函数。

```xml
<tool_call name="weather_forecast">
{
  "location": "Ancient Ruins",
  "days": 3,
  "units": "celsius"
}
</tool_call>
```

---

## 表现与交互标签 (Presentation & Interaction)

### `<status_bar>` - 自定义状态栏 (Extension: `status_bar`)

**启用方式**:
```yaml
configuration:
  protocols:
    - status_bar
```

用于显示轻量级的、非标准化的状态信息。

```xml
<status_bar>
  <SFW>safe</SFW>
  <mood>anxious</mood>
  <location>Dark Forest</location>
</status_bar>
```

### `<details>` - 折叠摘要 (Extension: `details`)

**启用方式**:
```yaml
configuration:
  protocols:
    - details
```

兼容 HTML `<details>` 标签，用于输出折叠的辅助信息或摘要。

```xml
<details>
  <summary>摘要</summary>
  用户询问了森林的危险性...
</details>
```

### `<choice>` - 选择菜单 (Extension: `choice`)

**启用方式**:
```yaml
configuration:
  protocols:
    - choice  # 标准选择菜单
    # 或
    - options_format  # 九选项覆盖格式
```

用于向用户提供明确的行动选项。

```xml
<choice>
  <prompt>请选择下一步行动：</prompt>
  <options>
    <option id="investigate">调查废墟</option>
    <option id="rest">休息恢复</option>
  </options>
</choice>
```

### `<ui_component>` - 嵌入式前端 (Extension: `ui_component`)

**启用方式**:
```yaml
configuration:
  protocols:
    - ui_component
```

允许 LLM 请求渲染复杂的原生嵌入式 UI 组件。

```xml
<ui_component view="widget.inventory_grid">
{
  "filter": "magical_items",
  "columns": 3
}
</ui_component>
```

### `<media>` - 媒体资源 (Extension: `media`)

**启用方式**:
```yaml
configuration:
  protocols:
    - media
```

请求插入图片、音频、视频等媒体资源。

```xml
<media type="image" src="assets/forest_night.jpg" alt="黑暗森林的夜景" />
```

## 标签使用规范

### 标签闭合要求

- **严格闭合**: 所有标签必须严格闭合，禁止自闭合标签（`<media>` 除外，如果 Parser 支持）。
- **JSON 格式**: `<variable_update>` 和 `<ui_component>` 内部的 JSON 必须严格符合标准（双引号、无尾随逗号）。
- **注释规范**: 在 `<content>` 中使用 `<!-- -->` 进行内部标记，不要将用户不可见的内容裸露在正文中。

### 迁移指南

对于从 SillyTavern 或旧系统迁移的内容：

- **变量更新**: 将 `<UpdateVariable>` 映射为 `<variable_update>`。
- **选择菜单**: 将 `<xx>` 或纯文本选项映射为 `<choice>`。
- **状态栏**: 将 HTML 状态栏映射为 `<status_bar>` 或 `<ui_component>`。

### UI 组件设计规范

1. **view 命名**: 使用 `namespace.component` 格式。
2. **降级策略**: 关键交互组件应提供文本降级方案，以防 UI 渲染失败。

## 相关阅读

- **[解析流程](filament-parsing-workflow.md)**: 了解这些标签如何被实时解析和分发
- **[输入格式](filament-input-format.md)**: 回顾输入端的 XML+YAML 结构
- **[架构索引](../README.md)**: 查看标签在系统核心架构中的应用

---

**最后更新**: 2025-12-28  
**维护者**: Clotho 协议团队
