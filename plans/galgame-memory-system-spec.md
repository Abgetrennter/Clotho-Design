# Galgame 特化记忆系统设计规范 (Galgame Specialized Memory System Spec)

**版本**: 1.0.0
**日期**: 2026-01-03
**状态**: Draft
**基于**: Clotho v2.x Architecture, Mnemosyne Data Engine, Filament Protocol v2.1

---

## 1. 核心理念：双层混合事件模型与动态作用域 (Core Philosophy)

传统的 LLM 记忆系统通常一视同仁地对待所有交互（全部向量化或全部作为历史）。在 Galgame 场景中，这种做法效率低下且破坏沉浸感。
本系统引入 **双层混合事件模型 (Dual-layer Hybrid Event Model)**，将交互分为两类处理：

1.  **数值化交互 (Numerical Interactions)**:
    *   **特征**: 高频、重复、低叙事密度（如摸头、送礼、日常问候）。
    *   **处理**: 实时转化为数值（VWD）变更，**不进入长期叙事记忆**。短期内作为对话上下文存在，随着 Context Window 滑动自然消失。
    *   **目的**: 避免“摸头 x 100”污染长期记忆库，同时通过数值（好感度、心情）长久影响角色行为。

2.  **事件化交互 (Event-based Interactions)**:
    *   **特征**: 低频、高叙事密度、关键剧情节点（如约会、吵架、告白）。
    *   **处理**: 结构化为 **Global Events** 或 **Character Logs**，永久存储并支持 RAG 检索。
    *   **目的**: 确保关键剧情点能被准确回忆和引用。

同时，引入 **动态作用域 (Dynamic Scopes)** 与 **ACL**，解决多女主场景下的“记忆隔离”与“信息共享”问题。

---

## 2. 数据架构 (Data Architecture)

### 2.1 混合存储结构

Mnemosyne 的存储层将被扩展为以下三个核心区域：

#### A. Global Event Table (全局事件表)
用于存储对世界状态或多角色关系产生重大影响的客观事实。

*   **存储格式**: 结构化 JSON/SQL
*   **Schema**:
    ```json
    {
      "event_id": "evt_date_aquarium_01",
      "timestamp": 1735920000,
      "type": "plot_point",
      "participants": ["player", "alice"],
      "location": "aquarium",
      "summary": "Player and Alice went to the aquarium. Alice saw a penguin for the first time.",
      "outcome": {
        "alice_affinity": "+15",
        "global_flag": "aquarium_visited"
      },
      "tags": ["date", "wholesome"]
    }
    ```

#### B. Character Private Logs (角色私有日志)
用于存储角色的主观记忆、情感反应和私密想法。

*   **存储格式**: 向量数据库 (Vector DB) + 元数据
*   **Schema**:
    ```json
    {
      "log_id": "log_alice_001",
      "owner": "alice",
      "linked_event_id": "evt_date_aquarium_01", // 可选关联全局事件
      "content": "The penguins were so cute! I want to go again with him...", // 主观描述
      "emotion_tags": ["happy", "excited"],
      "access_control": {
        "scope": "private", // 仅自己可见
        "condition": null
      }
    }
    ```

#### C. VWD State Tree (数值状态树)
用于存储高频交互的累积结果。

*   **存储格式**: Mnemosyne VWD Tree
*   **示例**:
    ```json
    "affinity": [85, "High affection, in love"],
    "mood": [10, "Ecstatic"],
    "interaction_stats": {
      "headpat_count": 523,
      "gift_count": 12
    }
    ```

### 2.2 记忆作用域与访问控制 (ACL)

为了处理多角色互动的复杂性（如：A 知道 B 喜欢主角，但 B 不知道 A 知道），我们定义了严格的 ACL。

| 作用域 (Scope) | 定义 | 可见性规则 | 典型应用 |
| :--- | :--- | :--- | :--- |
| **Global (全局)** | 公开的事实 | 所有角色、系统旁白可见 | 天气、公共场所发生的事件 |
| **Shared (共享)** | 特定群体共享 | 仅 `participants` 列表中的角色可见 | 两人约会、三人修罗场 |
| **Private (私有)** | 角色内心独白 | 仅 Owner 可见 | 日记、内心独白、未表露的情感 |
| **Conditional (条件)** | 需满足特定条件 | 满足 `condition` (如好感度 > 90) 可见 | 只有在亲密关系下才回忆起的往事 |

**Condition 逻辑示例**:
```javascript
// ACL Check Pseudo-code
function canAccessMemory(actor, memory) {
  if (memory.scope === 'global') return true;
  if (memory.scope === 'private' && memory.owner !== actor.id) return false;
  if (memory.scope === 'shared' && !memory.participants.includes(actor.id)) return false;
  
  // 条件可见性检查
  if (memory.condition) {
    if (!evaluateCondition(actor, memory.condition)) return false;
  }
  return true;
}
```

---

## 3. 运行时逻辑 (Runtime Logic)

### 3.1 Pre-Flash: 意图分流与动态 Prompt (Intent Triage)

为了优化延迟和 Token 消耗，系统在 Main LLM 之前引入一个轻量级的 **Flash LLM (Pre-Flash)** 节点。

#### 3.1.1 职责
*   **Intent Classification**: 识别用户意图等级。
*   **Schema Selection**: 动态挂载所需的 Function Schema。
*   **Directive Injection**: 向 Main LLM 注入强效指令。

#### 3.1.2 分流等级 (Triage Levels)

| 等级 | 标识 | 典型场景 | Prompt 策略 | 挂载 Schema |
| :--- | :--- | :--- | :--- | :--- |
| **L1** | `ROUTINE` | 摸头、送礼、早安、短语互动 | **Minimal**: 仅保留人设核心，强制短回复 | `update_vwd` |
| **L2** | `CHAT` | 闲聊、询问看法、普通对话 | **Standard**: 标准对话历史 + 状态 | `update_vwd`, `expression` |
| **L3** | `EVENT` | 约会邀请、冲突、地点移动、关键抉择 | **Full**: 完整 Lorebook + 详细 RAG | `record_event`, `trigger_flag` |

#### 3.1.3 Pre-Flash 输出示例
```json
{
  "intent": "headpat_loop",
  "level": "ROUTINE",
  "reasoning": "User is performing repetitive affection action.",
  "directives": {
    "style": "short_cute",
    "forbidden_topics": ["complex_philosophy", "past_trauma"]
  }
}
```

### 3.2 Main LLM: 执行与生成 (Execution)

Main LLM 接收经过 Pre-Flash 选择注入的上下文和明确指令，专注于生成回复和 Filament 标签。

#### 场景 1: 摸头 (数值化路径 - L1 Routine)
1.  **用户输入**: `*摸摸头* 乖哦~`
2.  **Pre-Flash 指令**: `Level: ROUTINE. Action: Headpat. Update affinity only.`
3.  **Main LLM 响应**:
    ```xml
    <thought>日常互动。好感度+1。</thought>
    <state_update>
      [
        {"op": "add", "path": "character.affinity", "value": 1},
        {"op": "replace", "path": "character.mood", "value": "happy"}
      ]
    </state_update>
    <reply>嘿嘿...好痒...</reply>
    ```

#### 场景 2: 约会 (事件化路径 - L3 Event)
1.  **用户输入**: `*带你去水族馆看企鹅*`
2.  **Pre-Flash 指令**: `Level: EVENT. New Location: Aquarium. Enable Event Recorder.`
3.  **Main LLM 响应**:
    ```xml
    <thought>关键剧情：水族馆约会。记录事件。</thought>
    <record_event>
      <type>date</type>
      <summary>和主角去了水族馆，看到了企鹅。</summary>
      <participants>player, alice</participants>
    </record_event>
    <reply>哇！企鹅！它们走路好可爱！</reply>
    ```

### 3.3 Post-Flash: 记忆整合 (Consolidation)

为了减轻 Main LLM 的负担，复杂的记忆归档工作由后台的 **Post-Flash LLM** 异步完成。

#### 3.3.1 触发机制
*   **Buffer Full**: 当短期记忆缓冲区 (Context Window) 即将溢出时。
*   **Session End**: 用户结束会话或长休时。
*   **Manual Trigger**: 剧情节点结束时。

#### 3.3.2 整合任务
1.  **Log Consolidation**: 读取缓冲区内的 N 条原始对话。
2.  **Event Extraction**: 提取 Main LLM 可能遗漏的微小剧情点。
3.  **Reflection**: 生成角色的私有日志 (Character Private Log)。
4.  **Vectorization**: 将生成的 Event 和 Log 向量化并存入 Mnemosyne。

#### 3.3.3 输出示例 (Reflection)
```json
// Generated by Post-Flash LLM
{
  "log_id": "log_daily_summary_1024",
  "type": "reflection",
  "content": "今天他带我去了水族馆。虽然只是看着企鹅发呆，但感觉很安心。也许...我可以试着更依赖他一点？",
  "mood_shift": { "trust": "+5" },
  "tags": ["aquarium", "penguin", "reflection"]
}
```

### 3.4 动态检索：RAG Filter (Retrieval)

当构建 Prompt 时，Mnemosyne 执行带 ACL 的 RAG 检索。

1.  **Context Analysis**: 分析当前对话上下文，提取关键词 (Key Terms)。
2.  **Candidate Retrieval**: 从向量库检索 Top-K 相关记忆片段。
3.  **ACL Filtering**:
    *   遍历候选记忆。
    *   使用 `canAccessMemory(currentCharacter, memory)` 进行过滤。
    *   *例如：Alice 正在说话，过滤掉 Bob 的私有日记，保留 Global Events 和 Alice 的私有记忆。*
4.  **Injection**: 将通过过滤的记忆注入到 Prompt 的 `<relevant_memories>` 区块。

---

## 4. 架构图 (Architecture Diagram)

```mermaid
graph TD
    subgraph Input [输入阶段]
        UserInput[用户输入] --> PreFlash[Pre-Flash (Triage)]
        PreFlash --> |JSON Directive| Jacquard
        Context[上下文摘要] -.-> PreFlash
    end

    subgraph Runtime [运行时编排]
        Jacquard --> |Dynamic Prompt| MainLLM
        MainLLM --> |Filament Stream| Parser
        Parser --> |<state_update>| VWD[VWD 状态树]
        Parser --> |<record_event>| EvtBuf[事件缓冲区]
    end

    subgraph DataEngine [Mnemosyne 记忆引擎]
        EvtBuf --> |Buffer Full/End| PostFlash[Post-Flash (Consolidator)]
        PostFlash --> |Summarize| GlobalEvt[全局事件表]
        PostFlash --> |Reflect| PrivateLog[角色私有日志]
        PostFlash --> |Delayed Update| VWD
        
        GlobalEvt --> |Index| VectorDB
        PrivateLog --> |Index| VectorDB
    end

    subgraph Retrieval [构建上下文]
        VectorDB -.-> |Query| RAG[RAG 检索引擎]
        RAG --> |Filter by ACL| ContextBuilder
        VWD -.-> |Read State| ContextBuilder
        ContextBuilder --> |Assemble| Jacquard
    end

    style PreFlash fill:#ffecb3,stroke:#ff8f00,stroke-width:2px
    style MainLLM fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    style PostFlash fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    style VWD fill:#fff9c4,stroke:#fbc02d
    style VectorDB fill:#e8f5e9,stroke:#2e7d32
```

## 5. 总结

本设计通过区分“数值”与“事件”，完美解决了 Galgame 场景下的核心矛盾：
*   **数值化处理** 保证了高频互动的即时反馈和长远影响，同时避免了 Context 污染。
*   **事件化处理** 保证了关键剧情的铭记。
*   **ACL 机制** 使得多角色互动的逻辑严密，避免了“全知全能”的出戏感。
