# Filament Canonical Spec

**版本**: 3.0.0
**日期**: 2026-04-03
**状态**: Draft
**作者**: Clotho 协议团队
**关联文档**:

- 协议总览 [`filament-protocol-overview.md`](filament-protocol-overview.md)
- 输入侧实现说明 [`filament-input-format.md`](filament-input-format.md)
- 输出侧实现说明 [`filament-output-format.md`](filament-output-format.md)
- 解析器实现说明 [`filament-parsing-workflow.md`](filament-parsing-workflow.md)
- Schema 库规范 [`schema-library.md`](schema-library.md)
- Schema YAML 示例标准库 [`schema-yaml-standard-library/README.md`](schema-yaml-standard-library/README.md)
- Jinja2 宏系统 [`jinja2-macro-system.md`](jinja2-macro-system.md)

> 术语体系参见 [naming-convention.md](../naming-convention.md)

---

## 1. 定位与事实来源

本文档是 **Filament 协议的唯一事实来源 (SSOT)**。凡涉及以下内容，均以本文档为准：

1. 协议适用边界
2. canonical 标签名称
3. 输入/输出语法基线
4. 版本基线与兼容策略

其他文档只能：

- **引用** 本文档中的 canonical 定义
- **补充** 实现细节、工作流、测试策略和工程约束

其他文档不得再独立定义另一套标签名、语法或版本基线。

---

## 2. 适用边界

### 2.1 协议作用范围

**Filament 仅用于 Clotho 与 LLM 的边界通信。**

| 场景 | 是否使用 Filament | 说明 |
|------|------------------|------|
| Jacquard 组装 Prompt 发给 LLM | 是 | 输入端遵循 XML + YAML |
| LLM 输出返回给 Parser | 是 | 输出端遵循 XML + JSON |
| Jacquard 与 Mnemosyne 之间 | 否 | 使用 Dart 对象与接口契约 |
| Presentation 与 Jacquard 之间 | 否 | 使用 `JacquardUIAdapter` 等接口 |
| 数据库存储与持久化 | 否 | 使用 SQLite / JSON / Domain Object |

### 2.2 版本分层

为避免“协议版本”和“解析器能力版本”混淆，采用双版本体系：

| 名称 | 当前基线 | 作用 |
|------|----------|------|
| **Filament Spec** | `3.0.0` | 对外协议定义 |
| **ESR Engine** | `2.5.x` | Parser 的结构约束与容错引擎 |

`ESR Engine` 可以演进，但不得改变 `Filament Spec 3.x` 的 canonical 标签与语法含义。

---

## 3. 设计原则

### 3.1 非对称交互

- **输入端**: `XML + YAML`
- **输出端**: `XML + JSON`

### 3.2 文本与机器动作分离

Filament 将标签分成两类：

| 类型 | Body 格式 | 典型标签 |
|------|-----------|----------|
| **文本标签** | 纯文本 / Markdown | `<thought>`, `<content>` |
| **结构化标签** | 严格 JSON | `<state_update>`, `<tool_call>`, `<choice>` |

### 3.3 兼容性不等于双规范

历史标签只允许作为 **兼容别名** 存在，不再作为规范正文的一部分重复定义。

---

## 4. 版本基线与兼容策略

## 4.1 Canonical 基线

从本文档起，Clotho 的协议基线统一为：

- **Filament Spec 3.0.0**
- **Canonical Tags Only**
- **Structured Tags Use Strict JSON**

### 4.2 Legacy 兼容范围

运行时允许 `compat` 模式兼容以下历史标签：

| Legacy 标签 | Canonical 标签 | 兼容状态 |
|-------------|----------------|----------|
| `<think>` | `<thought>` | 兼容 |
| `<reply>` | `<content>` | 兼容 |
| `<variable_update>` | `<state_update>` | 兼容 |

### 4.3 运行模式

| 模式 | 用途 | 行为 |
|------|------|------|
| `strict` | 文档、测试、CI、Schema 校验 | 非 canonical 标签直接报错 |
| `compat` | 运行时生产环境 | 先做 alias 归一化，再进入正式解析 |

**要求**:

- 文档示例必须使用 `strict` 语法
- 测试基线必须使用 `strict` 语法
- Parser 可以在运行时支持 `compat`

---

## 5. Canonical 输入模型

### 5.1 输入封套

在 `strict` 模式下，Filament 输入必须使用统一封套：

```xml
<filament_input version="3.0">
  ...
</filament_input>
```

### 5.2 输入块规则

输入端的块名用于表达 Prompt 的语义边界，但**不属于输出解析的 core tag 集**。推荐使用下列保留块名：

| 标签 | 用途 | Body 格式 |
|------|------|-----------|
| `<system_instruction>` | 系统规则与约束 | YAML |
| `<persona>` | 角色或用户设定投影 | YAML |
| `<world_state>` | 当前世界状态 | YAML |
| `<lorebook_entry>` | 世界书条目 | YAML 或纯文本 |
| `<conversation_history>` | 历史对话 | YAML 或纯文本 |
| `<use_protocol>` | 动态启用协议 | 纯文本 |

### 5.3 YAML 规则

输入侧 YAML 必须遵循以下约束：

1. UTF-8 编码
2. 统一 2 空格缩进
3. 禁止 Tab
4. 每个 XML 块内部仅承载一个 YAML 文档
5. 非必要时不要将 JSON 再嵌入 YAML 字符串

### 5.4 输入示例

```xml
<filament_input version="3.0">
  <system_instruction>
role: Dungeon Master
tone: dark_fantasy
rules:
  - strict_physics
  - permadeath
  </system_instruction>

  <persona>
name: Seraphina
class: Mage
traits:
  - cautious
  - proud
  </persona>

  <world_state>
location: Ancient Ruins
time: Midnight
weather: Stormy
  </world_state>

  <use_protocol>state_update</use_protocol>
</filament_input>
```

---

## 6. Canonical 输出模型

### 6.1 输出封套

在 `strict` 模式下，Filament 输出必须使用统一封套：

```xml
<filament_output version="3.0">
  ...
</filament_output>
```

### 6.2 Core Tags

Core 永远启用，无需显式声明。

| 标签 | 类型 | Body 格式 | 说明 |
|------|------|-----------|------|
| `<thought>` | Core | 文本 / Markdown | 内部思维链，默认不直接展示 |
| `<content>` | Core | 文本 / Markdown | 用户可见正文 |

### 6.3 Extension Tags

Extension 只有在对应协议启用后才合法。

| 标签 | 类型 | Body 格式 | 说明 |
|------|------|-----------|------|
| `<state_update>` | Extension | JSON | 状态变更、工具外部副作用的结构化提交 |
| `<tool_call>` | Extension | JSON | 请求执行外部工具 |
| `<ui_component>` | Extension | JSON | 请求渲染复杂组件 |
| `<choice>` | Extension | JSON | 交互选项 |
| `<status_bar>` | Extension | JSON | 轻量状态展示 |
| `<details>` | Extension | JSON | 折叠信息 |
| `<media>` | Extension | JSON | 媒体资源引用 |

### 6.4 输出示例

```xml
<filament_output version="3.0">
  <thought>
用户切换到找猫支线，应调整当前目标并保持语气自然。
  </thought>

  <state_update>
{
  "ops": [
    { "op": "replace", "path": "/planner/active_quest_id", "value": "quest_find_cat" },
    { "op": "replace", "path": "/planner/current_goal", "value": "help_find_cat" }
  ],
  "analysis": "用户当前意图从约会切换为支线求助。"
}
  </state_update>

  <content>
我们先去帮那位老奶奶找猫，等事情解决后再回来继续原来的安排。
  </content>
</filament_output>
```

---

## 7. Structured Tag JSON Schemas

### 7.1 `<state_update>`

`<state_update>` 的 JSON body 必须符合：

```json
{
  "ops": [
    { "op": "replace", "path": "/character/mood", "value": "happy" }
  ],
  "analysis": "可选，人类可读分析"
}
```

约束：

1. `ops` 为必填数组
2. `op` 采用 JSON Patch 动词：`add`, `remove`, `replace`, `move`, `copy`, `test`
3. `path` 使用 JSON Pointer 格式，如 `/character/hp`
4. 禁止 Bare Word 指令
5. 禁止在 JSON body 内嵌 XML 子标签或 XML 注释

### 7.2 `<tool_call>`

```json
{
  "name": "weather_forecast",
  "args": {
    "location": "Ancient Ruins",
    "days": 3
  }
}
```

### 7.3 `<ui_component>`

```json
{
  "view": "widget.inventory_grid",
  "props": {
    "filter": "magical_items",
    "columns": 3
  },
  "fallback": "请显示魔法物品列表。"
}
```

### 7.4 `<choice>`

```json
{
  "prompt": "请选择下一步行动：",
  "options": [
    { "id": "investigate", "label": "调查废墟" },
    { "id": "rest", "label": "休息恢复" }
  ]
}
```

### 7.5 `<status_bar>`

```json
{
  "items": [
    { "id": "mood", "label": "情绪", "value": "anxious" },
    { "id": "location", "label": "位置", "value": "Dark Forest" }
  ]
}
```

### 7.6 `<details>`

```json
{
  "summary": "摘要",
  "content": "用户询问了森林的危险性与夜间行动建议。"
}
```

### 7.7 `<media>`

```json
{
  "type": "image",
  "src": "assets/forest_night.jpg",
  "alt": "黑暗森林的夜景"
}
```

---

## 8. 语法与安全约束

### 8.1 XML 约束

1. 所有标签必须闭合
2. 标签名必须使用 canonical 名称
3. `strict` 模式下必须存在 `filament_input` / `filament_output` 根封套
4. 不允许未声明的顶层 structured tag

### 8.2 JSON 约束

1. 必须是严格 JSON
2. 必须使用双引号
3. 禁止尾随逗号
4. 禁止 Bare Word opcode
5. 禁止 XML 注释混入 structured body

### 8.3 文本标签约束

- `<thought>` 与 `<content>` 允许纯文本和 Markdown
- `<content>` 允许受限 HTML 白名单，具体渲染规则由 [filament-output-format.md](filament-output-format.md) 补充

---

## 9. Parser 一致性要求

### 9.1 ESR 注册要求

`expected_structure_registry` 中的 `expected_tags` 必须使用 canonical tag 名称：

```json
{
  "expected_tags": ["thought", "content", "state_update", "choice"]
}
```

### 9.2 Alias 归一化

在 `compat` 模式下，Parser 的归一化顺序必须是：

1. 识别 legacy 标签
2. 映射到 canonical 标签
3. 再执行 ESR 校验与路由

禁止在 ESR 内长期维护两套并行标签集。

---

## 10. 迁移策略

### 10.1 文档迁移

所有文档、示例、表格、测试夹具统一迁移到：

- `<thought>`
- `<content>`
- `<state_update>`

### 10.2 Prompt 与 Parser 迁移

| 旧写法 | 新写法 |
|--------|--------|
| `<think>` | `<thought>` |
| `<reply>` | `<content>` |
| `<variable_update>` | `<state_update>` |
| `[SET, path, value]` | `{ "op": "replace", "path": "/...", "value": ... }` |

### 10.3 迁移期要求

- 运行时允许兼容旧标签
- 新增文档与测试不得再出现旧标签
- 新增 Schema 不得再定义 legacy `root_tag`

---

## 11. 一致性要求

以下文档必须引用本文档，而不是重复定义 canonical 语法：

- [`filament-protocol-overview.md`](filament-protocol-overview.md)
- [`filament-input-format.md`](filament-input-format.md)
- [`filament-output-format.md`](filament-output-format.md)
- [`filament-parsing-workflow.md`](filament-parsing-workflow.md)
- [`schema-library.md`](schema-library.md)
- [`../jacquard/schema-injector.md`](../jacquard/schema-injector.md)
- [`../reference/testing-strategy.md`](../reference/testing-strategy.md)

---

**最后更新**: 2026-04-03
**维护者**: Clotho 协议团队
