# Schema 库规范 (Schema Library Specification)

**版本**: 1.1.0
**日期**: 2026-03-11
**状态**: Active
**作者**: 资深系统架构师 (Architect Mode)
**关联文档**:

- Filament 协议概述 [`filament-protocol-overview.md`](filament-protocol-overview.md)
- Jacquard 编排层 [`../jacquard/README.md`](../jacquard/README.md)
- 输入格式 [`filament-input-format.md`](filament-input-format.md)

---

## 📖 术语使用说明

本文档使用**隐喻术语**进行架构描述：

| 隐喻术语 | 技术术语 | 说明 |
|---------|---------|------|
| Character Card (角色卡) | **Persona** (角色设定) | 静态蓝图 |

在代码实现时，请使用 [`../naming-convention.md`](../naming-convention.md) 中定义的技术术语。

---

## 1. 背景与目标 (Context & Objectives)

在角色扮演（RP）和复杂交互场景中，用户经常需要定义复杂的输出格式或逻辑规则（如“好感度计算规则”、“直播间格式”）。这些规则如果直接写死在 Character Card 的 Prompt 中，会导致**复用困难**、**维护成本高**和**解析困难**。

本规范定义了一套 **Schema Library (协议库)** 机制，将这些规则从角色卡中剥离，标准化存储，并在运行时按需注入。

## 2. 核心概念：分层 Schema 架构 (Layered Schema Architecture)

为了响应“数据与规则分离”的需求，我们将 Schema 设计分为两层：

### L1: State Manipulation Protocol (状态操作层)

定义**“如何修改数据”**的基础机制。这层不包含具体业务逻辑，只定义操作指令（OpCodes）和数据结构。

*   **职责**: 提供标准化的数据变更指令集。采用 Filament v2.1/v2.4 定义的 `<variable_update>` 风格。
*   **示例**: `<variable_update>` 标签定义，支持 `[SET, path, value]`, `[ADD, path, number]` 等 Bare Word 指令。
*   **复用性**: 极高，全系统通用。

### L2: Business Rule Schema (业务规则层)

定义**“何时修改数据”**以及**“修改的限制”**。

*   **职责**: 定义具体的游戏规则、数值范围、触发条件。
*   **示例**: “好感度每次最多增加 5 点”，“战斗中受到攻击扣除 HP”。
*   **复用性**: 按场景或游戏系统复用 (e.g., "Galgame 恋爱规则", "D&D 战斗规则")。

### 层级关系

```mermaid
graph TD
    L2[L2: 业务规则 (Business Rules)] -->|生成| L1[L1: 状态操作 (State Manipulation)]
    L1 -->|执行| State[Mnemosyne State]
    
    subgraph "L2 Example: Love System"
        Rule1["规则: 赞美 +1~3 好感度"]
        Rule2["规则: 每日上限 10 点"]
    end
    
    subgraph "L1 Example: Variable Update"
        Op1["[ADD, 'favorability', 3]"]
    end
```

## 3. 存储设计 (Storage Design)

### 3.1 目录结构

建议在项目根目录下建立 `data/schemas` 目录：

```text
project_root/
├── data/
│   ├── schemas/              # Schema 库根目录
│   │   ├── core/             # 核心协议（系统内置，无需配置）
│   │   │   └── filament_minimal.yaml   # 仅包含 think, content
│   │   ├── extensions/       # 扩展协议（需显式启用）
│   │   │   ├── variable_update.yaml    # 变量更新
│   │   │   ├── choice.yaml             # 选择菜单
│   │   │   ├── status_bar.yaml         # 状态栏
│   │   │   ├── tool_call.yaml          # 工具调用
│   │   │   ├── details.yaml            # 折叠摘要
│   │   │   ├── ui_component.yaml       # 嵌入式UI
│   │   │   ├── media.yaml              # 媒体资源
│   │   │   └── chain_of_thought.yaml   # 强制思维链格式
│   │   ├── modes/            # 模式协议（全局风格，互斥）
│   │   │   ├── live_stream.yaml        # 直播模式
│   │   │   ├── text_adventure.yaml     # 文字冒险
│   │   │   └── json_mode.yaml          # JSON输出模式
│   │   └── overrides/        # 覆盖协议（替换Extension实现）
│   │       ├── options_format.yaml     # 九选项格式（覆盖choice）
│   │       └── json_variable_update.yaml # JSON变量更新格式
│   └── ...
```

### 3.2 文件格式规范 (YAML)

使用 YAML 作为存储格式，利用其多行字符串处理能力（Block Scalars `|`）。

#### 3.2.1 Schema 类型定义

**Core Schema**（系统内置，无需配置）:
```yaml
# data/schemas/core/filament_minimal.yaml
meta:
  id: "filament_minimal"
  name: "Filament 最小协议"
  version: "2.5.0"
  schema_type: "core"        # 固定值：core
  
tags:
  - name: "think"            # Core 标签 1
    category: "cognition"
  - name: "content"          # Core 标签 2
    category: "expression"
```

**Extension Schema**（需显式启用）:
```yaml
# data/schemas/extensions/variable_update.yaml

meta:
  id: "variable_update"
  name: "变量更新规则"
  version: "1.0.0"
  author: "System"
  description: "定义状态变更逻辑"
  schema_type: "extension"   # 枚举: extension | mode | override
  
# 启用后，Parser 才会识别此标签
parser_hints:
  root_tag: "variable_update"

# 注入配置
injection:
  position: "system_end"     # 注入位置
  priority: 100
  priority: 100 # 优先级，越高越靠后（越接近末尾）

# 核心指令 (Prompt)
instruction: |
  <rule>
    <description>
      - 在回复末尾，必须检查并更新相关变量。
      - 使用 <UpdateVariable> 标签包裹指令。
    </description>
    <format>
      <UpdateVariable>
        <Analysis>...</Analysis>
        _.add('path', value);
      </UpdateVariable>
    </format>
  </rule>

# 少样本示例 (Few-shot Examples)
# Jacquard 会将其格式化后追加到 Prompt 的示例区
examples:
  - input: "我送给你一朵花。"
    output: |
      谢谢你！这花真漂亮。
      <UpdateVariable>
        <Analysis>- 用户送礼，好感度上升。</Analysis>
        _.add('favorability', 5);
      </UpdateVariable>

# 解析器提示 (Parser Hints) - 可选
# 告诉 Filament Parser 如何处理这个新引入的标签
parser_hints:
  root_tag: "UpdateVariable"
  behavior: "execute_script" # ignore, display, execute_script
```

## 4. 引用机制 (Reference Mechanism)

### 4.1 角色卡静态引用 (Character Card Static Reference)

在角色卡元数据中增加 `enabled_schemas` 或 `protocols` 字段。

```yaml
# Character Card YAML
name: "高松灯"
description: "..."
configuration:
  protocols:
    - "variable_update_v1" # 引用 Schema ID
    - "live_stream_mode"   # 可以同时激活多个，但 Override 类型通常互斥
```

### 4.2 运行时动态引用 (Runtime Dynamic Reference)

支持通过 Filament 协议标签动态加载 Schema。这允许“临时进入”某种模式（例如进入战斗）。

**语法**: `<use_protocol>schema_id</use_protocol>`

**示例**:
```xml
User: 进入直播模式！
```

当 Jacquard 检测到此关键词（或通过意图识别）时，会在对话构建 Prompt 时注入对应的 Schema。

## 5. 注入与处理流程 (Injection Workflow)

### 5.1 Jacquard 组装流程

1.  **扫描**: Jacquard 扫描当前角色卡配置 + 活跃的动态协议列表。
2.  **加载**: 从 `data/schemas` 读取对应的 YAML 文件。
3.  **合并**:
    *   将 `instruction` 内容按优先级合并到 System Prompt 的 `Extension Block` 区域。
    *   将 `examples` 合并到 Few-shot Examples 区域。
4.  **注册**: 将 `parser_hints` 注册到 Filament Parser 的配置中，确保流式解析器知道如何处理新出现的标签（例如 `<live>`）。

### 5.2 冲突解决

*   如果多个 Schema 定义了相同的 `parser_hints.root_tag`，优先级高的覆盖优先级低的。
*   如果同时激活了多个 `type: override` 的 Schema，系统应发出警告或仅使用优先级最高的一个。

## 6. 标准库定义 (Standard Library Definitions)

### 6.1 Core（始终启用，无需配置）

| ID | 标签 | 描述 |
|----|------|------|
| `filament_minimal` | `<think>`, `<content>` | 最小 Filament 协议，所有角色卡默认支持 |

### 6.2 Extension（需显式启用）

| ID | 提供的标签 | 描述 | 适用场景 |
|----|-----------|------|----------|
| `variable_update` | `<variable_update>` | 状态变更规则 | RPG 系统 |
| `choice` | `<choice>` | 选择菜单 | 交互叙事 |
| `status_bar` | `<status_bar>` | 自定义状态栏 | 状态展示 |
| `tool_call` | `<tool_call>` | 工具调用 | 外部工具集成 |
| `details` | `<details>` | 折叠摘要 | 辅助信息 |
| `ui_component` | `<ui_component>` | 嵌入式 UI | 复杂交互 |
| `media` | `<media>` | 媒体资源 | 富媒体内容 |
| `chain_of_thought` | - | 强制思维链格式 | 复杂推理 |

### 6.3 Mode（互斥，仅选一个）

| ID | 描述 | 覆盖范围 |
|----|------|----------|
| `live_stream` | 直播间格式 | 全局输出风格 |
| `text_adventure` | 文字冒险游戏格式 | 全局输出风格 |
| `json_mode` | 强制 JSON 输出 | 全局输出格式 |

### 6.4 Override（替换 Extension 实现）

| ID | 描述 | 覆盖目标 |
|----|------|----------|
| `options_format` | 九选项格式 | 替换 `choice` 实现 |
| `json_variable_update` | JSON 变量更新 | 替换 `variable_update` 格式 |

## 7. 配置示例

### 极简对话角色（仅 Core）
```yaml
configuration:
  protocols: []  # 空列表，只使用 Core 标签
```

### RPG 角色（启用 Extension）
```yaml
configuration:
  protocols:
    - variable_update    # 状态管理
    - choice             # 选择菜单
    - status_bar         # 状态展示
```

### 工具助手（选择性启用）
```yaml
configuration:
  protocols:
    - tool_call          # 只需要工具调用
    # 不启用 variable_update
```

## 8. 下一步行动

1.  在项目根目录下创建 `data/schemas` 目录结构。
2.  将常用 Prompt 模式迁移为 Schema 文件。
3.  更新 Jacquard 插件以支持 `SchemaLoader` 和 ESR 构建。
