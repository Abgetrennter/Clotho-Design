好的，这是一份为您整理的**“基于多重宇宙树（Multiverse Dialogue Tree）的非线性对话系统设计方案”**。

这份文档剥离了具体的代码实现，专注于**理论模型**、**数据流向**和**逻辑定义**，您可以直接将其作为架构文档或开发规范使用。

---

# 多重宇宙对话树模型 (Multiverse Dialogue Tree Model)

## 1. 核心设计哲学 (Core Philosophy)

本模型旨在解决大语言模型（LLM）交互中的“探索性”需求。其核心思想是将线性的对话体验与树状的数据存储分离。

*   **数据不可变性 (Immutability)**：历史消息一旦产生，原则上不进行物理修改。所谓的“编辑”或“重生成”，本质上是创建新的节点。
*   **状态分离 (State Separation)**：
    *   **存储态 (Storage State)**：一棵包含所有历史分支的树（Tree）。
    *   **表现态 (Presentation State)**：一条从根节点到当前指针的线性链（Linear List）。
*   **LLM 无感 (LLM Agnostic)**：LLM 仅作为无状态的函数处理器，接收表现态的线性列表，并不感知背后的树状结构。

## 2. 数据结构抽象 (Data Structure Abstraction)

### 2.1 消息节点 (Message Node)
这是系统的最小原子单位。每个节点并不存储它属于哪条“线”，而是只存储它从哪里“来”。

*   **定义**：`Node = { ID, Parent_ID, Content, Role, Metadata }`
*   **关键属性**：
    *   `ID`：全局唯一标识。
    *   `Parent_ID`：指向上一个节点的指针（根节点的 Parent 为 Null）。**这是构建树的核心。**
    *   `Content/Role`：对话内容与角色（User/Assistant）。
    *   `Metadata`：生成参数（Temperature, Model）、时间戳等。

### 2.2 会话指针 (Session Pointer / HEAD)
为了在复杂的树中确定用户的“当前位置”，需要维护一个指针状态。

*   **定义**：`Session = { ID, Current_Leaf_ID }`
*   **作用**：`Current_Leaf_ID` 类似于 Git 中的 `HEAD`。它指向用户当前看到的最后一条消息。

---

## 3. 状态投影机制 (State Projection Mechanism)

这是连接“树状存储”与“线性 LLM”的桥梁。我们称之为**“线性投影 (Linear Projection)”**。

### 理论公式
$$ Context = \text{Reverse}( \text{TraceBack}( \text{HEAD} ) ) $$

### 逻辑流程
1.  **寻址**：系统读取当前的 `HEAD` 指针。
2.  **回溯 (TraceBack)**：从 `HEAD` 开始，通过 `Parent_ID` 递归向上查找，直到根节点。
3.  **序列化**：收集路径上的所有节点：`[Node_N, Node_N-1, ..., Node_Root]`。
4.  **反转**：将序列反转为时间正序：`[Node_Root, ..., Node_N-1, Node_N]`。
5.  **输出**：这份线性列表即为发送给 LLM 的 Context。

---

## 4. 关键行为逻辑模型 (Key Behavioral Logic)

所有用户操作都映射为对**节点树的生长**和**指针的移动**。

### 4.1 正常对话 (Append)
用户发送新消息，或 AI 回复。
*   **操作**：创建一个新节点 `New_Node`。
*   **挂载**：`New_Node.Parent_ID = Current_HEAD`。
*   **移动**：`Current_HEAD` 更新为 `New_Node.ID`。
*   **结果**：树的高度 +1，当前分支向前延伸。

### 4.2 重新生成 (Regenerate / Branching)
用户对 AI 的最后一条回复不满意，点击重试。
*   **场景**：当前 HEAD 指向 `Node_A`。
*   **操作**：找到 `Node_A` 的父亲 `Parent_P`。
*   **挂载**：创建新节点 `Node_B`，`Node_B.Parent_ID = Parent_P`。
*   **移动**：`Current_HEAD` 更新为 `Node_B.ID`。
*   **结果**：`Parent_P` 现在有了两个子节点（A 和 B）。用户处于分支 B。

### 4.3 历史修改 (Time Travel & Edit)
用户回到 5 轮对话前，修改了自己的提问。这被视为“从历史节点分叉”。
*   **场景**：用户想修改历史节点 `Node_Old`。
*   **操作**：
    1.  找到 `Node_Old` 的父亲 `Parent_X`。
    2.  创建新节点 `Node_New`（包含修改后的内容），`Node_New.Parent_ID = Parent_X`。
*   **移动**：`Current_HEAD` 更新为 `Node_New.ID`。
*   **后续**：此时 `Node_New` 是叶子节点。系统自动触发 LLM 请求，生成的 AI 回复将挂载在 `Node_New` 之后。
*   **结果**：产生了一条全新的平行时间线。旧的时间线依然存在，随时可以切回去。

### 4.4 切换分支 (Checkout)
用户在 UI 上点击“查看上一版本”或“< 2/5 >”。
*   **操作**：用户不产生新数据，只是单纯修改 `Current_HEAD` 指向已存在的某个兄弟节点 ID。
*   **结果**：投影机制会立即计算出新的线性上下文，UI 刷新为另一条时间线。

---

## 5. 系统边界与职责划分 (System Boundaries)

### 5.1 应用层 (Client/Server App)
*   **职责**：全知全能的上帝视角。
*   **任务**：
    *   维护整棵树的结构（增删节点）。
    *   维护 `HEAD` 指针。
    *   执行“投影”逻辑，准备 Prompt。
    *   处理 UI 上的“左右切换”逻辑（查询某节点的兄弟节点）。

### 5.2 推理层 (LLM Service)
*   **职责**：无状态的计算引擎。
*   **任务**：
    *   接收 `List<Message>`。
    *   返回 `String` (Text Stream)。
*   **感知**：完全不知道树的存在，也不需要知道这是第几次生成。

---

## 6. 总结 (Summary)

该模型将复杂的**版本控制问题**简化为**树的生长问题**。

*   **对于用户**：这是一个拥有“后悔药”和“平行宇宙”探索能力的强大聊天工具。
*   **对于 LLM**：这只是普通的、连续的对话。
*   **对于开发者**：只需要维护“节点（Node）”和“指针（Pointer）”两个核心概念，无需处理复杂的 Merge 或 Rebase 算法，逻辑健壮且易于扩展。