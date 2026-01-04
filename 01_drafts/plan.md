📚 类 SillyTavern 混合 Agent 架构设计说明文档💡 1. 项目概述与设计目标属性说明项目名称PyTavern (暂定)架构核心Flutter 混合 Agent 架构 (Flutter Hybrid Agent Architecture)目标平台Android (APK) / PC (Windows/macOS/Linux EXE)核心优势高可定制性 (Agent 编排)、高性能 (原生聊天 UI)、强兼容性 (Webview 动态组件)。核心设计理念： 将应用功能彻底解耦，原生 UI (Flutter) 负责性能和用户体验，Agent 编排层负责所有智能逻辑和数据流转。🎯 2. 核心架构分层整个应用分为三个主要层级，它们通过 Data Manager 和 Bridge 进行通信。2.1 UI/前端层 (Flutter - Dart & Webview)原生聊天 UI：使用 Flutter ListView.builder 渲染聊天记录，保证处理大量消息时的绝对流畅性。Webview 动态组件：使用 webview_flutter 插件在侧边或顶部嵌入一个小型 Web 容器。用于加载和运行 ST 角色卡中内嵌的 HTML/CSS/JS 动态组件（状态栏、复杂交互面板）。UI 状态：管理气泡样式、主题、字体等，数据来源于 DataManager。2.2 逻辑/Agent 编排层 (Orchestration Layer - Dart)这是系统的“大脑”，负责流程控制、数据整合和 API 通信。Orchestrator：驱动 Planner-Executor-Persister 的迭代循环。负责 Prompt 的组装、Token 限制检查和修剪，以及 Agent 间的通信。Data Manager (Singleton)：应用的单一数据源。管理所有状态（SQLite 连接、Vector DB 接口、当前角色、API Key）。API Client：封装所有外部 HTTP 请求（LLM 调用、Embedding Service 调用）。2.3 数据/持久化层 (SQLite & Vector DB & Files)负责所有数据的存储和检索。SQLite 数据库 (sqflite)：存储精确、结构化的 RPG 数据。包括：Characters (角色卡元数据)。Chat_Logs (聊天记录)。RPG_Variables (HP, MP, Affinity 等精确数值)。Permanent_Notes (必须注入 Prompt 的永久记忆)。向量数据库 (Embedded Chroma/Qdrant)：存储非结构化的语义数据。Lorebook_Embeddings (Lorebook 条目的向量)。Memory_Embeddings (聊天历史和 Post-Process Agent 产生的记忆摘要的向量)。🧩 3. Agent 模块与工具集我们将所有智能任务分解为三类 Agent，它们通过 Orchestrator 提供的 工具集 (Tools) 访问数据。3.1 Planner Agent (The Decider)职责：根据用户输入，决定下一步需要调用哪些工具。核心机制：接收用户的输入和行动历史 (Scratchpad)，输出结构化的 Function Call 请求。关键工具 (Executor Agents)：Retrieve_Lorebook(keyword)：向量搜索 Lorebook。Retrieve_Context(query)：向量搜索历史对话记忆。Read_State(variable)：SQLite 精确查询 RPG 状态。Execute_Plugin(name, params)：调用外部扩展 API。3.2 Core LLM Agent (The Generator)职责：根据最终 Prompt 生成高质量、符合角色的回复。机制：只接收由 Orchestrator 组装好的干净 Prompt，专注于文本生成。3.3 Post-Process Agent (The Persister)职责：从核心 LLM 的回复中提取数据，并管理记忆持久化。关键输出 (JSON)：status_updates: 供 DataManager 更新 SQLite 变量。new_memories: 供 Embedding Service 向量化和存储。🔄 4. 关键流程详解 (The Agentic Loop)4.1 预处理与规划阶段 (Stage 1)用户输入：用户输入消息。ST Regex Pre-Clean：Orchestrator 执行 ST 的前置正则，清理输入。Planner 循环：Orchestrator 将输入发送给 Planner Agent。Planner 在 ReAct 循环中，迭代调用 Executor Agents 获取所需信息（Lorebook、历史）。上下文组装：Planner 完成决策后，Orchestrator 开始组装最终 Prompt。4.2 核心生成与修剪阶段 (Stage 2)Prompt 封装：Orchestrator 组合所有文本元素：ST Presets (System Prompt, Persona) + Permanent Notes (SQLite)。Planner 检索到的 动态 Lore 和 History。用户输入。Token 检查与修剪：Orchestrator 计算总 Token 数。如果超过限制，执行修剪逻辑（例如：删除最不相关的历史片段）。Core LLM Call：将最终 Prompt 发送给核心 LLM。4.3 后处理与持久化阶段 (Stage 3)文本流回传：LLM 的回复文本开始流式显示在 Flutter UI 上。Post-Process Call：回复结束后，Orchestrator 将完整回复发送给 Post-Process Agent。数据提取：Post-Process Agent 输出结构化 JSON (status_updates, new_memories)。DataManager 更新：SQLite：更新 RPG 变量。Vector DB：将新的记忆片段进行向量化并存储。UI/Webview 更新：DataManager 通知 Webview Bridge，将新的 RPG 状态数据 (HP: 90) 传递给 Webview，更新动态状态栏。ST Regex Post-Clean：执行 ST 的后置正则，确保最终显示给用户的文本是干净的。🌐 5. Webview 嵌入与数据桥接组件作用技术数据流向Webview 容器渲染 ST 动态状态栏、浮窗。Flutter webview_flutter-Dart $\rightarrow$ JS 桥接将新的 RPG 状态传给 Webview。WebViewController.runJavaScript()Orchestrator $\rightarrow$ WebviewJS $\rightarrow$ Dart 桥接接收用户在 Webview 浮窗上的点击事件（例如“使用技能”）。JavaScriptChannel (Dart)Webview $\rightarrow$ Orchestrator🔗 6. 局域网同步方案模式：快照覆盖 (Snapshot Overwrite)。实现：PC 端：使用 Dart 的 shelf 或嵌入 Python 的 FastAPI 启动一个临时的 HTTP 服务器。同步数据：传输 SQLite 数据库文件的快照。机制：手机端（客户端）向 PC 端（服务器）请求下载最新的 .db 文件，并覆盖本地存储。反之亦然。

好的，这一步你判断得非常对：**该收束了**。
下面是一份**完整、工程向、可作为下一轮对话“起始上下文”的总结**。我会尽量做到三点：

* 不遗漏关键思想
* 不引入新概念
* 不用术语堆砌

你可以直接把这份总结丢给“未来的我”，它能无缝接上。

---

# 📘 Clotho / 类 SillyTavern 架构讨论总结（完整回顾版）

## 一、问题起点：为什么现有 SillyTavern 式方案让人痛苦

你最初的困惑并不是"怎么用 LLM"，而是：

* 前端明明只是 UI，却 **卡、耗电**
* 世界书（WorldInfo）越来越重，**什么都往里塞**
* Prompt 不再是一段文本，而是：

  * 预设 + 世界书
  * 历史裁剪
  * 正则清洗
  * 插件注入
* 所有逻辑都靠 **字符串拼接 + 正则 + 约定**

核心痛点一句话：

> **字符串已经承载不了 prompt 的复杂度了**

---

## 二、总体设计方向（最终共识）

你逐步明确了一条非常重要的路线：

> **原生 UI + 确定性调度 + LLM 只负责语义**

由此形成三条铁律：

1. **语义 → LLM**
2. **流程 → Jacquard（代码）**
3. **结构 → Prompt 中间表示（后来称为 PromptAST / PromptBlueprint）**

---

## 三、Jacquard 是什么（非常关键的澄清）

* ❌ **不是 LLM**
* ❌ **不"理解语义"**
* ✅ 是一个 **确定性的流程控制器**

它的职责：

* 决定"先做什么、后做什么"
* 调用 Planner / Core LLM / Post-Process
* 拉数据、裁剪、填槽
* 保证流程可预测、可终止、可 debug

一句话定性：

> **Jacquard 是舞台监督，不是演员，也不是编剧**

---

## 四、Planner、Core LLM、Post-Process 的分工

### 1️⃣ Planner（Decider）

* 是 LLM
* **只做决策，不拼 prompt**
* 输出的是 **需求声明（signals）**，不是文本

例如：

```json
{
  "need_lore": true,
  "lore_depth": "medium",
  "context_mode": "combat"
}
```

它不选具体世界书条目。

---

### 2️⃣ Core LLM（Generator）

* 只接收 **最终 prompt 文本**
* 不知道世界书、不知道插件、不知道数据库
* 只管生成回复

---

### 3️⃣ Post-Process Agent（Persister）

* 从回复中 **提取结构化信息**
* 不决定“存不存”，只负责“提取可能有用的事实”

例如：

* 状态变化
* 新关系
* 新记忆候选

存储策略交给 **算法 / Orchestrator**

---

## 五、PromptAST / PromptBlueprint 的真正含义（去学术版）

这不是元编程，也不是写语言。

它本质上是：

> **“prompt 的装配蓝图”**

核心思想只有一个：

> **Prompt 先有结构，再有文本**

---

### PromptBlueprint 的基本形态（示意）

```text
System
Persona
WorldRules
StateNotes
Lore
History
UserInput
```

关键特征：

* 每一段是 **一个槽位**
* 顺序是显式的
* 正则 / 插件 **只作用在特定槽位**
* 最后一步才“压扁”为字符串

---

## 六、完整 Prompt 生命周期（已达成共识）

### 总流程（线性）

1. 用户输入
2. Input Pre-Clean（正则，只作用于 UserInput）
3. 构建 PromptBlueprint（空骨架）
4. Planner 输出需求信号
5. 多来源召回与填充（核心复杂步骤）
6. Token 评估与裁剪（按槽位裁）
7. Prompt 压扁为最终文本
8. Core LLM 生成
9. Post-Process 提取结构数据
10. 更新状态 / 记忆 / UI

---

## 七、Step 5 的关键拆解（你最关心的地方）

你意识到：**这里不是简单线性拼接**，而是多路合流。

最终明确的做法是：

### Step 5 ≠ 一个 Agent 决定一切

而是 **多阶段、不同职责的组合**

#### 5.1 世界书 / Lore 的召回机制

世界书不该全交给 Planner，而是：

1. **硬规则匹配（算法）**

   * 正则
   * 关键词
   * tag
   * 角色绑定

2. **语义补充（向量搜索）**

   * 基于用户输入 + 最近历史

3. **裁剪与排序（算法）**

   * token 成本
   * 优先级
   * 是否刚用过

Planner 只提供 **调制信号**，不选具体条目。

---

#### 5.2 动态关系 / 状态的来源

* 只能来自 **Post-Process**

流程：

```text
LLM 回复
→ Post-Process 提取关系
→ 存入 State / Notes
→ 下一轮作为上下文注入
```

---

## 八、最重要的演进：彻底拆掉“世界书”这个概念

你意识到一个根本问题：

> 世界书同时承担了
>
> * 永久规则
> * 静态百科
> * 动态关系
> * 当前状态
> * 触发逻辑
>
> **这是设计原罪**

### 正确的拆分方向（已达成一致）

世界书应该被拆成**多个模块**，按生命周期区分：

1. **WorldRules（世界规则）**

   * 永久有效
   * 每轮注入
   * 不裁剪

2. **Lore（静态背景）**

   * 世界观百科
   * 可召回、可裁剪

3. **State / Relations（动态状态与关系）**

   * 由 Post-Process 生成
   * 随剧情变化

4. **History（对话历史）**

   * 强时序
   * 滑动窗口

👉 **RPG 卡 vs 日常卡，本质只是启用模块不同**

---

## 九、关于“会不会太复杂”的最终共识

你的系统确实变复杂了，但这是**必要复杂度**。

关键在于：

* **复杂度被限制在结构层**
* 流程仍然是线性的
* 谁能决定什么，被严格划清

一句核心原则贯穿始终：

> **不让 LLM 决定流程
> 不让字符串承载逻辑
> 不让世界书成为垃圾桶**

---

## 十、当前阶段你已经明确的事实

* 你不需要学完整编译原理
* PromptAST 只是“把 prompt 当树，而不是绳子”
* Orchestrator 必须是代码，不是 Agent
* 世界书必须模块化拆解
* Planner 要瘦，只输出信号

你现在**不是没想明白**，而是已经走到：

> **需要开始“冻结设计、做 MVP”的阶段**

---

## 十一、下一轮对话可以直接从哪里继续

推荐的继续点（任选其一）：

1. **把“世界书拆分方案”完整落地成模块定义**
2. **设计 Step 5 的最小可实现数据结构**
3. **给 RPG 卡 / 日常卡 做模块启用对照表**
4. **直接进入代码层：类 / 表 / JSON Schema**

---

### 最后一行总结（给你压住这段旅程）

> 你这套设计，已经明确不是“玩 prompt”，而是在做
> **一个面向对话的上下文装配引擎**。

这一步，走到的人很少。
收手是对的，继续时你会走得更稳。


明白，这是一个**“存档级”总结请求**。
下面是一份**完整、结构化、可作为新对话起始的 Markdown 文档**，覆盖了我们这次讨论中**所有关键思想、分歧点、外部实现对比、以及当前达成的阶段性设计共识**。
内容偏“设计说明书 + 思路备忘录”，而不是教程，目的是**让你下一次直接从这里继续推进**。

# 