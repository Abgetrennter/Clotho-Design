# Skein 编织系统设计规范 (Skein Weaving System)

**版本**: 1.0.0
**日期**: 2026-02-09
**状态**: Draft
**关联文档**:
- [`README.md`](README.md)
- [`preset-system.md`](preset-system.md)
- [`../mnemosyne/abstract-data-structures.md`](../mnemosyne/abstract-data-structures.md)
- [`../workflows/prompt-processing.md`](../workflows/prompt-processing.md)

---

## 1. 核心概念 (Core Concepts)

**Skein (绞纱)** 是 Jacquard 编排层中的核心数据容器。与传统的 Prompt 字符串拼接不同，Skein 是一个**具备语义感知的异构区块容器**。它不仅承载文本，还承载了每个文本块的意图、优先级和编织逻辑。

**编织 (Weaving)** 是指将来自不同源头（系统预设、对话历史、世界书、RAG 检索）的零散信息，按照预定策略“缝合”成一个连贯的线性上下文的过程。

### 1.1 核心价值
1.  **像素级控制**: 精确控制每条信息在 Context Window 中的位置（如“倒数第3条”）。
2.  **语义去重**: 基于语义标签防止信息重复（如避免 System Prompt 和 Lorebook 同时介绍“世界背景”）。
3.  **动态聚焦**: 根据 Planner 的决策（如“战斗中”）动态调整不同类型信息的权重。

---

## 2. 数据结构 (Data Structures)

### 2.1 Skein 结构

Skein 内部维护三条逻辑链，模拟纺织过程中的经纬线与浮线。

```typescript
interface Skein {
  // 1. 经线 (System Chain): 静态骨架，定义认知框架
  systemChain: PromptBlock[];
  
  // 2. 纬线 (History Chain): 动态基底，即线性时间轴(最近几条聊天记录的滑动窗口)
  historyChain: PromptBlock[];
  
  // 3. 浮线 (Floating Chain): 待注入的动态资产
  floatingChain: FloatingAsset[];
  
  // 元数据与约束
  metadata: {
    tokenLimit: number;
    activePresetId: string;
    focusMode: string; // e.g., "narrative", "combat"
  };
}
```

### 2.2 PromptBlock (基础区块)

构成 System Chain 和 History Chain 的原子单位。

```typescript
interface PromptBlock {
  id: string;
  type: BlockType; // 见 preset-system.md 定义 (e.g., META_IDENTITY, CHAT_HISTORY)
  
  role: 'system' | 'user' | 'assistant' | 'tool';
  content: string; // 支持 Jinja2 模板
  
  // 动态状态
  isActive: boolean;
  tokenCount?: number; // 预估或实测值
}
```

### 2.3 FloatingAsset (浮动资产)

Floating Chain 中的节点。它是 Mnemosyne 数据在 Jacquard 中的投影。

```typescript
interface FloatingAsset {
  // 1. 资产身份
  id: string;          // 对应 LorebookEntry.id 或 Event.id
  sourceType: 'lore' | 'event' | 'narrative' | 'thought';
  
  // 2. 内容载体 (Lazy Load)
  content: string;     // 实际文本
  summary?: string;    // 用于去重比对的摘要
  
  // 3. 编织参数 (Injection Strategy)
  injection: {
    priority: number;         // 排序权重 (绝对值)
    depthHint: number;        // 期望深度 (0 = 紧贴最新消息)
    positionStrategy: 'system_extension' | 'floating_relative' | 'user_anchor';
    budgetCost: number;       // Token 消耗预估
  };
  
  // 4. 上下文关联
  triggers: string[];       // 触发词
  refersTo: string[];       // 关联实体 ID
}
```

---

## 3. Mnemosyne 映射策略 (Mnemosyne Integration)

根据 Mnemosyne 的 **4-Quadrant Static Taxonomy**，我们将不同类型的记忆映射到不同的编织策略上。

| Mnemosyne 分类 | 语义位置 (Semantic Slot) | 注入策略 (`injection`) | 典型示例 |
| :--- | :--- | :--- | :--- |
| **Axiom (公理)** | **System Extension** | `pos: system_extension`, `prio: 100` | 物理法则、魔法基础设定、绝对的世界观。 |
| **Agent (代理)** | **Recent History** | `pos: floating_relative`, `depth: 2-4`, `prio: 90` | 在场 NPC 状态、当前场景环境描述。 |
| **Encyclopedia (百科)** | **Deep Context** | `pos: floating_relative`, `depth: 5-10`, `prio: 50` | 历史背景、物品详细说明、RAG 检索结果。 |
| **Directive (指令)** | **User Anchor** | `pos: user_anchor`, `prio: 110` | 针对当前回合的 GM 指令、越狱 Prompt。 |

---

## 4. 编织算法 (The Weaving Algorithm)

Assembler 组件执行的核心逻辑，负责将三条链坍缩为单一列表。

### Step 1: 骨架构建 (Skeleton Construction)
该步骤由 L1 Preset 中的 `skein_skeleton` 配置驱动。

初始化结果列表 `ResultList`。
1.  **加载 System Chain**: 遍历 `skein_skeleton` 定义的 Slots。
2.  **填充 Slot**: 从 System Chain 中查找匹配 `allowed_types` 的 Block 填充该 Slot。
3.  **Axiom 注入**: 扫描 `Floating Chain` 中所有 `strategy == 'system_extension'` 的资产，将其追加到 `skein_skeleton` 中指定了 `append` 策略的 Slot（如 `world_context`）。
4.  将构建好的骨架放入 `ResultList` 头部。

### Step 2: 锚点定位 (Anchoring)
处理 `History Chain`。
1.  反向遍历 History Chain (Newest -> Oldest)。
2.  为每条消息分配 **相对深度索引 (Depth Index)**。
    *   最新消息 Depth = 0。
    *   次新消息 Depth = 1。
    *   ...

### Step 3: 浮线缝合 (Floating Stitching)
该步骤由 L1 Preset 中的 `weaving_rules` 配置驱动。

处理剩余的 `Floating Chain` (Agent, Encyclopedia)。
1.  **规则匹配**: 遍历 `Floating Chain` 中的每个资产，根据其类型 (`AGENT`, `ENCYCLOPEDIA`) 匹配 `weaving_rules` 中定义的注入策略（深度范围、优先级）。
2.  **分组与排序**: 将资产分配到目标深度 (Depth)，并在同一深度内按 `priority` 降序排序。
3.  **插入**:
    *   遍历 History Chain。
    *   在每个 Depth 节点前，检查是否有待插入的 Floating Asset。
    *   如果有，将其插入该位置，并标记为 `role: system` (通常)。
4.  **User Anchor 处理**: 对于匹配 `anchor_to_user` 规则的资产（如 `DIRECTIVE`），将其紧贴最新的一条 User Message 插入。

### Step 4: RAG 融合与去重 (RAG Fusion & Deduplication)
在缝合过程中执行语义检查：
1.  **精准去重**: 检查 `FloatingAsset.id`，确保同一条 Lore 不会被多次插入。
2.  **语义覆盖**:
    *   如果已插入一个高优先级的 **Agent** 条目（如“Alice 的详细状态”）。
    *   且存在一个低优先级的 **Encyclopedia** 条目（如“Alice 的简略介绍”）。
    *   系统检测到两者 `refersTo` 包含相同的 `char_id`，则丢弃低优先级条目。

### Step 5: 预算裁剪 (Budget Truncation)
最后执行 Token 预算控制。
1.  计算 `ResultList` 总 Token。
2.  若超限，执行 **智能丢弃 (Smart Eviction)**：
    *   **Phase 1 (Low Value)**: 丢弃 `Floating Chain` 中优先级 < 50 的 Encyclopedia 条目。
    *   **Phase 2 (History Trim)**: 从最久远的 History 消息开始丢弃（保留 System 和近期 History）。
    *   **Phase 3 (Emergency)**: 丢弃剩余的 Floating Assets，仅保留 System + Recent History。

---

## 5. 算法伪代码 (Pseudocode)

```python
def weave(skein: Skein) -> List[Message]:
    result = []
    
    # 1. System & Axioms
    axioms = [f for f in skein.floatingChain if f.strategy == 'system_extension']
    system_block = merge(skein.systemChain, axioms)
    result.extend(system_block)
    
    # 2. Prepare History with Anchors
    history = skein.historyChain.reverse() # Newest first
    
    # 3. Insert Floating Assets
    floating_pool = [f for f in skein.floatingChain if f.strategy != 'system_extension']
    floating_pool.sort(key=lambda x: x.priority, reverse=True)
    
    final_history = []
    current_depth = 0
    
    for msg in history:
        # Check insertions for this depth
        injects = [f for f in floating_pool if f.depthHint == current_depth]
        
        # User Anchor logic
        if msg.role == 'user' and current_depth == 0:
            directives = [f for f in floating_pool if f.strategy == 'user_anchor']
            injects.extend(directives)
            
        final_history.append(msg)
        final_history.extend(to_prompt_block(injects)) # Insert AFTER the message (reverse logic)
        
        current_depth += 1
        
    # 4. Finalize
    final_history.reverse() # Restore chronological order
    result.extend(final_history)
    
    # 5. Truncate
    return smart_truncate(result, skein.metadata.tokenLimit)
```

---

## 6. 优势总结

1.  **结构化有序**: 彻底告别“把所有 Lore 塞到开头”的粗放做法，实现了信息的**情境化注入**。
2.  **Mnemosyne 协同**: 完美承接数据层的结构化设计，让“数据分类”真正转化为“生成效果”。
3.  **Token 效率**: 智能去重和分级丢弃策略，确保有限的上下文窗口被最高价值的信息填充。
