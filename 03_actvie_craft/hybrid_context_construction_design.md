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

在 `Jacquard` 流水线中，`Skein Builder` 将被重构为双流并行结构，最终在 `Assembler` 阶段汇聚。

```mermaid
graph TD
    subgraph Mnemosyne [Data Engine]
        State[State Chain]
        Hist[History Chain]
        Event[Event Chain]
        Narr[Narrative Chain]
        Lore[RAG Chain]
    end

    subgraph Jacquard [Orchestration Layer]
        User[User Input]
        
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
    State --> Render
    Hist --> Render
    Event -->|Status=Active| ActiveEventFilter --> Render
    
    %% Flow B: Probabilistic Curation
    User --> Retriever
    Lore --> Retriever
    Narr --> Retriever
    Event -->|Status=Completed| Retriever
    
    Retriever -->|Candidates (Top-50)| Curator
    Curator -->|Selected IDs (Top-5)| Assembler
    
    Render --> Assembler
    Assembler --> FinalPrompt
```

---

## 3. 多维链网映射 (Chain-Stream Mapping)

Mnemosyne 的 **多维上下文链** 将被严格分配到不同的流水线中，以确保逻辑的一致性。

| 上下文链 (Chain) | 属性 | 处理流 (Stream) | 机制 | 目的 |
| :--- | :--- | :--- | :--- | :--- |
| **1. State Chain** | 结构化数值 (VWD) | **Stream A (Auto)** | Jinja2 渲染 | 提供当前客观状态 (HP, Inventory, Locations)。 |
| **2. History Chain** | 线性对话 | **Stream A (Auto)** | 窗口裁剪 | 提供连贯的短期对话上下文，确保“刚才说了什么”绝对准确。 |
| **3. Planner Context** | 规划状态 | **Stream A (Auto)** | 直接注入 | 维持长线目标 (`current_goal`) 和待办 (`pending`)。 |
| **4. Event Chain** | 逻辑节点 | **混合 (Hybrid)** | 状态判断 | **Active**: 走 Auto 流，显示在任务列表。<br>**Completed**: 走 Flash 流，作为历史参考。 |
| **5. Narrative Chain** | 文本摘要 | **Stream B (Flash)** | FlashLLM 筛选 | 提供长时记忆与剧情背景，解决“很久以前发生的事”。 |
| **6. RAG Chain** | 向量片段 | **Stream B (Flash)** | 向量检索 + 筛选 | 提供静态的世界观知识 (Lore)。 |

---

## 4. Stream A: 自动化构建流 (Automation Detail)

此流产生的内容对应 Prompt 中的 **System Instruction** 和 **Chat History** 区域。

### 4.1 处理逻辑
*   **输入**: 数据库中的最新快照。
*   **处理**: 使用预定义的 Jinja2 模板将 JSON 数据转换为 XML/Markdown。
*   **特点**: 零延迟，零幻觉。

### 4.2 输出示例 (Prompt Block)

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

### 4.3 状态扁平化与锚点管理 (State Flattening & Anchor Management)

为了解决深层嵌套 YAML 导致的路径提取困难（LLM 容易忘记父级上下文），系统实施 **非对称上下文策略 (Asymmetric Context Strategy)**。

#### 4.3.1 Input: ID Anchoring
在输入的 YAML 中，为所有 **可修改实体 (Entities)** 和 **可添加容器 (Containers)** 注入唯一标识符（`id` 或 `_anchor`）。

*   **Entity Anchor**: 如 `id: "item_sword_01"`
*   **Container Anchor**: 如 `_anchor: "bag_main"`

#### 4.3.2 Output: Flat Path JSON
在输出的修改指令中，LLM **必须** 使用基于锚点的扁平路径。

*   ❌ **禁止**: `SET character.inventory.main_bag.items[0].count = 0` (易错)
*   ✅ **推荐 (修改)**: `["SET", "item_sword_01.count", 0]` (基于 Entity ID)
*   ✅ **推荐 (新增)**: `["PUSH", "bag_main", { "name": "Apple" }]` (基于 Container Anchor)

---

## 5. Stream B: 策展构建流 (Curation Detail)

**Stream B** 是一条与 Stream A 并行的 **概率性流水线**。它的核心目标是从海量的冷数据（Lore, Old Narratives, Completed Events）中，筛选出对当前对话最具有“语义价值”的 Top-K 条目，并注入到 Prompt 的浮动窗口中。

### 5.1 架构组件 (Components)

Stream B 由 `Jacquard` 中的 **Context Curator Plugin** 编排，内部包含三个子模块：

1.  **Hybrid Retriever (混合检索器)**: 负责从 Mnemosyne 的不同链中粗筛出候选集 (Recall Phase)。
2.  **Flash Selector (FlashLLM 选择器)**: 利用轻量级 LLM (Gemini 1.5 Flash / GPT-4o-mini) 进行精排 (Re-rank/Selection Phase)。
3.  **Injector (注入器)**: 将最终选中的条目转换为 `Floating Block` 并注册到 Skein。

```mermaid
graph TD
    subgraph Input
        User[User Input]
        History[Recent History (3 turns)]
    end

    subgraph "Phase 1: Recall (Hybrid Retriever)"
        QueryGen[Query Expansion]
        
        VectorDB[(RAG Chain - Vector)]
        NarrativeDB[(Narrative Chain - Text)]
        EventDB[(Event Chain - Structure)]
        
        User --> QueryGen
        QueryGen -->|Semantic Search| VectorDB
        QueryGen -->|Keyword/Time-Decay| NarrativeDB
        QueryGen -->|Relation Graph| EventDB
    end

    subgraph "Phase 2: Selection (Flash Selector)"
        CandidatePool[Candidate Pool (Top-50)]
        FlashLLM[Flash Model (e.g. Gemini Flash)]
        
        VectorDB --> CandidatePool
        NarrativeDB --> CandidatePool
        EventDB --> CandidatePool
        
        User --> FlashLLM
        History --> FlashLLM
        CandidatePool -->|JSON List| FlashLLM
        
        FlashLLM -->|Selected IDs (Top-5)| SelectedIDs[ID List]
    end

    subgraph "Phase 3: Injection (Injector)"
        Mnemosyne[Mnemosyne Engine]
        Skein[Skein Builder]
        
        SelectedIDs -->|Fetch Full Content| Mnemosyne
        Mnemosyne -->|Render Blocks| Skein
    end
```

### 5.2 第一阶段：混合召回 (Phase 1: Hybrid Recall)

为了避免单一向量检索的盲区，Retriever 采用多路召回策略。

*   **输入**: 用户最新消息 + 最近数轮 AI 回复。
*   **输出**: 约 50 个候选条目 (Candidate Items)。

| 数据源 (Source) | 检索策略 (Strategy) | 典型内容 | 目的 |
| :--- | :--- | :--- | :--- |
| **RAG Chain** | **Vector Similarity (Cosine)** | 世界观设定、物品描述、专有名词解释 | 回答 "What is X?" 类问题。 |
| **Narrative Chain** | **Recency-weighted Keyword** | 过去的剧情摘要 (Summary) | 回忆 "我们上次在村子里做了什么？" |
| **Event Chain** | **Graph Traversal / Tag Match** | 已完成的任务 (Completed Quests)、关系里程碑 | 检查前置条件或引用旧成就。 |

#### 5.2.1 候选条目数据结构 (Candidate Item Structure)
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

### 5.3 第二阶段：智能筛选 (Phase 2: Flash Selection)

这是 Stream B 的核心创新点。我们不依赖死板的阈值过滤，而是将“判断权”交给一个快速、廉价的 FlashLLM。

*   **模型选择**: Gemini 1.5 Flash, GPT-4o-mini, Haiku 3。
*   **任务定义**: 这是一个 **判别式任务 (Discriminative Task)**，而非生成式任务。

#### 5.3.1 Prompt 设计 (The Selector Prompt)

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

#### 5.3.2 输出处理
FlashLLM 返回：`["lore_01", "narrative_105"]`。
如果超时或失败，系统将回退到 **Heuristic Fallback**（直接取 Vector Search 的 Top-3）。

### 5.4 第三阶段：注入与编织 (Phase 3: Injection & Weaving)

一旦 ID 被确定，Context Curator 会向 Mnemosyne 请求这些 ID 的**完整内容**（不再是摘要），并将其封装为 Skein 的 `Floating Block`。

#### 5.4.1 注入策略 (Injection Strategy)

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

### 5.5 性能与并发 (Performance & Concurrency)

为了确保用户体验，Stream B 必须与 Stream A (Automation) **并发执行**。

1.  **并行启动**: 收到用户消息瞬间，Stream A (本地规则计算) 和 Stream B (网络请求/FlashLLM) 同时启动。
2.  **竞争机制 (Race Condition Handling)**:
    *   Stream A 通常极快 (<50ms)。
    *   Stream B 较慢 (~500ms - 1s)。
    *   **策略**: Jacquard 会等待 Stream B 完成，设定一个 **硬超时 (Hard Timeout, e.g. 1.5s)**。
    *   **超时处理**: 如果 Stream B 超时，本次回复将仅使用 Stream A 的上下文（保证响应速度），并在后台继续完成 Stream B 的处理，将结果缓存供下一轮使用（**预取策略**）。

### 5.6 Filament 协议映射

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

## 6. 最终 Skein 结构 (Final Prompt Structure)

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
