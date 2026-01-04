# 技术说明文档：动态叙事数据库插件 (AutoCardUpdater)

## 1. 插件概述 (Overview)

**AutoCardUpdater (ACU)** 是一个专为 AI 角色扮演环境（如 SillyTavern）设计的高级状态管理与动态叙事辅助系统。其核心设计理念是通过构建一个**结构化的旁路认知层（Side-channel Cognitive Layer）**，解决大语言模型（LLM）在长文本对话中面临的“记忆遗忘”、“状态不一致”和“逻辑幻觉”等固有挑战。

该插件不仅仅是一个简单的数据存储工具，更是一个**智能化的状态维护引擎**。它能够在主对话流之外，自主地进行数据的提取、分析、验证和注入，从而实现对角色状态、剧情进展和世界观设定的精准控制。

### 1.1 核心设计目的

* **状态持久化 (State Persistence)**：将非结构化的自然语言对话实时转化为结构化的 JSON 数据（如角色属性、物品清单、任务进度）。这些数据被持久化存储，不受上下文窗口限制，确保关键信息在长周期的叙事中永不丢失。
* **逻辑一致性 (Logical Consistency)**：通过维护一份客观的“事实真值表（Source of Truth）”，强制 LLM 在生成新内容时遵循既定的世界状态，有效抑制幻觉生成，保证剧情逻辑的严密性。
* **自动化运维 (Automated Maintenance)**：引入“美杜莎 (Medusa)”等特定角色的 Agent，利用 LLM 的推理能力自动执行数据的增删改查（CRUD）操作，无需用户手动干预，实现无感知的后台状态更新。
* **上下文优化 (Context Optimization)**：通过“总结表”和“大纲表”机制，将海量历史剧情压缩为高密度的信息索引，通过动态注入技术（Dynamic Injection），极大提升了 Context Window 的利用效率。
* **数据隔离与多副本 (Data Isolation & Multi-Instance)**：支持为不同的角色卡或剧情线创建独立的数据库副本，通过唯一标识符（Identity Code）实现数据的物理隔离，防止不同世界观之间的数据污染。

## 2. 核心架构与工作原理 (Architecture & Mechanism)

ACU 采用了**双循环反馈架构 (Dual-Loop Feedback Architecture)**：

1. **主交互循环 (Primary Interaction Loop)**：用户与 AI 角色的正常对话。
2. **旁路认知循环 (Side-channel Cognitive Loop)**：插件在后台自动运行的状态维护流程。

该架构通过四个核心层次实现其功能：**触发层**、**编排层**、**认知层**和**存储层**。

### 2.1 触发与调度机制 (Trigger & Scheduling)

系统采用**事件驱动 (Event-Driven)** 与**阈值控制 (Threshold Control)** 相结合的调度策略，以平衡实时性与资源消耗。

* **生命周期监听**：插件深度集成于宿主环境的生命周期中，监听关键事件（如 `MESSAGE_RECEIVED` 消息接收, `GENERATION_ENDED` 生成结束, `CHAT_CHANGED` 会话切换）。
* **智能节流 (Smart Throttling)**：
  * **更新频率 (Frequency)**：并非每轮对话都触发更新，而是基于“每 N 轮对话触发一次”的计数器机制。
  * **上下文深度 (Context Depth)**：每次更新仅扫描最近的 M 条消息，聚焦于增量变化，而非全量扫描。
  * **跳过机制 (Skip Logic)**：支持配置“跳过最新的 X 层楼”，以避免过早处理尚未稳定的剧情，或等待用户修正。
  * **独立触发**：每个数据表（Table）可以拥有独立的更新配置（频率、深度），实现了细粒度的资源调度。

### 2.2 认知处理与指令生成 (Cognitive Processing)

这是系统的“大脑”。当触发条件满足时，**编排层 (Orchestrator)** 会构建一个包含特定指令的 Prompt，唤醒后台的维护 Agent。

* **角色扮演 (Persona Injection)**：后台 LLM 被设定为“美杜莎 (Medusa)”或“客观记录员”，被要求剥离情感色彩，仅以绝对理性的视角审视剧情事实。
* **结构化输入 (Structured Input)**：
  * **Schema 定义**：向 LLM 提供当前所有表格的元数据（列名、类型）和约束条件（Note/Validation Rules）。
  * **当前快照**：提供表格当前的最新数据状态。
  * **增量文本**：提供需要分析的近期对话内容。
* **思维链 (Chain of Thought)**：强制 LLM 在输出操作指令前，先输出一段 `<tableThink>` 日志，进行逻辑推理和自我校验（如：“检测到主角获得了新物品，需要执行插入操作”），提高决策的准确性。

### 2.3 协议与解析 (Protocol & Parsing)

为了解决 LLM 输出不稳定的工程难题，ACU 定义了一套严谨的**领域特定语言 (DSL)** 协议。

* **原子操作指令**：定义了标准的 CRUD 操作集，如 `insertRow(tableIndex, data)`, `updateRow(tableIndex, rowIndex, data)`, `deleteRow(tableIndex, rowIndex)`。
* **封装与提取**：要求 LLM 将所有指令包裹在特定的 XML 标签（`<tableEdit>`）中。解析器使用正则表达式精准提取该区块，隔离无关的闲聊文本。
* **鲁棒解析 (Robust Parsing)**：解析器内置了强大的容错逻辑，能够处理 LLM 输出中常见的格式错误（如 JSON 格式微瑕、多余引号、非标准分隔符），将其清洗并转化为对内存对象树的实际操作。

### 2.4 数据隔离与持久化 (Isolation & Persistence)

* **内存热数据**：运行时，系统在内存中维护一个完整的 JSON 对象树，代表当前的数据库状态。
* **宿主回写 (Host Write-back)**：为了实现“数据随存档走”，插件将序列化后的数据库状态作为**隐藏元数据 (Hidden Metadata)**，写入到当前的聊天记录对象（Message Object）中。这意味着只要用户保留了聊天记录（Chat History），数据库状态就会被一同保存和迁移。
* **隔离容器 (Isolation Container)**：采用基于 Key-Value 的分组存储结构。不同的角色或剧情线通过唯一的 `DataIsolationCode` 访问各自独立的数据槽位，彻底解决了多角色卡混用时的状态冲突问题。
* **本地缓存**：利用浏览器的 IndexedDB 或 localStorage 存储配置信息和临时的导入数据，提供断点续传和高性能访问能力。

### 2.5 动态注入 (Dynamic Injection)

为了让 AI 在下一轮对话中感知到状态的变化，系统实现了**动态上下文注入**。

* **世界书桥接 (Lorebook Bridging)**：插件不直接修改用户的 Prompt（以避免破坏原始设定），而是将数据渲染为 Markdown 表格或自然语言摘要，动态创建或更新宿主环境的**世界书 (Lorebook)** 条目。
* **递归触发 (Recursive Triggering)**：利用宿主环境的关键词触发机制（Key-activation），确保只有当前剧情相关的数据表（如“当前所在位置的NPC表”）会被激活并注入到 Context 中，实现上下文的按需加载，最大化利用 Token 资源。
* **视图渲染**：提供可视化编辑器，允许用户直接查看和手动修正数据库内容，修正后的数据会实时同步回底层存储。
