# 项目设计现状与详细介绍文档

**版本**: 1.0.0  
**日期**: 2026-01-10  
**状态**: Generated  
**基准**: `@/00_active_specs/` (Single Source of Truth)

---

## 1. 项目概览 (Executive Summary)

### 1.1 背景与痛点

Clotho 项目的诞生旨在解决当前 AI 角色扮演（RPG）客户端（以 SillyTavern 为代表）面临的根本性挑战。现有方案普遍存在以下痛点：

* **性能瓶颈**：基于 Web 技术栈，在长文本渲染和内存管理上存在先天劣势，随着对话长度增加，性能呈指数级衰减。
* **逻辑混沌**：逻辑处理（Scripting）与界面表现（UI）高度耦合，且过度依赖不稳定的 LLM 进行逻辑判断。
* **时空错乱**：在频繁的回溯（Undo）、重绘（Reroll）与分支（Branching）操作中，上下文状态容易失去一致性。

### 1.2 核心愿景与定位

Clotho 定位为一个**高性能、跨平台、确定性与沉浸感并存**的次世代 AI RPG 客户端。

* **技术栈**：摒弃 Web 架构，拥抱 **Flutter** 生态，实现 Windows、Android 等多端的原生高性能体验。
* **核心价值**：通过严格的架构分层，实现“逻辑升级不破坏界面，界面重构不影响逻辑”的稳健系统。

### 1.3 设计哲学：凯撒原则 (The Caesar Principle)

项目遵循核心设计哲学 **"Hybrid Agency"（混合代理）**，具体体现为 **凯撒原则**：

> **"Render unto Caesar the things that are Caesar's, and unto God the things that are God's."**
> **(凯撒的归凯撒，上帝的归上帝)**

* **凯撒的归凯撒 (Code's Domain)**：逻辑判断、数值计算、状态管理、流程控制。这些必须由确定性的代码（Jacquard/Mnemosyne）严密掌控，**绝不外包给 LLM**。
* **上帝的归上帝 (LLM's Domain)**：语义理解、情感演绎、剧情生成、文本润色。这是 LLM 的“神性”所在，系统应让其专注于此，不被琐碎的计算任务干扰。

---

## 2. 系统架构与设计理念 (System Architecture & Design Philosophy)

### 2.1 整体架构图景

Clotho 采用严格的三层物理隔离架构，各层通过明确的协议交互：

* **表现层 (The Stage)**：负责可视化的像素渲染与用户交互，**无业务逻辑**。
* **编排层 (The Loom - Jacquard)**：系统的“大脑”，负责确定性的流程编排与 Prompt 组装。
* **数据层 (The Memory - Mnemosyne)**：系统的“海马体”，负责数据的存储、检索与动态快照生成。
* **基础设施 (Infrastructure)**：基于依赖倒置 (DIP) 的跨平台底座，提供统一的硬件访问与总线服务 (ClothoNexus)。

### 2.2 运行时架构：织卷模型 (The Tapestry)

运行时环境被解构为 **"织卷编织模型 (Tapestry Weaving Model)"**，包含四个逻辑层次（L0-L3）：

1. **L0 Infrastructure (骨架)**：Prompt Template (ChatML/Alpaca)、API 配置。
2. **L1 Environment (环境)**：用户 Persona、全局 Lorebook。
3. **L2 The Pattern (织谱)**：即传统的“角色卡”，定义角色的初始静态设定（只读）。
4. **L3 The Threads (丝络)**：记录角色的成长、记忆与状态变更（读写）。

**核心机制：Patching (写时复制)**
L3 层通过 **Patching** 机制对 L2 层进行非破坏性修改。角色的成长（如属性提升、设定变更）存储为 L3 的补丁，而不修改 L2 的原始文件，从而支持基于同一角色的无限“平行宇宙”存档。

---

## 3. 功能模块与详细规格 (Functional Modules & Specifications)

### 3.1 Jacquard 编排层 (The Loom)

Jacquard 是一个插件化的流水线执行器 (Pipeline Runner)。

* **流水线机制**：包含 Planner (意图规划)、Skein Builder (上下文构建)、Template Renderer (Jinja2 渲染)、Invoker (LLM 调用)、Parser (协议解析) 等标准插件。
* **Skein (绞纱)**：一种异构容器，取代传统的字符串拼接。它模块化地管理 System Prompt、History、Lore 等内容，支持动态裁剪与排序。
* **Jinja2 宏系统**：集成 Jinja2 引擎，支持在 Prompt 组装阶段进行安全的逻辑控制（如条件渲染），实现了“晚期绑定 (Late Binding)”。

### 3.2 Mnemosyne 数据引擎

Mnemosyne 超越了静态存储，是一个**动态上下文生成引擎**。

* **多维上下文链**：
  * **History Chain**：线性对话记录。
  * **State Chain**：基于 **VWD (Value with Description)** 模型的 RPG 状态树，支持 `[Value, Description]` 结构，兼顾程序计算与 LLM 理解。
  * **Event Chain**：关键剧情节点。
* **快照机制 (Punchcards)**：根据时间指针 (Time Pointer) 瞬间生成任意时刻的世界状态快照，支持无损的时间回溯 (Undo/Redo)。
* **元数据控制 ($meta)**：支持多级模板继承、细粒度删除保护和访问控制 (ACL)。

### 3.3 Muse 智能服务

MuseService 是系统的智能中枢，采用分层治理模型：

* **Layer 1: Raw Gateway (透明网关)**：为 Jacquard 提供直通底层的 LLM 访问，不做任何处理，确保编排层的绝对控制权。
* **Layer 2: Agent Host (Agent 宿主)**：为 UI 组件、导入向导等提供开箱即用的 Agent 能力，内置上下文管理和技能系统（如代码转换、联网搜索）。

### 3.4 The Stage 表现层

* **Hybrid SDUI (混合驱动 UI)**：
  * **Native Track**：使用 Flutter/RFW 渲染高性能官方组件。
  * **Web Track**：使用 WebView 渲染复杂的第三方动态内容（如 HTML 状态栏），确保生态兼容性。
* **Stage & Control 布局**：区分沉浸式对话区 (Stage) 与控制台 (Control)，采用响应式三栏设计适配 Desktop/Mobile。
* **Inspector**：提供基于 Schema 的数据可视化调试工具。

### 3.5 Filament 协议体系

Filament 是系统的通用交互语言，消除了自然语言与机器指令的模糊地带。

* **设计原则**：**非对称交互**。
  * **Input (Prompt)**: **XML + YAML**。利用 XML 构建骨架，YAML 描述数据，降低 Token 消耗。
  * **Output (Instruction)**: **XML + JSON**。利用 XML 标识意图（如 `<thought>`, `<content>`），JSON 描述严格参数（如 `<variable_update>`, `<tool_call>`）。
* **标签体系**：包含 `<status_bar>`, `<choice>`, `<ui_component>` 等标签，支持富交互。

### 3.6 工作流：织谱导入与迁移

* **策略**：深度分析 -> 双重分诊 -> 专用通道。
* **分诊机制**：将世界书分为基础/指令/代码三类，将正则脚本分为替换/清洗/UI注入三类。
* **处理**：EJS 代码自动转换为 Jinja2，复杂 HTML 脚本封装至 WebView 沙箱。

---

## 4. 当前设计进度评估 (Current Design Maturity Assessment)

基于 `@/00_active_specs/` 中的文档状态与版本号进行评估：

| 模块 | 版本 | 状态 | 成熟度评估 | 备注 |
| :--- | :--- | :--- | :--- | :--- |
| **Filament 协议** | v2.3.0 | Draft | 🟢 **高** | 协议定义详尽，输入输出格式已定型，覆盖了核心交互需求。 |
| **Muse 智能服务** | v3.0.0 | Draft | 🟢 **高** | 架构迭代至第三版，网关与 Agent 分层设计清晰，职责明确。 |
| **导入与迁移工作流** | v2.1.0 | Active | 🟢 **高** | 分诊策略和处理流程已细化，具备实操性。 |
| **运行时架构** | v1.1.0 | Draft | 🔵 **中** | L0-L3 分层与 Patching 机制逻辑自洽，但具体的数据结构细节需验证。 |
| **Jacquard 编排层** | v1.0.0 | Draft | 🔵 **中** | 流水线与插件化架构已确立，Skein 容器设计合理。 |
| **Mnemosyne 数据引擎** | v1.0.0 | Draft | 🔵 **中** | 概念先进（VWD, 快照），但 SQLite 具体 Schema 实现细节待补充。 |
| **表现层 (Stage)** | v1.0.0 | Draft | 🟡 **初级** | 核心布局与 Hybrid SDUI 概念已出，但组件库细节待完善。 |
| **基础设施** | v1.0.0 | Draft | 🟡 **初级** | 跨平台通信策略已定，ClothoNexus 总线设计已出。 |

**TBD (待定) 项目**:

1. **Mnemosyne**: SQLite 的具体表结构设计与索引策略。
2. **Infrastructure**: 具体的依赖注入 (DI) 容器选型与实现细节。
3. **Stage**: 具体的 UI 组件库规范与 Design Tokens。

---

## 5. 下一步计划 (Next Steps)

基于当前设计现状，建议采取以下行动：

1. **原型验证 (Proof of Concept)**：
    * 优先实现 **MuseService** (Raw Gateway) 与 **Jacquard** 的核心流水线，跑通 "Prompt -> LLM -> Filament Parser" 的最小闭环。
    * 构建 **Mnemosyne** 的 MVP 版本，验证 VWD 数据模型与快照机制的性能。

2. **协议固化**：
    * 基于 Filament v2.3 编写测试用例，涵盖各种边缘情况，确保解析器的鲁棒性。

3. **UI 框架搭建**：
    * 搭建 Flutter 项目骨架，实现 Infrastructure 层的依赖倒置接口。
    * 实现 ClothoNexus 事件总线，打通 UI 与逻辑层的通信。

4. **数据迁移工具开发**：
    * 开发导入向导的核心分析引擎，对现有 SillyTavern 角色卡进行大规模测试，验证分诊策略的有效性。
