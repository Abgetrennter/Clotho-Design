# Schema YAML 示例标准库

**版本**: 1.0.0
**日期**: 2026-04-03
**状态**: Draft
**作者**: Clotho 协议团队
**关联文档**:

- Filament Canonical Spec [`../filament-canonical-spec.md`](../filament-canonical-spec.md)
- Schema 库规范 [`../schema-library.md`](../schema-library.md)
- Schema Injector 组件规范 [`../../jacquard/schema-injector.md`](../../jacquard/schema-injector.md)

> 术语体系参见 [../../naming-convention.md](../../naming-convention.md)

---

## 1. 定位

本文档及同目录 YAML 文件构成 **Schema YAML 示例标准库**，用于给 `data/schemas/` 提供一套可直接拷贝、可直接修改的参考起点。

它的职责是：

- 演示一套统一的 Schema YAML 字段组织方式
- 为 `core / extensions / modes / overrides` 提供最小可用样例
- 帮助 Jacquard、测试夹具和文档示例共享同一批参考文件

它**不是** Filament 协议的事实来源。标签名称、语法、版本基线仍统一以 [`../filament-canonical-spec.md`](../filament-canonical-spec.md) 为准。

---

## 2. 目录映射

本目录是设计期参考实现，结构刻意镜像运行时建议目录 `data/schemas/`：

```text
schema-yaml-standard-library/
├── core/
│   └── filament_minimal.yaml
├── extensions/
│   ├── chain_of_thought.yaml
│   ├── choice.yaml
│   ├── details.yaml
│   ├── media.yaml
│   ├── state_update.yaml
│   ├── status_bar.yaml
│   ├── tool_call.yaml
│   └── ui_component.yaml
├── modes/
│   ├── json_mode.yaml
│   ├── live_stream.yaml
│   └── text_adventure.yaml
└── overrides/
    ├── json_state_update.yaml
    └── options_format.yaml
```

建议落地时直接复制为：

```text
data/schemas/
```

---

## 3. 推荐字段模型

示例标准库统一使用以下字段约定：

| 字段 | 是否必需 | 说明 |
|------|----------|------|
| `meta` | 是 | Schema 元数据，至少包含 `id`、`version`、`schema_type`、`filament_spec` |
| `tags` | 否 | 当前 Schema 提供或约束的标签列表 |
| `injection` | 是 | 注入位置与优先级，供 Schema Injector 合并 Prompt |
| `instruction` | 是 | 注入到 Prompt 的协议说明文本 |
| `examples` | 否 | Few-shot 示例，统一使用 strict Filament 语法 |
| `parser_hints` | 否 | 提供给 Parser 的标签、格式、行为提示 |
| `requires` | 否 | 依赖的其他 Schema ID 列表 |
| `conflicts_with` | 否 | 互斥的 Schema ID 列表 |
| `replaces` | 否 | `override` 类型替换的目标 Schema ID |

### 3.1 最小模板

```yaml
meta:
  id: example_schema
  name: 示例协议
  version: 1.0.0
  schema_type: extension
  filament_spec: 3.0.0
  author: Clotho 协议团队
  description: 示例说明。

tags:
  - name: example_tag
    body_format: json
    description: 标签用途说明。

injection:
  position: system_end
  priority: 100

instruction: |
  这里编写注入到 Prompt 的规范说明。

examples:
  - name: minimal_case
    input: |
      用户输入或语义条件。
    output: |
      <example_tag>
      {
        "key": "value"
      }
      </example_tag>

parser_hints:
  root_tag: example_tag
  body_format: json
  behavior: display
```

---

## 4. 标准库目录

### 4.1 Core

| ID | 文件 | 说明 |
|----|------|------|
| `filament_minimal` | [`core/filament_minimal.yaml`](core/filament_minimal.yaml) | 默认核心协议，只定义 `<thought>` 与 `<content>` |

### 4.2 Extensions

| ID | 文件 | 说明 |
|----|------|------|
| `state_update` | [`extensions/state_update.yaml`](extensions/state_update.yaml) | 状态变更提交 |
| `choice` | [`extensions/choice.yaml`](extensions/choice.yaml) | 交互选项 |
| `status_bar` | [`extensions/status_bar.yaml`](extensions/status_bar.yaml) | 轻量状态栏 |
| `tool_call` | [`extensions/tool_call.yaml`](extensions/tool_call.yaml) | 外部工具调用 |
| `details` | [`extensions/details.yaml`](extensions/details.yaml) | 折叠补充信息 |
| `ui_component` | [`extensions/ui_component.yaml`](extensions/ui_component.yaml) | 嵌入式复杂组件 |
| `media` | [`extensions/media.yaml`](extensions/media.yaml) | 媒体资源引用 |
| `chain_of_thought` | [`extensions/chain_of_thought.yaml`](extensions/chain_of_thought.yaml) | 强化 `<thought>` 的使用纪律，不新增标签 |

### 4.3 Modes

| ID | 文件 | 说明 |
|----|------|------|
| `live_stream` | [`modes/live_stream.yaml`](modes/live_stream.yaml) | 直播口播风格 |
| `text_adventure` | [`modes/text_adventure.yaml`](modes/text_adventure.yaml) | 文字冒险叙述风格 |
| `json_mode` | [`modes/json_mode.yaml`](modes/json_mode.yaml) | Filament 内 JSON-first 输出模式，不允许退化为裸 JSON |

### 4.4 Overrides

| ID | 文件 | 说明 |
|----|------|------|
| `options_format` | [`overrides/options_format.yaml`](overrides/options_format.yaml) | 将 `<choice>` 固定为 9 选项宫格 |
| `json_state_update` | [`overrides/json_state_update.yaml`](overrides/json_state_update.yaml) | 对 `<state_update>` 施加更严格的业务字段要求 |

---

## 5. 使用建议

1. 运行时仅复制需要的 YAML 文件到 `data/schemas/`，不要把整个示例库原样视为生产配置。
2. 新增业务协议时，优先复制最相近的示例文件，再局部修改 `instruction`、`examples` 和 `parser_hints`。
3. 示例库中的所有标签和 few-shot 输出都必须保持 strict Filament 语法。
4. `json_mode` 的含义是“结构化信息优先进入 structured tags”，不是“整个输出改为 JSON-only”。

---

**最后更新**: 2026-04-03
**维护者**: Clotho 协议团队
