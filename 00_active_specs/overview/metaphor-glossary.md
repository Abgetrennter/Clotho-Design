# Clotho 隐喻体系与术语表 (Clotho Metaphor System & Glossary)

**版本**: 1.0.0  
**日期**: 2026-01-10  
**状态**: Active  
**作者**: 资深系统架构师 (Architect Mode)  

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

在后续文档和代码注释中，应优先使用新术语：

*   ✅ "Load the **Pattern** into memory." (将织谱加载到内存)
*   ✅ "Save the current **Tapestry**." (保存当前织卷)
*   ✅ "Apply a patch to the **Threads**." (对丝络应用补丁)
