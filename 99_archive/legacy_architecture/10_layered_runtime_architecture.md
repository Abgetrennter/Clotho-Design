# 第十章：分层运行时环境架构 (Layered Runtime Architecture)

**版本**: 1.0.0
**日期**: 2025-12-30
**状态**: Draft
**作者**: 资深系统架构师 (Architect Mode)
**源文档**: `doc/architecture/00_architecture_panorama.md`

---

## 1. 核心设计哲学 (Core Philosophy)

为了解决传统 AI RPG 客户端（如 SillyTavern）中存在的状态混乱、设定成长与原始数据冲突、以及环境配置耦合严重的问题，Clotho 引入了 **"分层运行时环境 (Layered Runtime Architecture)"**。

这一架构借鉴了游戏引擎的 **"蓝图 (Blueprint) vs 实例 (Instance)"** 以及 Git 的 **"写时复制 (Copy-on-Write)"** 思想，将一个运行中的角色会话解构为四个物理隔离但逻辑叠加的层次。

**核心价值**:
*   **动静分离**: 原始角色卡（蓝图）永远保持只读，确保可以随时重置。
*   **成长性**: 角色可以在特定存档中经历性格突变，而不会污染原始设定。
*   **模版独立**: Prompt 结构（如 ChatML/Alpaca）与角色内容彻底解耦。
*   **平行宇宙**: 支持基于同一角色的无限分支存档。

---

## 2. 四层叠加模型 (The Layered Sandwich)

Clotho 的运行时上下文 (Runtime Context) 是由以下四层数据在内存中动态 **"编织 (Weaving)"** 而成的：

```mermaid
graph TD
    subgraph "Layer 0: Infrastructure (框架层)"
        Preset[Prompt Template / API Config]
        Note0[Read-Only: 定义对话协议与骨架]
    end

    subgraph "Layer 1: Global Context (环境层)"
        GlobalLore[通用世界书 / RPG规则]
        GlobalScript[通用正则 / UI插件]
        Persona[用户设 (Persona)]
        Note1[Read-Only: 跨角色共享，用户级配置]
    end

    subgraph "Layer 2: Character Assets (蓝图层)"
        CardMeta[CCv3 原始数据 (Name, Desc)]
        CharLore[角色专属 Lore]
        CharAssets[立绘 / 背景]
        Note2[Read-Only: 静态不可变，作为工厂蓝图]
    end

    subgraph "Layer 3: Session State (实例层)"
        History[历史记录链]
        StateTree[变量状态树 (VWD)]
        LoreStatus[世界书激活状态]
        Patches[Patch 对 L2 的动态修正]
        Note3[Read-Write: 动态可变，随存档独立]
    end

    Preset -->|Structure| Context
    GlobalLore -->|Inject| Context
    CardMeta -->|Content| Context
    History -->|State| Context
    Patches -.->|Override| CardMeta

    Context[Mnemosyne Context]
```

### 2.1 层级详解

| 层级 | 名称 | 职责 (Responsibility) | 读写权限 | 典型数据内容 |
| :--- | :--- | :--- | :--- | :--- |
| **L0** | **Infrastructure** | **骨架**：定义与 LLM 的通信协议和 Prompt 结构。 | Read-Only | Prompt Template (ChatML/Alpaca), API Settings, Tokenizer Config |
| **L1** | **Global Context** | **环境**：定义跨角色共享的世界规则与用户身份。 | Read-Only | User Persona, Global Lorebooks (D&D Rules), Global UI Scripts |
| **L2** | **Character Assets** | **蓝图**：定义角色的初始设定与固有特质。 | Read-Only | Character Card V3 Data (Name, Desc, First Mes), Base Lorebooks, Assets |
| **L3** | **Session State** | **灵魂**：记录角色的成长、记忆与状态变更。 | **Read-Write** | **Patches**, History Chain, VWD State Tree, Active Lore IDs |

---

## 3. Patching 机制 (The Patching Mechanism)

Patching 是 L3 层的核心特性，它允许运行时状态对 L2 的静态定义进行 **非破坏性修改**。

### 3.1 工作原理

Mnemosyne 在聚合上下文时，执行 **Deep Merge (深度合并)** 操作：

1.  **Base**: 加载 L2 的原始数据对象。
2.  **Apply**: 将 L3 中的 `patches` 字典应用到对象上。
3.  **Result**: 生成用于本次推理的临时对象 (Projected Entity)。

### 3.2 应用场景

*   **属性成长**: 角色从 level 1 升级到 level 99。L3 的 State Tree 更新，不影响 L2。
*   **设定重写**: 剧情导致角色从“修女”黑化为“魔女”。L3 存储一个针对 `description` 字段的 Patch，覆盖 L2 的原始描述。
*   **世界变迁**: 角色摧毁了“新手村”。L3 将 L2 中的“新手村”Lorebook 条目标记为 `enabled: false`，并新增一个 L3 独有的“废墟”条目。

---

## 4. 运行时数据流 (Runtime Data Flow)

当 Jacquard 发起推理请求时，数据流经各层并在 Mnemosyne 中聚合：

```mermaid
sequenceDiagram
    participant J as Jacquard (Orchestrator)
    participant M as Mnemosyne (Data Engine)
    participant L3 as L3 Session
    participant L2 as L2 Blueprint
    participant L0 as L0 Preset

    J->>M: Request Context Snapshot
    M->>L3: Load Session State (History, Patches)
    M->>L2: Load Static Assets
    M->>M: Apply L3 Patches to L2 Assets (Projection)
    M->>L0: Load Prompt Structure
    M->>M: Weave (Structure + Projected Content + History)
    M-->>J: Return Immutable Punchcard
```

---

## 5. 聚合实体：Mnemosyne Context

最终传递给编排层 (Jacquard) 的是一个聚合后的上下文对象，我们称之为 **Mnemosyne Context**。

```typescript
interface MnemosyneContext {
  // Layer 0: 策略与骨架
  infrastructure: {
    preset: PromptTemplate;
    apiConfig: ApiConfiguration;
  };
  
  // Layer 1 & 2 (Projected): 静态引用的投影 (已应用 Patch)
  world: {
    character: ProjectedCharacterData; // L2 + L3 Patch
    globalLore: List<LorebookEntry>;   // L1 + L3 Status
    user: PersonaData;                 // L1
  };

  // Layer 3: 纯动态状态
  session: {
    history: List<Message>;
    stateTree: VWDStateTree;
    activeLoreIds: List<string>;
  };
}
```
