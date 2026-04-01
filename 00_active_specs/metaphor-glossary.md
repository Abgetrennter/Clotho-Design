# Clotho 隐喻体系与术语表 (Clotho Metaphor System & Glossary)

**版本**: 1.3.0
**日期**: 2026-04-02
**状态**: Active

> 完整的技术术语映射参见 [naming-convention.md](naming-convention.md)

---

## 1. 核心隐喻：纺织命运 (Weaving Fate)

Clotho 命名源自希腊神话中的命运三女神之一 **克洛托 (Clotho)**——纺织生命之线的女神。整个系统采用 **"纺织 (Weaving)"** 隐喻体系，将软件架构映射为纺织工艺：

- **Jacquard (提花机)** 读取 **Pattern (织谱)** 的指令，调度 **Shuttle (梭子)** 穿梭往复，将 **Threads (丝络)** 编织进时间的经纬，最终生成独一无二的 **Tapestry (织卷)**。

> 不再将对话视为简单的"消息列表"，而是一幅不断编织、延伸的织卷。

## 2. 术语速查

| 隐喻术语 | 技术术语 | 隐喻原型 |
|---------|---------|---------|
| Clotho | Clotho (整个应用) | 纺织女神 |
| Jacquard | Orchestration Engine | 提花织机 |
| Mnemosyne | Data Engine | 记忆女神 |
| Tapestry | **Session** (会话) | 挂毯 |
| Pattern | **Persona** (角色设定) | 纹板/图样 |
| Threads | **Context** (上下文) | 丝线/经纬 |
| Punchcards | **Snapshot** (快照) | 穿孔卡 |
| Skein | **PromptBundle** (提示词包) | 纱束 |
| Filament | Filament Protocol | 纤维 |
| Shuttle | **Plugin** (插件) | 梭子 |
| Planning Phase | **Pre-Generation** | — |
| Consolidation Phase | **Post-Generation** | — |

## 3. Legacy 概念映射

| 传统概念 | Clotho 概念 | 备注 |
|---------|------------|------|
| Character Card | Pattern → **Persona** | 生成式蓝图 |
| Chat / Session | Tapestry → **Session** | 完整编织物 |
| Message History | Threads → **TurnHistory** | 构成织卷的原材料 |
| World Info | Lore → **Worldbook** | 背景纹理 |
| Save File | Punchcards → **Snapshot** | 状态快照 |
| Prompt Blocks | Skein → **PromptBundle** | 结构化容器 |

> 写代码时，请将隐喻术语"翻译"为 [naming-convention.md](naming-convention.md) 中的技术术语。

---

*最后更新: 2026-04-02*
