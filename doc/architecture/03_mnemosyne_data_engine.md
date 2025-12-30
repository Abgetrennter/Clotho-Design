 # 第三章：数据中枢与记忆引擎 (Mnemosyne Layer)

**版本**: 1.0.0
**日期**: 2025-12-23
**状态**: Draft
**作者**: 资深系统架构师 (Architect Mode)
**源文档**: `system_architecture.md`, `mvu_integration_design.md`

---

## 1. 引擎概览 (Mnemosyne Overview)

**Mnemosyne** 是数据层的核心，它不再仅仅是静态数据的仓库，而是升级为 **动态上下文生成引擎 (Dynamic Context Generation Engine)**。它负责管理系统的“长期记忆”与“瞬时状态”，并为编排层提供精准的上下文快照。

### 1.1 核心职责
1.  **数据托管**: 管理 Lorebook, Presets, World Rules。
2.  **快照生成**: 根据 Time Pointer 聚合数据，生成不可变的 `Punchcards`。
3.  **状态管理**: 维护 RPG 变量，处理 VWD (Value with Description) 数据模型。

---

## 2. 多维上下文链 (Multi-dimensional Context Chains)

虽然数据在物理上以 **增量 (Incremental)** 形式存储，但在逻辑上，Mnemosyne 将其投影为数条平行的 **上下文链网**。

### 2.1 链网结构
1.  **History Chain (历史链)**:
    *   内容: 标准对话记录。
    *   逻辑: 线性投影，提供 LLM 理解剧情的连贯性。
2.  **State Chain (状态链)**:
    *   内容: 结构化的 RPG 数值与状态。
    *   策略: **关键帧 (Keyframe) + 增量 (Delta)**。
    *   作用: 确保“时间旅行”时，世界状态能精确回滚。
3.  **RAG Chain (检索增强链)**:
    *   内容: 向量化的记忆片段。
    *   逻辑: 基于 History 的语义检索结果，动态注入背景知识。

### 2.2 Context Pipeline 工作流
当 Jacquard 请求快照时，Pipeline 执行 **投影 (Projection)** 操作：
1.  **Trace**: 根据 Session Pointer 回溯树路径。
2.  **Project**: 合并路径文本，提取当前状态，执行向量检索。
3.  **Assemble**: 封装为不可变的 `Punchcards` 返回给 Jacquard。

---

## 3. Value with Description (VWD) 数据模型

为了解决“数值对 LLM 缺乏语义”的问题，我们引入了 MVU 的 **VWD** 模型。

### 3.1 结构定义
状态节点不再是简单的 Key-Value，而是支持 `[Value, Description]` 的复合结构。

```dart
// Dart 伪代码
class StateNode {
  dynamic value;          // 实际值 (80)
  String? description;    // 语义描述 ("HP, 0 is dead")
  
  dynamic toJson() => description == null ? value : [value, description];
}
```

### 3.2 渲染策略
*   **System Prompt (给 LLM 看)**: 渲染完整的 `[Value, Description]`，让 LLM 理解变量含义。
    *   `"health": [80, "HP, 0 is dead"]`
*   **UI Display (给用户看)**: 仅渲染 `Value`。
    *   `Health: 80`

---

## 4. 状态 Schema 与元数据 ($meta)

为了规范状态树的结构并增强数据引擎的灵活性，Mnemosyne 支持 `$meta` 字段定义约束、模板与权限。

### 4.1 核心元数据定义
*   **template**: 定义当前层级及其子层级的默认结构（支持多级继承）。
*   **updatable**: 是否允许修改该节点的值（默认 true）。
*   **necessary**: 删除保护级别 (`self` | `children` | `all`)。
*   **description**: 语义化描述（VWD 集成）。
*   **extensible**: 是否允许 LLM 在根节点下添加新属性。
*   **required**: 必须存在的字段列表。

### 4.2 多级模板继承 (Multi-level Template Inheritance) - v1.1
Mnemosyne 支持在状态树中定义 `$meta.template`，并在数据访问时动态计算继承链。

**继承逻辑**:
1.  **向上查找**: 从目标节点向上遍历至根节点，收集所有 `$meta.template`。
2.  **深度合并**: 按 "父级 -> 子级 -> 自身数据" 的顺序进行深度合并 (Deep Merge)。
3.  **覆盖机制**: 子级模板覆盖父级，实际数据覆盖所有模板。

**示例**:
```json
{
  "characters": {
    "$meta": {
      "template": { "hp": 100, "level": 1 } // 基类模板
    },
    "npcs": {
      "$meta": {
        "template": { "faction": "neutral" } // 子类模板，继承 hp=100
      },
      "guard": { "class": "Warrior" } // 实际数据，隐含 hp=100, faction=neutral
    }
  }
}
```

### 4.3 细粒度权限控制 (Fine-grained Permission) - v1.1
引入 `$meta.necessary` 和 `$meta.updatable` 实现数据保护。

| 权限字段 | 值 | 行为 |
| :--- | :--- | :--- |
| **necessary** | `"self"` | 保护节点自身不被删除 |
| | `"children"` | 保护直属子节点不被删除 |
| | `"all"` | 保护整个子树不被删除 |
| **updatable** | `false` | 锁定节点值，禁止修改（除非操作显式覆盖） |

### 4.4 完整 Schema 示例
```json
{
  "character": {
    "$meta": {
      "extensible": false,
      "required": ["health", "mood"]
    },
    "health": [100, "当前生命值"],
    "inventory": {
      "$meta": {
        "extensible": true,
        "template": {
           "name": "Unknown Item", 
           "desc": "物品描述",
           "$meta": { "necessary": "self" }
        }
      }
    }
  }
}
```

---

## 5. 快照与变更管理

### 5.1 状态更新流程
1.  Jacquard 解析出 `State Delta`（变更增量）。
2.  Mnemosyne 接收 Delta，校验 Schema。
3.  生成新的状态节点，存入数据库。
4.  计算用于 UI 展示的 **Display Data** (纯值) 和 **Change Log** (如 "Health: 100 -> 80")。

### 5.2 确定性回溯
由于采用了 Keyframe + Delta 机制，当用户回滚到之前的消息时，Mnemosyne 能瞬间重建当时的状态，确保剧情与数值的完美一致。
