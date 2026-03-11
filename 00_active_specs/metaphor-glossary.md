# Clotho 隐喻体系与术语表 (Clotho Metaphor System & Glossary)

**版本**: 1.2.0
**日期**: 2026-03-11
**状态**: Active
**作者**: 资深系统架构师 (Architect Mode)

---

## 📖 阅读指南：双术语体系说明

Clotho 项目采用**双术语体系**，本文档与 [`naming-convention.md`](naming-convention.md) 各司其职：

| 场景 | 使用本文档 (隐喻体系) | 使用 naming-convention.md (技术体系) |
|-----|---------------------|----------------------------------|
| **架构设计文档** | ✅ 优先使用隐喻术语，保持概念形象化 | 可作为补充参考 |
| **代码实现** | ❌ 不要直接使用隐喻术语作为变量名 | ✅ 必须使用技术语义术语 |
| **用户界面** | 可选（适合面向普通用户） | ✅ 推荐（适合面向开发者） |
| **对外交流** | ✅ 向非技术背景人员解释 | ✅ 向开发者解释技术实现 |

### 快速映射示例

| 隐喻术语 (本文档) | 技术术语 (naming-convention.md) | 代码变量示例 |
|------------------|-------------------------------|-------------|
| Tapestry (织卷) | **Session** (会话) | `final session = await getSession(id);` |
| Pattern (织谱) | **Persona** (角色设定) | `final persona = session.persona;` |
| Threads (丝络) | **Context** (上下文) | `final context = session.context;` |
| Punchcards (穿孔卡) | **Snapshot** (快照) | `final snapshot = await createSnapshot(id);` |
| Skein (绞纱) | **PromptBundle** (提示词包) | `final bundle = await assemblePrompt(id, input);` |

> 💡 **简单规则**：写代码时，请将本文档中的隐喻术语"翻译"为 [`naming-convention.md`](naming-convention.md) 中的技术术语。

---

## 1. 核心隐喻：纺织命运 (Weaving Fate)

Clotho 项目的命名源自希腊神话中的命运三女神之一 **克洛托 (Clotho)**，她是负责纺织生命之线的女神。受此启发，整个系统采用了一套完整的 **"纺织 (Weaving)"** 隐喻体系，将复杂的软件架构映射为直观的纺织工艺。

### 1.1 核心理念

> **"以织谱 (Pattern) 为魂，以时间为线，编织而成的命运织卷 (Tapestry)。"**

我们不再将对话视为简单的“消息列表”，而是视为一幅不断编织、延伸的 **"织卷 (Tapestry)"**。
*   **Jacquard (提花机)** 读取 **Pattern (织谱)** 的指令。
*   它调度 **Shuttle (梭子)** 穿梭往复。
*   将 **Threads (丝络)** 编织进时间的经纬。
*   最终生成独一无二的 **Tapestry (织卷)**。

---

## 2. 术语定义表 (Glossary)

### 2.1 系统组件 (System Components)

| 术语 (EN) | 术语 (CN) | 隐喻原型 | 技术定义 |
| :--- | :--- | :--- | :--- |
| **Clotho** | **Clotho** | 纺织女神 | **整个应用系统**。它是用户交互的载体，是命运发生的场所。 |
| **Jacquard** | **Jacquard** | 提花织机 | **编排引擎 (Orchestration Layer)**。系统的核心调度器，负责解析指令、组装 Prompt、调用 LLM 并处理响应。它像提花机一样，精确控制每一步编织。 |
| **Mnemosyne** | **Mnemosyne** | 记忆女神 | **数据引擎 (Data Engine)**。系统的存储中枢，负责管理状态快照、历史记录和知识检索。它不仅仅是存储，更是"动态投影"的生成者。 |
| **Shuttle** | **梭子** | 织机梭子 | **功能单元 / 插件**。Jacquard 流水线中的具体执行模块（如 `Planner`, `Renderer`, `Invoker`）。它们在流水线上穿梭，完成特定任务。 |

### 2.2 数据实体 (Data Entities)

| 术语 (EN) | 术语 (CN) | 隐喻原型 | 架构层级 | 技术定义 |
| :--- | :--- | :--- | :--- | :--- |
| **The Tapestry** | **织卷** | 挂毯/织物 | **Top Level**<br>(Instance) | **运行时实例 (Runtime Instance)**。它是用户感知的“一个存档”或“一段人生”。它是由静态定义的 Pattern 和动态演进的 Threads 共同编织而成的完整实体。包含了历史、状态和设定。 |
| **The Pattern** | **织谱** | 纹板/图样 | **L2 Layer**<br>(Blueprint) | **静态定义集 (Static Definition)**。曾称为 "Character Card"。它是一组指令、模具或基因。它定义了织卷的风格、世界观、逻辑规则和初始状态。它是只读的 (Read-Only)。 |
| **The Threads** | **丝络** | 丝线/经纬 | **L3 Layer**<br>(State) | **动态状态流 (Dynamic State)**。它是在编织过程中不断加入的、改变织卷走向的变量、状态 Patch 和历史记录。它是可变的 (Read-Write)。 |
| **Punchcards** | **穿孔卡** | 提花织机穿孔卡 | **Snapshot**<br>(Serialization) | **世界状态快照 (World State Snapshot)**。它是织卷 (Tapestry) 在特定冻结时刻的静态切片。用于序列化、保存进度及恢复上下文。(参见: Mnemosyne) |
| **Skein** | **绞纱** | 纱束 | **Pipeline Obj** | **结构化容器 (Structured Container)**。Jacquard 处理过程中的临时数据载体，包裹了 Prompt 的各个部分（System, User, History），等待被编织（渲染）成最终文本。 |
| **Filament** | **纤丝** | 纤维 | **Protocol** | **交互协议 (Interaction Protocol)**。连接各组件的标准化数据格式（XML+YAML/JSON），如同一根根强韧的纤维，贯穿系统始终。 |

### 2.3 流程阶段 (Process Phases)

| 术语 (EN) | 术语 (CN) | 旧术语 (Legacy) | 定义 |
| :--- | :--- | :--- | :--- |
| **Planning Phase** | **规划阶段** | Pre-Flash | **生成前 (Pre-Generation)** 的战术规划阶段。由 `Planner` 组件执行，负责分析用户意图、更新关注点 (Focus)、查询相关知识，并决定"本轮聊什么"。 |
| **Consolidation Phase** | **整合阶段** | Post-Flash | **生成后 (Post-Generation)** 的记忆整合阶段。由后台 Worker 异步执行，负责对本轮产生的对话和事件进行摘要、提取、并存入长期记忆 (Vector DB)，实现从短期工作记忆到长期记忆的巩固。 |

---

## 3. 概念映射 (Concept Mapping)

为了方便从旧体系（如 SillyTavern）迁移，提供以下映射对照：

| 传统概念 (Legacy) | Clotho 新概念 (New Metaphor) | 备注 |
| :--- | :--- | :--- |
| **Character Card (角色卡)** | **The Pattern (织谱)** | 强调其作为"生成式蓝图"的本质，包含角色、世界书、正则、UI等复杂结构。 |
| **Chat / Session (对话)** | **The Tapestry (织卷)** | 强调其作为"完整编织物"的整体性，包含 Pattern 的投影和运行时的演变。 |
| **Message History (历史)** | **Threads (丝络)** | 强调其作为构成织卷的原材料。 |
| **World Info (世界书)** | **Lore / Texture (纹理)** | Pattern 的一部分，为织卷提供背景纹理。 |

---

## 4. 引用规范

### 4.1 架构文档中的隐喻术语

在架构设计文档、设计图和概念说明中，**优先使用隐喻术语**以保持概念的形象化：

*   ✅ "Load the **Pattern** into memory." (将织谱加载到内存)
*   ✅ "Save the current **Tapestry**." (保存当前织卷)
*   ✅ "Apply a patch to the **Threads**." (对丝络应用补丁)
*   ✅ "Execute the **Planning Phase** logic." (执行规划阶段逻辑)

### 4.2 代码实现中的技术术语

**重要**：在代码实现中，请切换到 [`naming-convention.md`](naming-convention.md) 定义的技术语义术语：

*   ✅ `final session = await dataEngine.getSession(id);`
*   ✅ `final persona = session.persona;`
*   ✅ `final bundle = await assembler.assemble(sessionId, input);`
*   ✅ `await dataEngine.updateState(sessionId, patches);`

完整的技术术语对照表请参见：[`naming-convention.md`](naming-convention.md#7-概念映射对照表)

---