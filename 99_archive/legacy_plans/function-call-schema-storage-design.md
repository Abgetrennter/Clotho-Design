# Function Call Schema 存储与注入方案设计

**版本**: 1.0.0
**日期**: 2025-12-30
**状态**: Draft

## 1. 背景与目标 (Context & Objectives)

在角色扮演（RP）和复杂交互场景中，用户经常需要定义复杂的输出格式或逻辑规则（如“好感度计算规则”、“直播间格式”）。目前这些规则通常直接写死在 Character Card 的 Prompt 字段中，导致：
1.  **复用困难**: 相同的逻辑需要在不同角色卡间复制粘贴。
2.  **维护成本高**: 修改规则需要更新所有相关角色卡。
3.  **Token 浪费**: 缺乏标准化的结构，往往导致 Prompt 冗长且不规范。
4.  **解析困难**: 非标准的输出格式使得前端难以进行结构化解析和 UI 渲染。

本方案旨在设计一套 **Schema Library (协议库)** 机制，将这些规则从角色卡中剥离，标准化存储，并在运行时按需注入。

## 2. 核心概念：分层 Schema 架构 (Layered Schema Architecture)

为了响应“数据与规则分离”的需求，我们将 Schema 设计分为两层：

### L1: State Manipulation Protocol (状态操作层)
定义**“如何修改数据”**的基础机制。这层不包含具体业务逻辑，只定义操作指令（OpCodes）和数据结构。
*   **职责**: 提供标准化的数据变更指令集。采用 Filament v2.1/v2.4 定义的 **`<variable_update>`** 风格。
*   **示例**: `<variable_update>` 标签定义，支持 `[SET, path, value]`, `[ADD, path, number]` 等 Bare Word 指令。
*   **复用性**: 极高，全系统通用。

### L2: Business Rule Schema (业务规则层)
定义**“何时修改数据”**以及**“修改的限制”**。
*   **职责**: 定义具体的游戏规则、数值范围、触发条件。
*   **示例**: “好感度每次最多增加 5 点”，“战斗中受到攻击扣除 HP”。
*   **复用性**: 按场景或游戏系统复用 (e.g., "Galgame 恋爱规则", "D&D 战斗规则")。

### 层级关系
L2 依赖于 L1。L2 的 Prompt 会指导 LLM 生成符合 L1 规范的输出。

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

建议在项目根目录下建立 `data/schemas` (或 `protocols`) 目录：

```text
e:/Code/MyST/design/
├── data/
│   ├── schemas/              # Schema 库根目录
│   │   ├── core/             # 系统内置核心协议
│   │   │   ├── filament_v2.yaml    # Filament 标准协议
│   │   │   └── chain_of_thought.yaml
│   │   ├── extensions/       # 扩展功能
│   │   │   ├── variable_update.yaml # 变量更新规则
│   │   │   └── rpg_combat.yaml
│   │   └── modes/            # 全局模式覆盖
│   │       ├── live_stream.yaml     # 直播模式
│   │       └── text_adventure.yaml
│   └── ...
```

### 3.2 文件格式规范 (YAML)

使用 YAML 作为存储格式，利用其多行字符串处理能力（Block Scalars `|`）。

#### 3.2.1 Schema 定义模板

```yaml
# data/schemas/extensions/variable_update.yaml

meta:
  id: "variable_update_v1"
  name: "通用变量更新规则"
  version: "1.0.0"
  author: "System"
  description: "定义了基于 <UpdateVariable> 的状态变更逻辑"
  type: "augmentation" # 枚举: augmentation (增强), override (覆盖)

# 注入配置：定义这段 Prompt 应该插入到 System Prompt 的哪个位置
injection:
  target: "system_instruction" # system_instruction, post_history, etc.
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

**语法**: `<use_protocol id="schema_id" />`

**示例**:
```xml
User: 进入直播模式！
```

当 Jacquard 检测到此关键词时，会在对话构建 Prompt 时注入对应的 Schema。

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

## 6. 用户案例映射 (Case Mapping)

### 6.1 映射案例 1: 变量更新 (Variable Update)

该案例将被拆分为两个文件：

**L1: Base Protocol (`data/schemas/core/variable_update.yaml`)**
```yaml
meta:
  id: "variable_update_base"
  type: "augmentation"
instruction: |
  <format>
    <variable_update>
      <analysis>
        - (变更原因分析)
      </analysis>
      [
        [OPCODE, path, value],
        ...
      ]
    </variable_update>
  </format>
parser_hints:
  root_tag: "variable_update"
```

**L2: Love System Rule (`data/schemas/rules/love_system.yaml`)**
```yaml
meta:
  id: "love_system_simple"
  type: "augmentation"
  dependencies: ["variable_update_base"] # 声明依赖 L1

instruction: |
  好感度变量更新规则：
  <rule>
    <description>
      - 单次数值限制 [1-5]。
      - 变量路径示例: '角色名.好感度'
      - 使用 [ADD, path, val] 指令。
    </description>
  </rule>
```

### 6.2 映射案例 2: 直播模式 (Live Stream)

**Schema File**: `data/schemas/modes/live_stream.yaml`

```yaml
meta:
  id: "live_stream_mode"
  type: "override"

instruction: |
  <FORMAT_RULE>
  当处于直播模式时，必须强制使用以下格式，禁止输出其他内容。
  <live>
    <basic_info>...</basic_info>
    <barrage>...</barrage>
  </live>
  </FORMAT_RULE>

examples:
  - input: "(进入直播间)"
    output: |
      <live>
       ...
      </live>

parser_hints:
  root_tag: "live"
  behavior: "display_component" # 前端可能需要特殊的 LiveStream组件 来渲染这个标签
```

## 7. 下一步行动

1.  在 `structure/protocols/` 下创建 Schema Library 目录结构。
2.  将用户提供的两个例子转换为正式的 YAML Schema 文件。
3.  更新 `Jacquard` 的架构文档，说明 Schema Loader 的工作原理。
