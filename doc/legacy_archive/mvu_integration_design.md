# MVU 特性集成设计文档 (MVU Integration Design Document)

**状态**: Draft
**相关文档**: `system_architecture.md`, `st_prompt_template_migration_design.md`

## 1. 概述

MagVarUpdate (MVU) 是一个基于变量的状态维护系统，其核心理念是通过**结构化的变量更新**和**LLM 主动的状态分析**，来替代传统的正则匹配更新。Clotho 架构中的 Mnemosyne (数据层) 和 Filament (协议层) 已经具备了支持类似功能的基础，但需要吸纳 MVU 的优秀设计，特别是其 "Value with Description" (VWD) 模型和 `<Analysis>` 思维链。

本设计旨在将 MVU 的核心特性无缝迁移到 Clotho 架构中，增强 Clotho 的状态管理能力。

## 2. 核心特性迁移

| MVU 特性 | Clotho 对应组件 | 迁移方案 |
| :--- | :--- | :--- |
| **Value with Description (VWD)** | Mnemosyne (State Schema) | 引入 VWD 数据结构，支持 `[Value, Description]` 存储。 |
| **`<Analysis>` 块** | Filament Protocol | 在 `<thought>` 或新的 `<analysis>` 标签中显式要求变量分析。 |
| **`_.set` / `_.update`** | Filament Protocol | 扩展 `<state_update>` 标签，支持更细粒度的操作 (`set`, `push`, `assign`)。 |
| **Display Data / Delta Data** | Mnemosyne (State Chain) | Mnemosyne 计算 Delta 并生成用于 UI 展示的 `DisplayData`。 |
| **Schema Validation ($meta)** | Mnemosyne (Validation) | 在 Mnemosyne 中实现 Schema 校验，支持 `$meta` 定义的可扩展性/必填项。 |

## 3. Mnemosyne 数据结构升级

### 3.1 Value with Description (VWD) 支持

MVU 使用 `[Value, Description]` 的数组形式来存储变量，这样既能存储值，又能存储给 LLM 看的描述/约束。

在 Mnemosyne 中，我们将状态树的节点定义升级为支持这种复合结构。

```dart
// Dart 伪代码: 状态节点值的类型定义
typedef StateValue = dynamic; // 可以是 String, num, bool, List, Map
typedef StateDescription = String;

class StateNode {
  StateValue value;
  StateDescription? description; // 可选的描述

  // 序列化为 JSON 时
  // 如果没有 description，直接序列化 value
  // 如果有 description，序列化为 [value, description]
  dynamic toJson() {
    if (description == null) return value;
    return [value, description];
  }
}
```

### 3.2 Schema 与元数据 ($meta)

引入 MVU 的 `$meta` 概念，用于控制状态树的结构约束。

```json
{
  "character": {
    "$meta": {
      "extensible": false, // 不允许 LLM 随意添加根级属性
      "required": ["health", "mood"]
    },
    "health": [100, "当前生命值，范围 0-100"],
    "inventory": {
      "$meta": {
        "extensible": true, // 允许添加新物品
        "template": ["Unknown Item", "物品描述"] // 新增物品的默认模板
      }
    }
  }
}
```

## 4. Filament 协议扩展 (Protocol v2)

为了支持 MVU 的复杂更新逻辑，Filament 的 `<state_update>` 需要支持更丰富的语义。

### 4.1 新增操作指令 (Protocol v2)

为了简化 LLM 的生成负担并提高解析的鲁棒性，我们将采用 **JSON 列表包裹三元组** 的形式来描述状态变更。这种方式比 XML 标签更紧凑，且天然符合代码逻辑。

**格式定义**: `[OpCode, Path, Value]`

*   `OpCode`: 操作码 (String)。
    *   `"SET"`: 设置/覆盖值。
    *   `"ADD"`: 数值加法。
    *   `"PUSH"`: 数组追加。
    *   `"REM"`: 数组移除（按值）。
    *   `"DEL"`: 删除键。
    *   `"MERGE"`: 对象合并。
*   `Path`: 变量路径 (String)，如 `"character.inventory[0]"`.
*   `Value`: 目标值 (Any)，可以是数字、字符串、JSON 对象等。

**Filament 标签**:
我们保留 `<state_update>` 标签作为容器，但内容变更为单一的 JSON 数组。

```xml
<state_update>
[
  ["SET", "character.mood", "happy"],
  ["ADD", "character.gold", 50],
  ["PUSH", "inventory", {"name": "Sword", "atk": 10}],
  ["MERGE", "quest_log", {"quest_1": "completed"}]
]
</state_update>
```

**优势**:
1.  **Token 效率高**: 相比重复的 XML 标签，JSON 数组更短。
2.  **解析简单**: 直接使用 `JSON.parse` 即可，无需复杂的 XML 解析器。
3.  **类型安全**: JSON 原生支持 Number, Boolean, Object，不需要像 XML 那样都作为 String 解析后再转换。

### 4.2 引入 `<analysis>` 标签

在 `<state_update>` 之前，强制要求 LLM 输出 `<analysis>`，用于分析变量变化的逻辑。这对应 MVU 的 `<Analysis>` 块。

**Prompt 示例:**

```xml
<system>
请分析剧情发展，并更新相关变量。
格式要求：
<analysis>
  - 变量路径: Y/N (是否变化)
  - 原因分析...
</analysis>
<state_update>
[
  ["OP", "path", value],
  ...
]
</state_update>
</system>
```

**LLM 输出示例:**

```xml
<analysis>
  - character.health: N (未受伤)
  - character.gold: Y (完成任务获得奖励)
  - inventory: Y (获得新物品)
</analysis>
<state_update>
[
  ["ADD", "character.gold", 100],
  ["PUSH", "inventory", "Golden Key"]
]
</state_update>
<reply>
这是给你的奖励。
</reply>
```

## 5. 渲染与 Prompt 构建 (Weaver)

### 5.1 VWD 的 Prompt 呈现

当构建 Prompt 给 LLM 时，Mnemosyne 需要将状态树展平（Flatten）或格式化为 JSON。
对于 VWD 节点，我们保留 `[Value, Description]` 格式，因为 Description 本身就是给 LLM 看的 Prompt。

**System Prompt 中的状态区:**

```json
// Current State
{
  "character": {
    "health": [80, "HP, 0 is dead"],
    "mood": ["Neutral", "Current emotion"]
  }
}
```

### 5.2 Display Data 生成

在 UI 层（状态栏），用户通常只关心值，而不关心描述。
Mnemosyne 在输出给 UI 时，需要提供纯净的 `DisplayData`（去除 Description）。

同时，为了支持 MVU 的 "Change Log" 功能，State Updater 插件需要计算 Delta：

*   **DisplayData**: `{"character.health": 80}` (用于渲染 UI)
*   **DeltaLog**: `["character.health: 100 -> 80 (Battle Damage)"]` (用于 Toast 或日志展示)

## 6. 迁移 Todo List

1.  **Mnemosyne**:
    *   实现 `StateNode` 类，支持 VWD。
    *   实现 `$meta` 解析与校验逻辑。
    *   实现 `toJson(forLLM)` (带描述) 和 `toJson(forUI)` (不带描述) 的导出方法。

2.  **Filament Parser**:
    *   升级解析器，支持 `<push>`, `<assign>`, `<delete>` 等新标签。
    *   支持解析 `<analysis>` 标签（主要用于调试和展示思维链，不直接影响状态）。

3.  **State Updater Plugin**:
    *   实现新的状态更新逻辑（处理数组操作、对象合并）。
    *   实现 Delta 计算，生成变更日志。

4.  **Weaver**:
    *   更新 System Prompt 模板，包含 VWD 格式的状态 JSON。
    *   更新 Instruction，教 LLM 如何使用新的 Filament 标签进行更新。
