# 输出格式：XML+JSON (Output Format: XML+JSON)

**版本**: 3.0.0
**日期**: 2026-04-03
**状态**: Active
**作者**: Clotho 协议团队
**关联文档**:

- Canonical 规范 [`filament-canonical-spec.md`](filament-canonical-spec.md)
- 协议概述 [`filament-protocol-overview.md`](filament-protocol-overview.md)
- 解析器实现说明 [`filament-parsing-workflow.md`](filament-parsing-workflow.md)
- 输入侧实现说明 [`filament-input-format.md`](filament-input-format.md)

> 术语体系参见 [naming-convention.md](../naming-convention.md)

---

## 1. 文档角色

本文档不再重复维护 Filament 的 canonical 标签定义、JSON schema 和版本基线。

**输出端的唯一 canonical 定义，请参阅 [`filament-canonical-spec.md`](filament-canonical-spec.md)。**

本文档只补充：

1. 输出标签在产品中的使用约束
2. 富文本与 HTML 安全渲染规则
3. 各类 extension 的落地建议

---

## 2. 输出组织原则

在 `strict` 模式下，输出端统一使用：

```xml
<filament_output version="3.0">
  ...
</filament_output>
```

Filament 3.0 将标签分成两类：

| 类别 | 标签 | Body 形式 |
|------|------|-----------|
| 文本标签 | `<thought>`, `<content>` | 纯文本 / Markdown |
| 结构化标签 | `<state_update>`, `<tool_call>`, `<choice>`, `<ui_component>`, `<status_bar>`, `<details>`, `<media>` | 严格 JSON |

### 示例

```xml
<filament_output version="3.0">
  <thought>
用户在询问森林风险，需要先总结威胁，再给出自然化建议。
  </thought>

  <state_update>
{
  "ops": [
    { "op": "replace", "path": "/planner/current_goal", "value": "warn_about_forest" }
  ]
}
  </state_update>

  <content>
在这片黑暗森林里，夜晚比白天危险得多。
  </content>
</filament_output>
```

---

## 3. 文本标签渲染规则

### 3.1 `<thought>`

- 默认折叠或隐藏
- 允许纯文本或 Markdown
- 不应承载 JSON、XML 子标签或工具调用语义

### 3.2 `<content>`

- 直接展示给用户
- 支持 Markdown
- 允许受限 HTML 白名单

### 3.3 受限 HTML 白名单

| 标签 | 允许属性 | 用途 |
|------|----------|------|
| `<span>` | `style` 中的安全样式 | 局部高亮 |
| `<br>` | 无 | 换行 |
| `<b>`, `<strong>`, `<i>`, `<em>`, `<u>`, `<s>` | 无 | 基础排版 |
| `<ruby>` | 无 | 注音 |

### 3.4 安全要求

前端渲染器必须对 `<content>` 做统一净化：

- 剥离 `<script>`、`<iframe>`、事件处理属性
- 禁止执行任意嵌入脚本
- 对不在白名单中的标签进行转义或移除

---

## 4. Structured Tag 使用建议

### 4.1 `<state_update>`

- 仅在启用 `state_update` 扩展时允许出现
- Body 必须是严格 JSON
- 状态操作统一使用 canonical spec 中的 `ops` 结构
- 不再接受 Bare Word opcode 作为文档规范

### 4.2 `<tool_call>`

- 统一使用 `{ "name": "...", "args": { ... } }`
- 不再使用“XML 属性 + JSON body”的双语义形式

### 4.3 `<choice>`

- 建议用于“用户必须显式选项”的场景
- 如果渲染失败，应具备文本降级方案

### 4.4 `<ui_component>`

- `view` 采用 `namespace.component` 命名
- 必须提供 `fallback`

### 4.5 `<status_bar>` / `<details>` / `<media>`

- 这三类标签均视为 structured tags
- Parser 只负责提取结构，具体渲染策略由 Presentation 层决定

---

## 5. Legacy 迁移规则

从 Filament 3.0 起，文档与测试中的 canonical 标签统一为：

| 旧写法 | 新写法 |
|--------|--------|
| `<think>` | `<thought>` |
| `<reply>` | `<content>` |
| `<variable_update>` | `<state_update>` |

对于从旧系统迁移的材料：

- 运行时可通过 `compat` 模式做 alias 归一化
- 新文档、新测试、新 Schema 不得再继续使用 legacy 标签

---

## 6. 相关阅读

- [`filament-canonical-spec.md`](filament-canonical-spec.md)
- [`filament-parsing-workflow.md`](filament-parsing-workflow.md)
- [`../presentation/README.md`](../presentation/README.md)

---

**最后更新**: 2026-04-03
**维护者**: Clotho 协议团队
