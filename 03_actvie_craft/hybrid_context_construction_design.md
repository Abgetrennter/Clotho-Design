# 混合上下文构建与 FlashLLM 策展设计 (Hybrid Context Construction Design)

**版本**: 0.1.0
**日期**: 2026-01-10
**状态**: Draft
**关联文档**: 
- `../00_active_specs/core/jacquard-orchestration.md`
- `../00_active_specs/core/mnemosyne-data-engine.md`

---

## 1. 核心理念 (Core Concept)

为了解决长上下文场景下“精确性”与“相关性”的矛盾，我们提出 **混合上下文构建 (Hybrid Context Construction)** 架构。

该架构遵循 **"Bone & Flesh" (骨肉分离)** 原则：
*   **骨架 (Skeleton)**: 由确定性逻辑生成的、不可或缺的上下文（如当前生命值、任务列表、最近对话）。必须绝对准确，由规则驱动。
*   **血肉 (Flesh)**: 由概率性模型筛选的、辅助性的上下文（如回忆、传说、背景设定）。允许模糊，由 FlashLLM 驱动。

---

## 2. 架构拓扑 (Architecture Topology)

在 `Jacquard` 流水线中，引入了 **Planner** 作为“战术指挥官”，随后 `Skein Builder` 分叉为双流并行结构，最终在 `Assembler` 阶段汇聚。

```mermaid
graph TD
    %% 输入阶段
    UserInput[用户输入] --> Planner[Pre-Flash Planner]

    %% Phase 0: Planner Decision (The Brain)
    subgraph "Phase 0: Planner Decision (Tactical)"
        Planner --> Triage{1. 意图分流}
        Triage -- Numerical --> FastPath[数值快速通道]
        Triage -- Narrative --> Analyze[2. 分析聚焦 & 策略]
        
        Analyze --> SetFocus[Focus: 设定 Active Quest]
        Analyze --> SetGoal[Goal: 设定 Current Goal]
        Analyze --> SetStrat[Strategy: 选择 Template]
        
        SetFocus & SetGoal & SetStrat --> PlanCtx[Planner Context]
    end

    %% 快速通道出口 (Stream B 熔断)
    FastPath --> StateUpdater[直接更新状态] --> Response

    subgraph Mnemosyne [Data Engine]
        State[State Chain]
        Hist[History Chain]
        Event[Event Chain]
        Narr[Narrative Chain]
        Lore[RAG Chain]
    end

    subgraph Jacquard [Orchestration Layer]
        %% Stream A: Deterministic
        subgraph AutoStream [Stream A: Automation (Skeleton)]
            Render[Template Renderer]
            ActiveEventFilter[Active Event Filter]
        end
        
        %% Stream B: Probabilistic
        subgraph FlashStream [Stream B: Curation (Flesh)]
            Retriever[Hybrid Retriever]
            Curator[Context Curator (FlashLLM)]
        end
        
        Assembler[Skein Assembler]
        FinalPrompt[Final Skein]
    end

    %% Flow A: Deterministic Projection
    PlanCtx -->|Template & Goal| Render
    State --> Render
    Hist --> Render
    Event -->|Status=Active| ActiveEventFilter --> Render
    
    %% Flow B: Probabilistic Curation
    PlanCtx -->|Search Intent & Focus| Retriever
    UserInput --> Retriever
    Lore --> Retriever
    Narr --> Retriever
    Event -->|Status=Completed| Retriever
    
    Retriever -->|Candidates (Top-50)| Curator
    Curator -->|Selected IDs (Top-5)| Assembler
    
    Render --> Assembler
    Assembler --> FinalPrompt
    
    Response[Client Response]
```

---

## 3. 规划器集成 (Phase 0: Planner Integration)

Planner (Pre-Flash) 是系统的**前额叶皮层**，它在上下文构建之前执行高阶认知控制。

### 3.1 核心职责
1.  **意图分流 (Triage)**: 识别“数值操作”意图，直接熔断 Stream B，避免不必要的 RAG 和 FlashLLM 调用（成本控制）。
2.  **聚焦管理 (Focus)**: 确定当前对话的“战术焦点” (Topic/Quest)，为 Stream B 提供精准的检索锚点。
3.  **策略选型 (Strategy)**: 选择 Skein 模板，决定 Stream A 的渲染逻辑和 Stream B 的检索权重。

### 3.2 数据流：PlanContext
Planner 产生的战术决策通过 `PlanContext` 对象传递给后续流。

```typescript
interface PlanContext {
  activeQuestId: string | null; // 聚焦的任务
  current_goal: string;         // 当前回合战术目标 (给 Stream A)
  templateId: string;           // 策略模板 ID (给 Stream A & B)

  // 搜索意图 (给 Stream B)
  search_intent: {
    enabled: boolean;           // 是否启用 Stream B (Triage 结果)
    focus_keywords: string[];   // 关键实体 (e.g., ["Iron Sword", "Blacksmith"])
    temporal_context: "now" | "past" | "future";
    domain_weight: {            // 指导 Hybrid Retriever 的权重分配
      narrative: number;        // e.g., 0.8 (回忆权重)
      lore: number;             // e.g., 0.2 (设定权重)
      event: number;            // e.g., 0.5 (任务权重)
    };
  };
}
```

---

Mnemosyne 的 **多维上下文链** 将被严格分配到不同的流水线中，以确保逻辑的一致性。

| 上下文链 (Chain) | 属性 | 处理流 (Stream) | 机制 | 目的 |
| :--- | :--- | :--- | :--- | :--- |
| **1. State Chain** | 结构化数值 (VWD) | **Stream A (Auto)** | Jinja2 渲染 | 提供当前客观状态 (HP, Inventory, Locations)。 |
| **2. History Chain** | 线性对话 | **Stream A (Auto)** | 窗口裁剪 | 提供连贯的短期对话上下文，确保“刚才说了什么”绝对准确。 |
| **3. Planner Context** | 规划状态 | **Stream A (Auto)** | 直接注入 | 维持长线目标 (`current_goal`)，并作为指令指导 Main LLM。 |
| **4. Event Chain** | 逻辑节点 | **混合 (Hybrid)** | 状态判断 | **Active**: 走 Auto 流，显示在任务列表。<br>**Completed**: 走 Flash 流，作为历史参考。 |
| **5. Narrative Chain** | 文本摘要 | **Stream B (Flash)** | FlashLLM 筛选 | 提供长时记忆与剧情背景，解决“很久以前发生的事”。 |
| **6. RAG Chain** | 向量片段 | **Stream B (Flash)** | 向量检索 + 筛选 | 提供静态的世界观知识 (Lore)。 |

---

此流产生的内容对应 Prompt 中的 **System Instruction** 和 **Chat History** 区域。

### 5.1 处理逻辑
*   **输入**: 数据库中的最新快照 + `PlanContext`。
*   **处理**: 使用由 `PlanContext.templateId` 指定的 Jinja2 模板，将 JSON 数据转换为 XML/Markdown。
*   **特点**: 零延迟，零幻觉，强指令性。

### 5.2 输出示例 (Prompt Block)

遵循 `Filament` 协议的 **XML+YAML** 标准，并实施 **ID 锚点策略** 以优化 Token 效率和防止深层路径丢失。

```xml
<context_layer type="deterministic">
  <!-- 状态面板: 使用 XML 定义边界，YAML 描述数据 -->
  <status>
    health: 85 (受伤状态)
    location: 低语森林 - 外部
    inventory:
      # 容器锚点: main_bag
      main_bag:
        _anchor: "bag_main"
        items:
          - { id: "item_sword_01", name: "Iron Sword", count: 1 }
          - { id: "item_potion_02", name: "Healing Potion", count: 2 }
  </status>
  
  <!-- 活跃任务: 列表结构用 YAML 非常清晰 -->
  <active_quests>
    - id: q_001
      status: in_progress
      objective: 找到森林神庙的入口
      progress: 已找到 2/3 个符文
  </active_quests>
  
  <!-- 规划指导 -->
  <guidance>
    current_goal: 引导玩家发现神庙入口的线索
  </guidance>
</context_layer>
```

### 5.3 状态扁平化与锚点管理 (State Flattening & Anchor Management)

为了解决深层嵌套 YAML 导致的路径提取困难（LLM 容易忘记父级上下文），系统实施 **非对称上下文策略 (Asymmetric Context Strategy)**。

#### 5.3.1 Input: ID Anchoring
在输入的 YAML 中，为所有 **可修改实体 (Entities)** 和 **可添加容器 (Containers)** 注入唯一标识符（`id` 或 `_anchor`）。

*   **Entity Anchor**: 如 `id: "item_sword_01"`
*   **Container Anchor**: 如 `_anchor: "bag_main"`

#### 5.3.2 Output: Flat Path JSON
在输出的修改指令中，LLM **必须** 使用基于锚点的扁平路径。

*   ❌ **禁止**: `SET character.inventory.main_bag.items[0].count = 0` (易错)
*   ✅ **推荐 (修改)**: `["SET", "item_sword_01.count", 0]` (基于 Entity ID)
*   ✅ **推荐 (新增)**: `["PUSH", "bag_main", { "name": "Apple" }]` (基于 Container Anchor)

---

## 6. Stream B: 策展构建流 (Curation Detail)

**Stream B** 是一条与 Stream A 并行的 **概率性流水线**。它的核心目标是从海量的冷数据（Lore, Old Narratives, Completed Events）中，筛选出对当前对话最具有“语义价值”的 Top-K 条目，并注入到 Prompt 的浮动窗口中。

### 6.1 架构组件 (Components)

Stream B 由 `Jacquard` 中的 **Context Curator Plugin** 编排，内部包含三个子模块：

1.  **Hybrid Retriever (混合检索器)**: 接收 Planner 的 `search_intent`，负责从 Mnemosyne 的不同链中粗筛出候选集 (Recall Phase)。
2.  **Flash Selector (FlashLLM 选择器)**: 利用轻量级 LLM (Gemini 1.5 Flash / GPT-4o-mini) 进行精排 (Re-rank/Selection Phase)。
3.  **Injector (注入器)**: 将最终选中的条目转换为 `Floating Block` 并注册到 Skein。

### 6.2 第一阶段：混合召回 (Phase 1: Hybrid Recall)

在 Planner 的指导下，Retriever 不再盲目搜索，而是进行**目标导向召回**。

*   **输入**: 用户最新消息 + **Planner Context (Focus & Keywords)**。
*   **机制**: `QueryGen` 模块会将 Planner 提供的 `focus_keywords` 与用户输入合并，生成高精度的查询向量。
*   **输出**: 约 50 个候选条目 (Candidate Items)。

| 数据源 (Source) | 检索策略 (Strategy) | Planner 增强作用 |
| :--- | :--- | :--- |
| **RAG Chain** | **Vector Similarity** | 使用 `search_intent.domain_weight.lore` 调整权重；使用 `focus_keywords` 增强 Query。 |
| **Narrative Chain** | **Recency-weighted Keyword** | 如果 `temporal_context` 为 "past"，大幅提升此链权重。 |
| **Event Chain** | **Graph Traversal** | 优先检索与 `activeQuestId` 关联的前置或后续任务节点。 |

#### 6.2.1 候选条目数据结构 (Candidate Item Structure)
为了节省 FlashLLM 的 Token，召回阶段仅提取摘要信息。

```json
{
  "id": "lore_entry_052",
  "type": "lore",
  "source": "rag_chain",
  "content_preview": "森林神庙：位于低语森林深处的古代遗迹...", // 截断至 100 tokens
  "metadata": {
    "score": 0.85, // 向量相似度或关键词匹配度
    "tags": ["location", "ancient"]
  }
}
```

### 6.3 第二阶段：智能筛选 (Phase 2: Flash Selection)

即使有了 Planner 的关键词指导，向量检索仍然可能召回“语义相关但上下文无关”的噪声（Recall 高，Precision 低）。FlashLLM 在此作为**精准过滤器**。

*   **Why Needed?**: Planner 负责“圈定范围”，FlashLLM 负责“去伪存真”。
*   **模型选择**: Gemini 1.5 Flash, GPT-4o-mini, Haiku 3。
*   **任务定义**: 这是一个 **判别式任务 (Discriminative Task)**，而非生成式任务。

#### 6.3.1 Prompt 设计 (The Selector Prompt)

```xml
<system_instruction>
You are the Context Curator System.
Your task is to select the most relevant information from the "Candidate Pool" to help the AI answer the "User Input".

Rules:
1. Select at most 5 items.
2. Prioritize items that directly explain proper nouns or entities in the User Input.
3. Prioritize recent narrative events if the user is asking about "what happened".
4. Return ONLY a JSON list of selected IDs.
</system_instruction>

<user_context>
  <recent_history>
    AI: 听说村长有一把钥匙。
  </recent_history>
  <current_input>
    那把钥匙是不是开启神庙的？我记得之前提到过。
  </current_input>
</user_context>

<candidate_pool>
  <item id="lore_01">神庙钥匙：传说中开启森林神庙的唯一信物...</item>
  <item id="narrative_105">Summary: 玩家在第10轮对话中拒绝了村长的请求...</item>
  <item id="event_03">Completed Quest: 寻找失落的项链...</item>
  ... (up to 50 items)
</candidate_pool>
```

#### 6.3.2 输出处理
FlashLLM 返回：`["lore_01", "narrative_105"]`。
如果超时或失败，系统将回退到 **Heuristic Fallback**（直接取 Vector Search 的 Top-3）。

### 6.4 第三阶段：注入与编织 (Phase 3: Injection & Weaving)

一旦 ID 被确定，Context Curator 会向 Mnemosyne 请求这些 ID 的**完整内容**（不再是摘要），并将其封装为 Skein 的 `Floating Block`。

#### 6.4.1 注入策略 (Injection Strategy)

这些块会被标记为 `probabilistic` 类型，Skein Assembler 会根据配置将它们插入到 Prompt 的合适位置（通常是 Chat History 之前，或者 System Prompt 的底部）。

```python
# 伪代码：构建浮动块
for item_id in selected_ids:
    full_content = mnemosyne.fetch(item_id)
    
    block = PromptBlock(
        content=full_content.text,
        role="system",
        source="curation",
        injection_config={
            "position": "relative_to_history",
            "depth": 0, // 紧贴历史记录上方
            "priority": 10
        }
    )
    skein.add_floating_block(block)
```

### 6.5 性能与并发 (Performance & Concurrency)

为了确保用户体验，Stream B 必须与 Stream A (Automation) **并发执行**。

1.  **并行启动**: 在 Phase 0 (Planner) 完成后，Stream A (本地规则计算) 和 Stream B (网络请求/FlashLLM) 同时启动。
    *   *Note*: 如果 Planner 决定熔断 Stream B (Triage=Numerical)，则仅启动 Stream A。
2.  **竞争机制 (Race Condition Handling)**:
    *   Stream A 通常极快 (<50ms)。
    *   Stream B 较慢 (~500ms - 1s)。
    *   **策略**: Jacquard 会等待 Stream B 完成，设定一个 **硬超时 (Hard Timeout, e.g. 1.5s)**。
    *   **超时处理**: 如果 Stream B 超时，本次回复将仅使用 Stream A 的上下文（保证响应速度），并在后台继续完成 Stream B 的处理，将结果缓存供下一轮使用（**预取策略**）。

### 6.6 Filament 协议映射

最终生成的 XML 结构示例：

```xml
<!-- Stream B 的产物 -->
<context_layer type="probabilistic" model="gemini-1.5-flash">
  <rationale>User asked about 'Key' and 'Temple'. Selected relevant lore and past conversation.</rationale>
  
  <knowledge_base>
    <entry id="lore_01" type="item">
      <name>神庙钥匙</name>
      <desc>由翡翠雕刻而成的古老钥匙，表面流动着微光。</desc>
    </entry>
  </knowledge_base>

  <relevant_memories>
    <memory id="narrative_105" turn="10">
      玩家在被问及是否愿意帮助寻找钥匙时，表现出了犹豫。
    </memory>
  </relevant_memories>
</context_layer>
```

---

## 7. 最终 Skein 结构 (Final Prompt Structure)

Assembler 将两部分合并，形成最终发送给 Smart Model 的 Prompt。

```xml
<root>
  <system>
    You are an AI assistant...
    
    <!-- Stream A: 坚固的骨架 -->
    {{ automation_block }}
    
    <!-- Stream B: 丰富的血肉 -->
    {{ curation_block }}
  </system>

  <chat_history>
    <!-- Stream A: 线性历史 -->
    {{ history_block }}
  </chat_history>
  
  <user_input>
    {{ user_input }}
  </user_input>
</root>
```
