# Standard RPG State Schema (VWD) 设计草案

**版本**: 0.1.0
**日期**: 2026-01-15
**状态**: Draft
**作者**: Roo

---

## 1. 核心思想：引擎做容器，L2 定义内容

Clotho 的状态管理遵循“凯撒原则”，即**引擎层 (Mnemosyne) 只提供一个最简的、通用的数据容器**，而具体的业务逻辑和数据结构则下沉到 **L2 层（The Pattern / Schema）去定义**。

- **State Chain 的概念映射**: 在 Clotho 的架构中，用户所提的 "State Chain" 概念对应于 **Mnemosyne State Tree**（基于 VWD 模型）与 **OpLog**（操作日志）的组合。State Tree 负责存储当前世界的快照，而 OpLog 记录了从上一个快照到当前状态的所有变更，共同构成了完整的状态历史。

- **设计决策**: 我们不应该在引擎层硬编码任何具体的 RPG 状态（如 `hp`, `gold`）。引擎的核心职责是高效、确定性地读写一个灵活的、可嵌套的 JSON 树，并应用 Patch。

这种设计的优势在于：
- **通用性**: 同一个 Clotho 引擎可以无缝支持从 D&D（生命值/护甲等级）到赛博朋克（理智/信用点），再到恋爱模拟（好感度/心情）等完全不同的规则体系。
- **可扩展性**: 用户（或 L2 层的设计者）可以自由定义、增删和修改状态，而无需改动底层引擎。
- **LLM 友好**: 通过 VWD (Value-With-Description) 模型，所有状态数据都可以携带自身的语义描述，使大型语言模型能更好地理解和操作这些数据。

---

## 2. 标准 RPG Schema (初步条目设计)

尽管引擎是通用的，但为了促进互操作性和提供“开箱即用”的体验，我们建议在 **协议层 (Protocols/Schemas)** 定义一套 **"标准 RPG 模板" (Standard RPG Schema)**。当用户创建新的 RPG 存档而未提供自定义结构时，系统可默认加载此模板。

以下是基于 VWD 模型设计的 **State Tree 推荐结构**，它应作为 L2 层的 Schema 文件存在（例如 `schemas/extensions/rpg_standard_v1.yaml`），而非引擎代码。

### 2.1 根节点结构

```json
{
  "$meta": {
    "description": "Global State Root for a Standard RPG Session",
    "schemaVersion": "1.0"
  },
  "user": { ... },
  "world": { ... },
  "social": { ... },
  "inventory": { ... },
  "journal": { ... }
}
```

### 2.2 详细设计建议

#### A. 用户状态 (User Persona State)

利用 VWD 的 `[Value, Description]` 元组特性，让数值对 AI 自解释。

```json
"user": {
  "$meta": { "description": "The player character's state." },
  "status": {
    "hp": [100, "Health Points (0 indicates death)"],
    "mp": [50, "Mana or Magic Points for casting spells"],
    "stamina": [100, "Stamina for physical actions"],
    "sanity": [80, "Mental Stability (low values may cause negative effects)"]
  },
  "attributes": {
    "strength": [12, "Strength: Affects physical damage and carrying capacity"],
    "intelligence": [14, "Intelligence: Affects magic power and problem-solving"],
    "dexterity": [13, "Dexterity: Affects speed, evasion, and ranged attacks"]
  },
  "equipment": {
    "main_hand": ["Iron Sword", "A basic one-handed sword granting +5 Attack"],
    "off_hand": [null, "Empty"],
    "armor": ["Leather Tunic", "Light body armor providing +2 Defense"]
  }
}
```

#### B. 社交关系 (Social Graph)

使用嵌套结构动态记录与重要 NPC 和势力的关系。`$meta.extensible: true` 允许在游戏过程中动态添加新的 NPC。

```json
"social": {
  "$meta": {
    "description": "Manages relationships with NPCs and factions.",
    "extensible": true,
    "uiSchema": { "viewType": "card" }
  },
  "npc_seraphina": {
    "affection": [45, "Affection level, influencing dialogue and quests (0-100)"],
    "trust": [80, "Trust level, determining willingness to share secrets"],
    "status": ["Ally", "Current relationship status"],
    "flags": {
      "met_in_tavern": true,
      "knows_player_secret": false
    },
    "current_location": "The Grand Library"
  },
  "faction_iron_hand": {
    "reputation": [-20, "Reputation with this faction (Negative is hostile)"]
  }
}
```

#### C. 世界状态 (World State)

记录游戏世界的时间、地点和探索进度。只存储**状态**和**已探索**信息，而不是整个静态世界地图。

```json
"world": {
  "$meta": { "description": "Current state of the game world." },
  "time": {
    "day": 12,
    "phase": ["Dusk", "Current time of day (e.g., Morning, Noon, Dusk, Night)"]
  },
  "location": {
    "current_node_id": "old_ruins_entrance",
    "current_region": "northern_wastes"
  },
  "explored_nodes": {
    "$meta": {
      "description": "A record of visited locations.",
      "uiSchema": { "viewType": "list" }
    },
    "village_start": { "visited": true, "shops_unlocked": true },
    "old_ruins_entrance": { "visited": true, "cleared": false }
  },
  "global_flags": {
      "dragon_has_awakened": false,
      "is_eternal_night": false
  }
}
```

#### D. 任务与日志 (Quest & Journal)

这部分数据与 `Mnemosyne` 的 `Quest` 系统紧密耦合。State Tree 中主要存储任务相关的**变量**和**标志位**，而任务的静态描述和目标定义在 `Quest` 对象中。

```json
"journal": {
  "$meta": { "description": "Tracks quest progress and related variables." },
  "active_quest_id": "quest_find_holy_grail",
  "quest_vars": {
    "holy_grail_clues_found": 2,
    "dragon_slain": false,
    "has_met_oracle": true
  }
}
```
---

## 3. 实现与应用

1.  **L2 定义 (Definition at L2)**: 在角色卡（Pattern）或世界书（Lorebook）的元数据中，通过 `initial_state` 字段注入上述 JSON 结构作为初始状态。
2.  **Schema 验证与规则注入 (Schema Validation)**: 加载一个标准的 `rpg_standard_v1.yaml` Schema 文件。此文件不仅可以用于验证 State Tree 的结构，更重要的是，它可以向 Jacquard 的 System Prompt 中注入规则，指导 LLM 如何理解和修改这些状态值（例如，“当角色受到火焰攻击时，更新 `user.status.hp` 并可能添加一个 'burning' 状态”）。
3.  **UI 渲染 (UI Rendering)**: 利用 `$meta.uiSchema` 字段，表现层（Presentation Layer）可以动态地、非硬编码地渲染状态栏。例如，将 `hp` 渲染为一个红色进度条，将 `inventory` 渲染为一个带图标的网格视图，而无需前端代码理解每个变量的具体含义。

通过这种方式，我们构建了一个既灵活又强大的状态管理系统，完美契合 Clotho 的设计哲学。
