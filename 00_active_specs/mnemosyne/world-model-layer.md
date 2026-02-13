# 完整世界模型层设计 (World Model Layer)

**版本**: 1.0.0
**日期**: 2026-02-13
**状态**: Draft
**作者**: Clotho 架构团队
**关联文档**: 
- [抽象数据结构设计](./abstract-data-structures.md)
- [SQLite 存储架构](./sqlite-architecture.md)
- [分层运行时架构](../runtime/layered-runtime-architecture.md)

---

## 1. 概述

**世界模型层 (World Model Layer)** 是 Mnemosyne 数据引擎的核心扩展，它将分散的 **Lorebook 条目** 整合为一个**有机的、可交互的、可演化**的世界实体。

### 1.1 设计动机

现有架构中，**Global Lore (L1)** 作为静态知识库存在以下局限：
- 地理空间信息缺乏结构化关联
- 时间线仅体现为回合计数，缺乏语义层级
- 势力关系与经济系统分散在文本条目中
- 社交动态与信息传播缺乏形式化模型

世界模型层通过引入 **World State Graph**，将 RPG 设计理论中的核心概念（地理空间、时间线、势力关系、经济系统）映射为可操作的系统实体。

### 1.2 核心隐喻

| 概念 | 隐喻映射 | 技术定位 |
|------|----------|----------|
| **The World (世界)** | 织卷展开的舞台 | L3 State Tree 中的 `/world` 节点 |
| **Timeline (时间线)** | 命运的编织节奏 | 回合索引 + 游戏内历法 + 叙事节拍 |
| **Location Graph (地理图)** | 舞台的场景布局 | 空间节点与连通关系构成的图 |
| **Faction Web (势力网)** | 舞台上的阵营博弈 | 势力实体与外交关系网络 |
| **Social Graph (社交图)** | 角色间的命运纠缠 | Agent 间的关系边集 |

---

## 2. 架构设计

### 2.1 整体结构

```
┌─────────────────────────────────────────────────────────────────┐
│                      World State Graph                          │
│                    (世界状态统一图模型)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │
│   │   Timeline  │◄──►│   Location  │◄──►│    Agent    │        │
│   │   (时间线)   │    │   (地理图)   │    │   (代理)     │        │
│   └──────┬──────┘    └──────┬──────┘    └──────┬──────┘        │
│          │                  │                  │               │
│          ▼                  ▼                  ▼               │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │              Core State Nodes (核心状态节点)             │  │
│   │  • 节点: Agent, Location, Faction, Item, Event          │  │
│   │  • 边: 空间关系、社交关系、经济关系、时间关系              │  │
│   │  • 属性: VWD 格式的动态状态                               │  │
│   └─────────────────────────────────────────────────────────┘  │
│                              ▲                                  │
│                              │                                  │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │              Dynamic Systems (动态系统层)                │  │
│   │  • Information Flow (信息传播)                           │  │
│   │  • Social Dynamics (社交动态)                            │  │
│   │  • Event Cascade (事件连锁)                              │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 与 L2/L3 的映射关系

| 层级 | 对应概念 | 可变性 | 存储位置 |
|------|----------|--------|----------|
| **L2 (Pattern)** | World Blueprint | 只读 | `patterns` 表 |
| **L3 (Threads)** | World Instance | 读写 | `state_snapshots` + `oplogs` |
| **Runtime** | World Projection | 内存投影 | 运行时对象 |

**状态树路径约定**: `/world/{subsystem}/{entityId}/{property}`

---

## 3. 四大核心子系统

### 3.1 Timeline (时间线系统)

时间线不仅是回合计数器，而是具有语义的多层时间结构。

#### 3.1.1 结构定义

- **Turn Index**: 绝对回合序号，线性递增
- **Game Time**: 游戏内历法时间 (可选)
  - `calendar`: 历法名称
  - `epoch/year/month/day/hour/minute`: 层级时间单位
  - `timeScale`: 每回合对应的游戏时间跨度
- **Narrative Time**: 叙事结构标记
  - `chapter`: 当前章节
  - `arc`: 故事弧
  - `beat`: 叙事节拍
  - `flags`: 活跃故事标记

#### 3.1.2 时段系统 (Time Phase)

支持定义具有不同效果的时段：

```
时段定义示例:
- 黎明 (05:00-07:00): 潜行检定加成
- 深夜 (00:00-04:00): 特定事件触发概率提升
- 血月之夜: 特殊世界状态覆盖
```

**State Tree 路径**: `/world/timeline/...`

---

### 3.2 Location Graph (地理空间系统)

地点不再是简单的字符串标签，而是空间图中的节点。

#### 3.2.1 节点结构

- **Identity**: 唯一标识符、关联的 L2 模板
- **Spatial**: 坐标(可选)、所属区域、生态类型
- **Connections**: 连通关系边集
  - 类型: `path` (路径) / `portal` (传送) / `hidden` (隐藏) / `conditional` (条件)
  - 距离: 旅行所需回合数
  - 通行条件: 钥匙、技能检定等
- **State**: 动态状态 (VWD)
  - `condition`: 地点当前状况
  - `dangerLevel`: 危险等级
  - `population`: 当前人口
  - `resources`: 本地资源储备
- **Occupancy**: 在场实体追踪
  - `agents`: 当前在场的 Agent ID 列表
  - `items`: 放置的物品

#### 3.2.2 图操作

- **路径查找**: 基于约束的最短路径
- **可见范围**: 基于 Agent 感知属性的地点发现
- **实体移动**: 更新位置并触发移动事件

**State Tree 路径**: `/world/locations/{locationId}/...`

---

### 3.3 Faction Web (势力网络系统)

形式化的势力实体与外交关系模型。

#### 3.3.1 势力实体

- **Identity**: 唯一标识符、名称、类型
  - 类型: `government` (政府) / `guild` (公会) / `tribe` (部落) / `cult` (教派) / `family` (家族)
- **Attributes**: 势力属性 (VWD)
  - `power`: 影响力
  - `wealth`: 经济实力
  - `territory`: 控制地点列表
  - `ideology`: 核心理念
- **Membership**: 成员关系
  - `leaderId`: 领袖 Agent
  - `members`: 成员及其地位映射
  - `hierarchy`: 等级制度定义

#### 3.3.2 外交关系

- **Stance**: 立场类型
  - `ally` (同盟) / `neutral` (中立) / `hostile` (敌对)
  - `vassal` (附庸) / `suzerain` (宗主)
- **Strength**: 关系强度 `[-100, 100]`
- **History**: 外交事件历史

#### 3.3.3 与社交图的交互

势力关系作为 **个人关系的初始权重**：
- 同一势力成员: 基础好感度 +20
- 敌对势力成员: 基础好感度 -20

**State Tree 路径**: `/world/factions/{factionId}/...`

---

### 3.4 Economy System (经济系统)

简化的市场与资源流动模型。

#### 3.4.1 核心组件

- **Currencies**: 货币定义与汇率
- **Markets**: 地点绑定的地方市场
  - `prices`: 商品价格 (VWD，动态变化)
  - `supply/demand`: 供需数量
  - `stockpile`: 本地库存
- **Trade Routes**: 贸易路线定义
- **Production Chains**: 生产/消费循环

#### 3.4.2 Agent 经济属性

- **Assets**: 持有资产
  - `currencies`: 现金
  - `inventory`: 物品栏
  - `properties`: 拥有的地点
- **Transactions**: 交易历史
- **Trade Reputation**: 商业信誉 (VWD)

**State Tree 路径**: `/world/economy/markets/{locationId}/...`

---

## 4. 动态系统层

### 4.1 Information Flow (信息传播)

形式化的谣言与新闻传播模型。

#### 4.1.1 信息节点

- **Type**: `rumor` (谣言) / `fact` (事实) / `lie` (谎言) / `secret` (秘密)
- **Content**: 信息内容
- **Known By**: 已知的 Agent 集合
- **Source**: 信息来源 (可选)
- **Credibility**: 可信度 (随传播衰减)
- **Expires At**: 过期时间 (谣言可能自动消散)

#### 4.1.2 传播机制

- **Spread**: 基于社交距离的传播概率
- **Distortion**: 传话游戏效应 (多跳后内容变形)
- **Credibility Decay**: 可信度随时间和距离衰减

**State Tree 路径**: `/world/information/{infoId}/...`

---

### 4.2 Social Dynamics (社交动态)

群体行为与关系演变模拟。

#### 4.2.1 群体氛围

- **Atmosphere**: 地点的情绪氛围聚合
  - 由在场 Agent 的情绪状态加权计算
  - 影响新入场 Agent 的初始情绪

#### 4.2.2 关系演变

- **Decay**: 长期不互动导致关系淡化
- **Bonding**: 共同经历强化关系
- **Conflict**: 冲突事件损害关系

---

### 4.3 Event Cascade (事件连锁)

事件触发的因果链机制。

#### 4.3.1 事件定义

- **Trigger**: 触发条件
- **Effect**: 直接效果
- **Cascade**: 连锁反应
  - 延迟: `delay` (回合数)
  - 概率: `probability`
  - 子事件: 递归触发

#### 4.3.2 示例连锁

```
玩家偷窃 (Turn 10)
  └─► 守卫发现失窃 (Turn 11, prob: 0.7)
        ├─► 发布通缉令 (Turn 12)
        │     └─► 所有城市守卫对 Player 态度 → hostile
        └─► 商人提高警戒 (Turn 13, prob: 0.5)
              └─► 本地市场价格上涨 20%
```

---

## 5. 与现有系统的集成

### 5.1 与 Lorebook 4-Quadrant 的重映射

| Quadrant | 原注入策略 | 世界模型锚定 | 增强策略 |
|----------|-----------|-------------|----------|
| **Axiom** | System Chain | `world.timeline.calendar` | 基于游戏内时间生效 |
| **Agent** | Floating Chain (浅层) | `world.agents.{id}` | 基于在场状态与社交距离 |
| **Encyclopedia** | Floating Chain (深层) | `world.locations.{id}` | 基于距离与访问历史分层 |
| **Directive** | User Anchor | `world.factions.{id}.ideology` | 基于势力立场动态调整 |

### 5.2 与 Scheduler 的协作

世界模型事件可作为调度触发器：

- **World Time**: 特定游戏内时间触发
- **Location State**: 地点状态变化触发
- **Faction Stance**: 势力关系变化触发
- **Information Spread**: 信息传播到特定 Agent 触发

### 5.3 与 Social Graph 的整合

**双层社交模型**:

```
Layer 1: Personal Relations (Agent-Agent)
  └─ Alice ──[好感度 70]──► Bob

Layer 2: Faction Relations (Faction-Faction)
  └─ 骑士团 ──[hostile]──► 暗影会

Composite: 通过势力推导个人关系
  └─ Alice(骑士团) 对 Bob(暗影会) 初始权重: -20
```

---

## 6. State Tree 结构示例

```json
{
  "$meta": { "description": "世界状态根节点" },
  "world": {
    "$meta": { 
      "description": "完整世界模型",
      "extensible": true
    },
    
    "timeline": {
      "turnIndex": 42,
      "gameTime": {
        "calendar": "艾欧泽亚历",
        "year": 1572, "month": 6, "day": 15, "hour": 22
      },
      "narrative": {
        "chapter": "暗影之逆焰",
        "arc": "逃离水晶塔",
        "flags": ["crystal_tower_unlocked"]
      }
    },
    
    "locations": {
      "loc_tavern": {
        "state": {
          "condition": ["crowded", "人声鼎沸"],
          "dangerLevel": [2, "安全"]
        },
        "occupancy": {
          "agents": ["char_alice", "char_bob"],
          "items": ["item_mysterious_letter"]
        },
        "connections": [
          { "target": "loc_market", "type": "path", "distance": 2 }
        ]
      }
    },
    
    "agents": {
      "char_alice": {
        "locationId": "loc_tavern",
        "socialGraph": {
          "char_bob": { 
            "affinity": [75, "战斗友谊"], 
            "trust": [60, "信任"] 
          }
        },
        "factionStanding": {
          "faction_knights": { "rank": "captain", "loyalty": [90, "忠诚"] }
        }
      }
    },
    
    "factions": {
      "faction_knights": {
        "attributes": { "power": [80, "势力强大"] },
        "relationships": [
          { "target": "faction_cult", "stance": "hostile", "strength": -80 }
        ]
      }
    },
    
    "information": {
      "rumor_king_murder": {
        "type": "rumor",
        "knownBy": ["char_alice", "char_bob"],
        "credibility": [0.6, "可信度一般"]
      }
    }
  }
}
```

---

## 7. 实现路线图

| 阶段 | 功能 | 优先级 | 依赖 |
|------|------|--------|------|
| Phase 1 | Timeline 系统 (基础回合 + 游戏内时间) | 高 | 现有 State Tree |
| Phase 2 | Location Graph (地点 + 连接关系) | 高 | Phase 1 |
| Phase 3 | Agent Social Graph (个人关系网络) | 高 | Phase 2 |
| Phase 4 | Faction Web (势力关系) | 中 | Phase 3 |
| Phase 5 | Economy System (基础市场) | 中 | Phase 2 |
| Phase 6 | Information Flow (信息传播) | 低 | Phase 3 |
| Phase 7 | Event Cascade (事件连锁) | 低 | Phase 1-4 |

---

## 8. 与 KiMi 建议的对应关系

| KiMi 指出的盲区 | 世界模型层的解决方案 |
|----------------|---------------------|
| "世界"概念薄弱 | 引入 World 作为独立实体，整合 Timeline/Location/Faction/Economy |
| 地理空间缺失 | Location Graph 提供结构化空间模型 |
| 时间线/日历缺失 | Timeline 系统的 Game Time 层级 |
| 势力关系缺失 | Faction Web 的形式化外交模型 |
| 经济系统缺失 | Economy System 的市场与资源流动 |
| 社交维度缺失 | Social Graph + Information Flow 的双层社交模型 |
| 信息传播缺失 | Information Flow 的谣言/新闻传播机制 |
