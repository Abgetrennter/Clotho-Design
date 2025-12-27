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

为了规范状态树的结构，Mnemosyne 支持 `$meta` 字段定义约束。

### 4.1 约束定义
*   **extensible**: 是否允许 LLM 在根节点下添加新属性。
*   **required**: 必须存在的字段列表。
*   **template**: 新增项目的默认模板。

**示例 JSON:**
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
        "template": ["Unknown Item", "物品描述"]
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
