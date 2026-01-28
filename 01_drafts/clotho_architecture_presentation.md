# 🧵 Clotho 项目架构深度解析 PPT 大纲
**版本**: Based on Specs v2.x  
**生成日期**: 2026-01-11

---

## 1. 封面页 (Title Slide)
*   **主标题**: Clotho 系统架构深度解析
*   **副标题**: 重塑 AI RPG 的交互体验与逻辑基石
*   **关键标签**: #HighPerformance #Deterministic #Flutter #AgenticRPG
*   **演讲者/部门**: 核心架构组

---

## 2. 愿景与核心痛点 (Vision & Core Pain Points)
### 2.1 Clotho 的定位
*   **定义**: 下一代高性能、跨平台、确定性的 AI 角色扮演客户端。
*   **技术栈**: Flutter (UI) + Rust/Dart (Logic) + Local/Cloud LLM。
*   **目标**: 解决现有 Web 技术栈 (SillyTavern 等) 的根本性架构缺陷。

### 2.2 三大核心痛点 (The "Why")
1.  **性能瓶颈 (Performance)**
    *   *现状*: DOM 节点过多导致长文本渲染卡顿，内存泄漏严重。
    *   *Clotho*: **原生渲染引擎**，即使万行对话也能保持 **60fps 流畅滚动**。
2.  **时空一致性 (Consistency)**
    *   *现状*: 频繁回溯 (Undo)、重绘 (Reroll) 导致变量与剧情状态错乱。
    *   *Clotho*: **多重宇宙树模型 + OpLog**，实现精确的“时间旅行”与分支管理。
3.  **逻辑耦合 (Coupling)**
    *   *现状*: UI 代码中混杂大量业务逻辑，难以维护。
    *   *Clotho*: **三层架构物理隔离** (Stage / Loom / Memory)，遵循 MVU 模式。

---

## 3. 设计哲学 (Design Philosophy)
### 3.1 凯撒原则 (The Caesar Principle)
> "Render unto Caesar the things that are Caesar's, and unto God the things that are God's."

*   **混合代理 (Hybrid Agency)**:
    *   **凯撒的归凯撒 (Code's Domain)**: 逻辑判断、数值计算、状态管理、工具调用。
        *   *原则*: 严禁 LLM 进行 HP 扣减等精确运算。
    *   **上帝的归上帝 (LLM's Domain)**: 语义理解、情感演绎、剧情生成、文本润色。
        *   *原则*: 释放 LLM 的创造力，不被琐碎逻辑束缚。

### 3.2 核心约束 (The "Must-Nots")
*   **UI 无逻辑**: 界面只负责渲染 State，所有操作通过 Intent 发送。
*   **无 eval**: 严禁直接执行 LLM 输出的代码，必须经过 Parser 清洗。
*   **单向数据流**: 状态变更必须统一提交给 Mnemosyne。

---

## 4. 宏观架构全景 (Architecture Panorama)
### 4.1 三大核心生态
1.  **The Stage (表现生态)**:
    *   **职责**: 纯粹的渲染与交互。
    *   **特性**: Flutter 原生 + WebView 混合渲染 (Mini-Apps)。
2.  **The Loom - Jacquard (编排生态)**:
    *   **职责**: 系统的“大脑”与“总线”。
    *   **特性**: 插件化流水线 (Pipeline Runner)，无状态执行。
3.  **The Memory - Mnemosyne (记忆生态)**:
    *   **职责**: 系统的“海马体”与“数据中枢”。
    *   **特性**: 动态上下文生成，负责长期记忆与状态管理。

---

## 5. 深度解析: Jacquard 编排层 (The Loom)
### 5.1 Pipeline 架构
Jacquard 是一个确定性的流水线执行器，包含以下核心插件：
1.  **Pre-Flash (Planner)**: 意图分流。
    *   *数值交互*: 摸头、签到 -> 直接走数值通道 (节省 Token)。
    *   *剧情事件*: 对话、抉择 -> 走 LLM 生成通道。
2.  **Skein Builder**: 上下文组装。
    *   构建 **Skein (绞纱)** 异构容器。
    *   包含 System Chain, History Chain, Floating Chain (World Info)。
3.  **Template Renderer**: 动态渲染。
    *   集成 **Jinja2** 引擎。
    *   执行 `{% if %}` 逻辑，替换 `{{ state.hp }}` 变量。
    *   原则: **Late Binding (晚期绑定)**，渲染发生在发送前的最后一刻。
4.  **Filament Parser**: 协议解析。
    *   实时流式解析 LLM 输出。
    *   分发 `<state_update>` 到 Mnemosyne，`<reply>` 到 UI。

---

## 6. 深度解析: Mnemosyne 数据引擎 (The Memory)
### 6.1 多维上下文链 (Context Chains)
Mnemosyne 将线性存储投影为逻辑上的并行链网：
1.  **History Chain**: 标准对话记录 (Linear)。
2.  **State Chain (Threads)**: RPG 数值状态树 (VWD 模型)。
3.  **Event Chain**: 稀疏的关键节点 (Quest, Relationship Milestones)。
4.  **Narrative Chain**:
    *   **Level 1**: 微观日志 (Micro-Log)。
    *   **Level 2**: 宏观大纲 (Macro-Event / Chapter Summary)。

### 6.2 性能黑科技
*   **稀疏快照 (Sparse Snapshots)**: 强制每 50 轮生成一个 Keyframe，避免 Delta 链过长。
*   **OpLog (操作日志)**: 使用 JSON Patch 记录状态变更，支持精确回滚。
*   **惰性求值 (Lazy Evaluation)**:
    *   `Punchcards` (快照代理对象) 仅在 Jinja2 真正访问变量时才执行 Deep Merge。
    *   大幅降低长 Context 下的 I/O 开销。

---

## 7. 核心数据模型: VWD (Value with Description)
### 7.1 为什么需要 VWD?
解决“数值对 LLM 缺乏语义”的问题。

### 7.2 结构定义
```json
"health": [80, "HP, current health points, 0 means death"]
```
*   **Prompt 视图**: 渲染完整结构，让 LLM 理解 80 代表什么。
*   **UI 视图**: 仅展示 Value (80)。

---

## 8. 统一交互协议: Filament Protocol
### 8.1 协议定位
系统各组件间的通用语言 (Lingua Franca)。

### 8.2 非对称设计 (Asymmetric Interaction)
*   **输入端 (Context Ingestion)**: **XML + YAML**
    *   *优势*: YAML 相比 JSON 更易读，Token 消耗更低，适合大量上下文注入。
*   **输出端 (Instruction Generation)**: **XML + JSON**
    *   *优势*: JSON 语法严格，适合机器解析，确保工具调用 (`<tool_call>`) 和状态更新 (`<state_update>`) 的确定性。

### 8.3 核心标签
*   `<state_update>`: 变更 RPG 状态。
*   `<ui_component>`: 请求渲染嵌入式组件。
*   `<thought>`: 链式思维 (CoT)。

---

## 9. 运行时动态: 分层架构 (Layered Runtime)
### 9.1 四层叠加模型 (The Layered Sandwich)
Clotho 的运行时实例 (**The Tapestry**) 由四层数据叠加而成：
1.  **L0 Infrastructure**: 骨架 (Prompt Template, API Config)。
2.  **L1 Global Context**: 环境 (Persona, Global Lore)。
3.  **L2 The Pattern**: **织谱 (蓝图)** - 原始角色卡数据 (只读)。
4.  **L3 The Threads**: **丝络 (状态)** - 动态补丁与历史 (读写)。

### 9.2 Patching 机制 (写时复制)
*   **原理**: L3 层存储针对 L2 数据的 **Patches (补丁)**。
*   **Deep Merge**: 加载时，Mnemosyne 将 L3 Patches 覆盖在 L2 上，生成 Projected Entity。
*   **价值**:
    *   **非破坏性**: 永远不修改原始角色卡文件。
    *   **平行宇宙**: 同一角色卡可拥有无限个独立的 L3 存档，互不干扰。

---

## 10. 关键工作流: 提示词处理 (Prompt Processing)
### 10.1 完整 Pipeline
1.  **User Input**
2.  **Pre-Flash**: 意图识别 (数值 vs 剧情)。
3.  **Skein Building**: 从 Mnemosyne 获取快照，组装 Block。
4.  **Weaving**: 将 World Info 插入 History Chain 的特定深度。
5.  **Rendering**: Jinja2 渲染，变量替换。
6.  **LLM Invocation**: 发送纯文本 Prompt。
7.  **Parsing**: 解析 XML 标签。
8.  **Post-Flash (Async)**:
    *   日志压缩 (Summarization)。
    *   事件提取 (Event Extraction)。
    *   记忆归档 (Archival)。

---

## 11. 总结与展望 (Conclusion)
### 11.1 Clotho 的核心竞争力
*   **确定性 (Determinism)**: 复杂的 RPG 逻辑由代码保障，而非依赖 LLM 的幻觉。
*   **高性能 (Performance)**: 原生架构支撑超长会话体验。
*   **扩展性 (Extensibility)**: 插件化 Pipeline + 统一 Filament 协议。

### 11.2 未来路线图
*   **v2.3**: 完善 Jinja2 宏系统与安全沙箱。
*   **ACU 集成**: 引入辅助认知单元，增强记忆检索能力。
*   **Galgame 引擎**: 落地基于 Event Chain 的复杂视觉小说系统。
