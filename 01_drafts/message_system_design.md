# 🌲 Clotho 多重宇宙对话系统与状态快照设计 (Multiverse Dialogue & State Snapshot System)

## 1. 核心设计理念：对话即存档 (Dialogue as Save State)

本设计旨在融合 **"类 Git 树状对话历史"** 与 **"Agent 状态管理"**。

核心思想是：**对话节点（Node）不仅仅承载文本，它是当时整个世界状态的"冻结快照"。**

### 1.1 解决的问题
在传统设计中，RPG 状态（如 HP、好感度）通常存储在全局变量中。
*   **问题**：当用户回滚对话（删除最后 3 条消息）时，全局变量（HP）不会自动变回去，导致逻辑断裂（死人复活、好感度错位）。
*   **解法**：将状态绑定在消息节点上。回滚消息 = 回滚世界状态。

### 1.2 核心公式
$$ Node_N = \{ Content, \text{State}_{N}, \text{PromptTrace}_{N} \} $$

---

## 2. 数据结构定义 (Data Structures)

### 2.1 消息节点 (MessageNode)
这是存储在数据库中的最小单元。

```dart
class MessageNode {
  final String id;              // UUID
  final String? parentId;       // 指向父节点 (Git Commit Parent)
  final List<String> childrenIds; // 子节点列表 (方便遍历)
  
  final String role;            // 'user' | 'assistant' | 'system'
  final String content;         // 消息文本
  
  final DateTime timestamp;
  
  // 🌟 核心新增：状态快照
  // 代表“这条消息产生后”的世界状态
  final WorldStateSnapshot stateSnapshot;
  
  // 🌟 核心新增：Prompt 溯源
  // 如果是 assistant 消息，记录生成这条消息时用的 Prompt 蓝图
  // 用于 Debug 和“重试”时的参数复用
  final PromptTrace? promptTrace;
}
```

### 2.2 世界状态快照 (WorldStateSnapshot)
这是一个不可变对象（Immutable Object），存储某一时刻的所有动态数据。

```dart
class WorldStateSnapshot {
  // 1. RPG 精确数值 (来自 SQLite)
  final Map<String, dynamic> variables; // { "hp": 90, "affinity": 50 }
  
  // 2. 活跃的上下文 (来自 Vector DB / Planner)
  // 记录当时生效的 Lorebook 条目 ID，用于回滚时知道当时“脑子里在想什么”
  final List<String> activeLoreIds; 
  
  // 3. 摘要记忆 (Summary)
  // 当时的短期记忆摘要
  final String summary;
}
```

### 2.3 Prompt 溯源 (PromptTrace)
记录“这句话是怎么来的”，用于调试和逻辑复盘。

```dart
class PromptTrace {
  final String plannerThought;   // Planner 的思考过程 (Scratchpad)
  final List<String> usedTools;  // 这一轮调用的工具
  final String finalPrompt;      // 最终喂给 Core LLM 的完整 Prompt (压扁后)
  final Map<String, dynamic> parameters; // Temperature, TopP 等
}
```

---

## 3. 关键流程详解 (The Flow)

### 3.1 正常对话流程 (Append & Commit)

假设当前 HEAD 指向 `Node_A`。

1.  **加载状态 (Load State)**: 
    *   Orchestrator 读取 `Node_A.stateSnapshot`。这是当前的“世界真相”。
    
2.  **规划与执行 (Plan & Act)**:
    *   Planner 基于 `Node_A` 的状态和用户新输入，决定检索哪些 Lore。
    *   生成 `PromptBlueprint`。
    
3.  **生成回复 (Generate)**:
    *   Core LLM 生成文本回复。
    
4.  **后处理 (Post-Process)**:
    *   Post-Process Agent 分析回复，输出状态变更 (Delta)。
    *   例如：`HP - 10`, `Affinity + 5`。
    
5.  **计算新状态 (Compute New State)**:
    *   `New_State` = `Node_A.stateSnapshot` + `Delta`。
    
6.  **提交节点 (Commit Node)**:
    *   创建 `Node_B`。
    *   `Node_B.parentId` = `Node_A.id`。
    *   `Node_B.content` = 回复文本。
    *   `Node_B.stateSnapshot` = `New_State`。
    *   `Node_B.promptTrace` = 本次生成的 Prompt 信息。
    
7.  **移动指针 (Move HEAD)**:
    *   `Session.head` 更新为 `Node_B.id`。

### 3.2 回滚与分支 (Rollback & Branching)

用户对 `Node_B` 不满意，想回到 `Node_A` 重来。

1.  **移动指针**: 用户点击“重新生成”或“编辑上一条”。
2.  **状态回溯**: 系统读取 `Node_A`。
3.  **状态恢复**: 
    *   Orchestrator 丢弃内存中的所有临时状态。
    *   **强制加载** `Node_A.stateSnapshot` 为当前状态。
    *   (此时，HP 自动变回了扣血前的数值)。
4.  **重新执行**: 
    *   基于 `Node_A` 的状态再次运行 Agent Loop。
    *   生成 `Node_C` (Node_B 的兄弟节点)。
5.  **树状分叉**:
    *   `Node_A` 现在有两个子节点：`B` 和 `C`。
    *   HEAD 指向 `Node_C`。

---

## 4. 存储优化策略 (Storage Optimization)

由于每个节点都存快照，数据量可能会膨胀。建议采用 **增量存储 (Delta Storage)** 策略。

*   **关键帧 (Keyframe)**: 每隔 N 个节点（如 10 个），存储完整的 `WorldStateSnapshot`。
*   **增量帧 (Deltaframe)**: 中间的节点只存储 `StateDiff` (例如 `{"hp": -10}`)。
*   **读取时**: 从最近的 Keyframe 开始，依次应用 Delta 计算出当前状态。

---

## 5. 对接现有架构 (Integration)

### 5.1 修改 Jacquard
*   **移除** `MockJacquard` 中的 `List<ChatMessage> _chatHistory`。
*   **引入** `TreeManager` 类，负责维护树结构和 HEAD 指针。
*   `processUserMessage` 不再只是 append list，而是执行上述的 **Commit** 流程。

### 5.2 修改 Mnemosyne
*   Mnemosyne 不再只维护一份全局单例的 State。
*   它需要提供 `restoreState(WorldStateSnapshot snapshot)` 方法，用于在切换节点时瞬间重置内存中的所有变量。

---

## 6. 总结

这个设计实现了**“时间旅行”**的完全闭环：

1.  **结构上**：使用树状结构管理对话分支。
2.  **数据上**：每个节点携带状态快照，保证逻辑一致性。
3.  **调试上**：每个节点携带 Prompt 蓝图，方便开发者追溯“AI 为什么这么说”。

这正是 PyTavern (Neuropean) 区别于普通聊天软件的核心竞争力。