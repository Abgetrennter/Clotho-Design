# Clotho 与 Agent Skills 集成分析报告

## 1. 概念映射 (Concept Mapping)

我们将 `Agent Skills` 的核心概念映射到 Clotho 的现有架构中，以评估其兼容性：

| Agent Skills 概念 | Clotho 对应概念 / 集成点 | 备注 |
|-------------------|--------------------------|------|
| **Skill Folder (技能文件夹)** | `World Expansion Pack` (世界扩展包) / `Gameplay Module` (玩法模块) | 可以作为 zip 文件或 git 子模块分发，包含特定玩法的全部资源。 |
| **SKILL.md (元数据部分)** | `Manifest.yaml` / `Registry` (插件注册表) | Clotho 需要结构化的元数据来供“插件/Mod 管理器”识别和加载。 |
| **SKILL.md (指令部分)** | `Schema Definition` (Schema 定义) + `Skein Block` | **核心调整**: 指令不应是散乱的文本，而应引用 `Schema Library` 中定义的标准协议。 |
| **scripts/ (脚本目录)** | `QuickJS / LuaJIT Scripts` | **关键调整**: 标准 Agent Skills 使用 Python/Bash，这在 Clotho 中是不安全的。我们必须限制使用内部沙箱环境 (QuickJS)。 |
| **references/ (参考资料)** | `Lorebook / World Info` | 可以映射为 Mnemosyne 的 RAG 检索库或静态知识库。 |
| **Progressive Disclosure (渐进式披露)** | `Pre-Flash Triage` -> `Dynamic Injection` (意图分流 -> 动态注入) | Clotho 的 Pre-Flash 机制天然支持这种“按需加载”的理念，非常契合。 |

## 2. 战略契合度分析

### 优势 (为什么采用?)
1.  **标准化 (Standardization)**: 目前 Clotho 中的“游戏机制”（如钓鱼、合成、决斗）往往是散乱的脚本或复杂的 Prompt 注入。Agent Skills 提供了一个清晰的标准目录结构。
2.  **可移植性 (Portability)**: 允许在不同的“宇宙”或“角色”之间共享游戏机制。一个角色可以通过简单地挂载文件夹来“学会”某项技能。
3.  **模块化 (Modularity)**: 将“能力 (Capabilities)”与“人格 (Character Card)”解耦。
4.  **性能优化 (Progressive Disclosure)**: 完美契合 Clotho 的 Token 优化目标。只有当用户说“我抛出鱼竿”时，系统才会加载“钓鱼手册”的 Prompt，避免上下文浪费。

### 挑战 (需要解决的问题)
1.  **安全模型不匹配**: Agent Skills 假设一个受信任的执行环境（通常是本地机器，有权访问文件系统和网络）。Clotho 是一个严格受控的 RPG 引擎。
    *   *解决方案*: 重新定义 `scripts/` 目录规范，仅允许 Clotho 内部协议调用 (Filament) 或沙箱化 JS。
2.  **协议冗余**: Agent Skills 倾向于在 `SKILL.md` 中用自然语言定义交互。Clotho 已经有严格的 `Filament Protocol` 和 `Schema Library`。
    *   *解决方案*: **强制要求 Skill 使用 `<use_protocol>` 标签引用现有的 Schema，而不是重新发明轮子。**

## 3. 集成架构设计 (修订版)

### 3.1 新增 Jacquard 插件: `SkillResolver`
*   **位置**: 位于 `Pre-Flash` (意图规划) 之后，`Skein Builder` (Skein 构建) 之前。
*   **执行逻辑**:
    1.  `Pre-Flash` 识别用户意图 (例如: "Combat" / "Crafting")。
    2.  `SkillResolver` 查询当前激活的技能列表，寻找匹配该意图的技能。
    3.  加载对应技能目录下的 `SKILL.md`。
    4.  **Schema 解析 (关键步骤)**:
        *   扫描 `SKILL.md` 中的 `<use_protocol src="schema_id" />` 标签。
        *   从 `00_active_specs/protocols/schema-library.md` 或本地 Schema 库中加载对应的 YAML 定义。
        *   将 Schema 的 `instruction` 和 `examples` 自动注入到 Prompt 中。
    5.  将 `scripts/` 下的逻辑脚本挂载到 QuickJS 运行时环境中。

### 3.2 文件结构调整 (Clotho 适配版)
建议采用如下结构：

```
my-rpg-skill/
├── SKILL.md          # 包含元数据、以及对 Schema 的引用 (<use_protocol>)
├── scripts/
│   └── logic.js      # QuickJS 逻辑脚本 (严禁 Python/Bash)
├── schemas/          # (可选) 自定义 Schema 定义，如果不想用标准库的话
│   └── custom_fishing.yaml 
├── assets/
│   ├── ui_templates/ # Jinja2 UI 模板 (用于生成 Filament <ui> 标签)
│   └── images/       # 技能相关图片资源
└── data/
    └── items.yaml    # RPG 物品/数据定义 (符合 VWD 模型)
```

### 3.3 SKILL.md 示例 (结合 Schema)

```markdown
---
name: fishing-system
description: 当用户尝试钓鱼或靠近水域时激活。
---

# Fishing Skill

## Protocol Usage
<!-- 引用标准物品交互协议，无需重复写 Prompt -->
<use_protocol src="std.interaction.item_usage" />
<!-- 引用自定义的钓鱼小游戏协议 -->
<use_protocol src="./schemas/fishing_minigame.yaml" />

## Game Logic
当收到 <fishing_result> 标签时，请调用 `scripts/fishing_logic.js` 计算获得的鱼类。
```

## 4. 最终建议

**结论: 采纳并深度集成 (ADOPT & INTEGRATE)**

1.  **保留目录结构**: 使用 Skill 的文件夹结构来组织玩法模块。
2.  **强制 Schema 引用**: `SKILL.md` 不应包含大量的自然语言 Prompt，而应作为 **Schema 的粘合剂**。它主要负责声明“我需要用到哪些协议”。
3.  **Filament 优先**: 所有交互必须通过 Filament 协议完成，Skill 仅负责定义新的标签或扩展现有标签的语义。
