# 神·数据库 V8 技术文档：数据处理层架构

## 1. 核心架构设计与模块划分

数据处理层（Data Processing Layer）采用**分散存储、动态合并**的架构设计，旨在解决长对话场景下数据一致性与版本管理的难题。该层不依赖单一的全局 JSON 文件，而是将数据切片化存储在聊天记录（Chat History）的元数据中，通过运行时动态重组来构建当前的数据库状态。

### 1.1 模块职责划分

| 模块文件 | 核心职责 | 关键函数 |
| :--- | :--- | :--- |
| `data/data-merge.js` | **合并引擎**：负责从分散的聊天记录中提取、去重并合并生成最新的完整数据对象。 | `mergeAllIndependentTables_ACU` |
| `data/isolation.js` | **存储与隔离**：处理数据的持久化存储，实现多时间线/分支的数据隔离（Data Isolation）。 | `saveIndependentTableToChatHistory_ACU` |
| `data/format.js` | **序列化与转换**：负责 JSON 数据与人类可读格式（Markdown Table）、LLM 友好格式之间的相互转换。 | `formatJsonToReadable_ACU`, `formatTableDataForLLM_ACU` |
| `chat/loader.js` | **数据接入**：作为底层 I/O，负责从 SillyTavern 宿主环境高效读取聊天记录。 | `loadAllChatMessages_ACU` |

### 1.2 核心数据结构

系统在内存中维护一个核心全局对象 `currentJsonTableData_ACU`，其结构如下：

```javascript
{
  "sheet_1": {
    "name": "人物状态表",
    "content": [ ["ID", "Name", "HP"], [1, "Alice", 100] ], // 二维数组：Row 0 为表头
    "sourceData": { ... }, // 元数据：增删改触发器定义
    "updateConfig": { "updateFrequency": 2, ... } // 更新策略配置
  },
  "sheet_2": { ... }
}
```

而在持久化存储层（聊天记录的隐藏字段），数据以增量或全量快照的形式存在：

```javascript
// 消息对象中的 TavernDB_ACU_IsolatedData 字段
{
  "isolation_tag_A": { // 隔离槽位
    "independentData": { "sheet_1": { ... } }, // 仅包含本条消息被更新的表格快照
    "modifiedKeys": ["sheet_1"], // 变更追踪
    "updateGroupKeys": ["sheet_1", "sheet_2"] // 原子性更新组
  }
}
```

---

## 2. 数据流（Data Flow）全过程

数据流的设计遵循**“写时复制（Copy-on-Write）”**与**“读时合并（Merge-on-Read）”**原则。

```mermaid
graph TD
    subgraph Input [输入阶段]
        A[SillyTavern 聊天记录] -->|1. 加载 (chat/loader.js)| B(原始消息列表)
    end

    subgraph Processing [合并处理 (data/data-merge.js)]
        B -->|2. 倒序遍历| C{检查数据隔离标签}
        C -->|匹配| D[提取 TavernDB_ACU_IsolatedData]
        D -->|3. 状态恢复| E(表格版本映射表)
        E -->|4. 冲突解决| F[生成 currentJsonTableData_ACU]
    end

    subgraph Output [持久化阶段 (data/isolation.js)]
        G[AI 更新结果] -->|5. 写入| H{选择目标消息}
        H -->|6. 构建隔离槽| I[TavernDB_ACU_IsolatedData]
        I -->|7. 保存| J[SillyTavern 历史记录文件]
    end
    
    F -->|同步| K[UI 渲染 / 世界书更新]
```

### 2.1 输入解析与清洗

1.  **加载**：`loadAllChatMessages_ACU` 通过 `TavernHelper` API 获取当前会话的所有消息。
2.  **清洗**：在合并过程中，系统会自动过滤无效的、格式错误的或与当前隔离标签（Isolation Tag）不匹配的数据块。
    *   **隔离逻辑**：系统检查 `settings_ACU.dataIsolationCode`。如果开启了隔离模式，合并器只读取带有相同 `identity` 或位于对应隔离槽位的数据，从而实现“平行世界”互不干扰。

### 2.2 转换与合并逻辑

`mergeAllIndependentTables_ACU` 函数实现了核心的合并算法：

1.  **倒序扫描**：从最新的消息开始向前遍历。
2.  **按表搜索**：对于每一个已定义的表格（Sheet），系统寻找其在聊天记录中**最后一次**出现的有效版本。
3.  **增量构建**：
    *   一旦找到某个表格的最新快照（Snapshot），就将其加入 `mergedData` 集合，并标记该表已找到。
    *   继续向前搜索尚未找到的表格。
    *   如果遍历完所有记录仍有表格缺失，则使用默认模板进行初始化。
4.  **原子性保证**：通过 `updateGroupKeys` 字段，系统能识别一次批量更新操作涉及的所有表格，确保读取到的数据在逻辑上是属于同一“版本”的。

### 2.3 持久化存储的具体逻辑

`saveIndependentTableToChatHistory_ACU` 负责将内存中的变更写回存储：

1.  **目标定位**：通常选择最新的 AI 回复消息作为载体（Anchor）。
2.  **隔离槽位写入**：
    *   系统不会覆盖整条消息的元数据，而是根据当前的 `currentIsolationKey`（如 "Timeline_A"），读取或创建对应的 `TavernDB_ACU_IsolatedData["Timeline_A"]` 对象。
3.  **瘦身存储**：
    *   调用 `sanitizeSheetForStorage_ACU` 移除运行时生成的临时字段（如 UI 状态），只保留核心内容（`content`, `name`, `sourceData`）。
    *   仅保存**本次被修改**或需要强制同步的表格，而非全量保存所有表格，以此降低存储压力。

---

## 3. 关键函数实现细节与异常处理

### 3.1 核心函数：`mergeAllIndependentTables_ACU` (data/data-merge.js)

*   **实现细节**：
    该函数维护一个 `foundSheets` 映射表。在遍历过程中，它会优先检查新版数据结构 (`TavernDB_ACU_IsolatedData`)，如果未找到，则向下兼容检查旧版字段 (`TavernDB_ACU_IndependentData`)。这种双重检查机制保证了新旧版本的平滑过渡。
    
*   **异常处理**：
    *   **空历史处理**：如果聊天记录为空，函数直接返回 `null`，触发后续的初始化流程。
    *   **数据完整性修复**：在合并完成后，会自动扫描 `AM` (Auto-Merged) 标记的数据行，如果发现标记丢失，会自动补全 `auto_merged` 字段，防止数据在后续处理中被误判为人工修改。

### 3.2 核心函数：`saveIndependentTableToChatHistory_ACU` (data/isolation.js)

*   **实现细节**：
    该函数实现了**细粒度的锁机制**。它不仅保存数据，还同时更新 `modifiedKeys` 和 `updateGroupKeys`。这两个辅助字段对于后续的“自动更新触发器”至关重要——它们帮助触发器判断某个表格距离上次更新已经过了多少轮对话。
    
*   **异常处理**：
    *   **目标丢失**：如果找不到合法的 AI 消息（例如纯用户对话），函数会记录警告并放弃保存，或者尝试回退到最近的一条消息。
    *   **并发写入保护**：虽然 JS 是单线程，但文件 I/O 是异步的。函数内部包含 `await new Promise(resolve => setTimeout(resolve, 500))` 强制延迟，确保文件系统完成写入操作后再通知前端刷新，避免读取到脏数据（UI 回跳问题）。

### 3.3 转换函数：`formatJsonToReadable_ACU` (data/format.js)

*   **实现细节**：
    采用 Markdown Table 语法进行序列化。为了适应 LLM 的上下文窗口，该函数支持**选择性输出**：
    *   自动过滤掉 `exportConfig.enabled = true` 的表格（这些表通常由独立文件管理）。
    *   特殊处理“总结表”，支持截断输出（如只输出最后 10 行），以节省 Token。
    
*   **异常处理**：
    *   **空数据容错**：如果表格内容为空或结构损坏，函数会输出默认占位符或仅输出表头，防止 LLM 在解析时产生幻觉。
