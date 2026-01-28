# Clotho 系统架构设计文档 (System Architecture Design Document)

**版本**: 4.0
**状态**: Draft
**最后更新**: 2025-12-23
**参考文档**: `doc/合并.md`, `doc/plan.md`, `doc/升级版设计.md`, `doc/architecture/st_prompt_template_migration_design.md`

---

## 1. 架构概览 (Architecture Overview)
本项目旨在构建一个高性能、高可定制的 AI 角色扮演（RPG）客户端。现有解决方案（如 SillyTavern）在处理复杂逻辑时面临性能瓶颈（前端重逻辑）和上下文管理混乱（字符串拼接难以维护）的问题。

### 核心目标
1.  **架构解耦**：实现 UI（Flutter）与逻辑（Dart Jacquard）的彻底分离。
2.  **确定性编排**：通过代码控制流程，通过 LLM 处理语义，拒绝"让 LLM 决定一切"。
3.  **时空一致性**：引入"多重宇宙树（Turn-based Tree）"模型管理对话历史，支持无损的回溯、分支（Reroll）和状态快照。
4.  **结构化 Prompt**：采用 **Skein**（结构化数据容器）替代传统的字符串拼接，实现模块化的上下文装配。
5.  **可扩展性**：支持用户通过 JavaScript/Lua 等脚本语言编写自定义插件，运行在安全的沙箱环境中。

本系统采用 **混合 Agent 架构 (Hybrid Agent Architecture)**，核心设计理念是 **"数据与逻辑分离，确定性编排与概率性生成结合"**。

### 1.1 系统边界与分层

系统划分为三个物理隔离但逻辑紧密的层次：

1.  **表现层 (Presentation Layer)**: 负责用户交互与界面渲染。
    *   **Flutter UI**: 原生高性能聊天界面。
    *   **Webview**: 承载动态 HTML/JS 组件（如状态栏）。
2.  **编排层 (Jacquard Layer)**: 系统的“大脑”，负责流程控制与 Prompt 组装。
    *   **Jacquard**: 插件化流水线执行器。
    *   **Shuttles**: 具体的逻辑单元（如 Prompt Assembler, Regex Cleaner）。
3.  **数据与基础设施层 (Data & Infrastructure Layer)**: 负责数据的存储、检索与聚合。
    *   **Mnemosyne**: **核心组件**，上下文快照提供者 (Context Snapshot Provider)。
    *   **History Engine**: 基于树状结构的历史管理。
    *   **Vector DB**: 语义检索支持。

### 1.2 架构拓扑图

```mermaid
graph TD
    %% 样式定义
    classDef ui fill:#e1f5fe,stroke:#01579b,stroke-width:2px;
    classDef orch fill:#fff3e0,stroke:#e65100,stroke-width:2px;
    classDef data fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px;
    classDef ext fill:#f3e5f5,stroke:#4a148c,stroke-width:2px;
    classDef script fill:#fce4ec,stroke:#880e4f,stroke-width:2px;

    User((用户))

    subgraph Presentation [表现层]
        UI_Chat[聊天界面]:::ui
        UI_Webview[Webview 组件]:::ui
    end

    subgraph Jacquard [编排层 Jacquard Pipeline]
        Jacquard[Jacquard 总线]:::orch
        
        subgraph NativePlugins [原生插件流水线]
            P_Planner[Planner Plugin]:::orch
            P_Builder[Skein Builder]:::orch
            P_AST[Prompt AST Executor]:::orch
            P_Cleaner[Regex Cleaner]:::orch
            P_Budget[Token Budget Plugin]:::orch
            P_Assembler[Prompt Assembler]:::orch
            P_Invoker[LLM Invoker]:::orch
            P_Parser[Filament Parser]:::orch
            P_Updater[State Updater]:::orch
        end
        
        subgraph ScriptPlugins [脚本插件沙箱]
            SR[Script Plugin Runner]:::script
            SR_JS[QuickJS 引擎]:::script
            SR_Lua[LuaJIT 引擎]:::script
        end
    end

    subgraph Data_Infra [数据层 Mnemosyne]
        Mnemosyne[Mnemosyne ContextProvider]:::data
        
        subgraph Internal_Modules
            Context_Pipeline[Context Pipeline]:::data
            History_Manager[History Manager]:::data
            Lore_Manager[Lore/RAG Manager]:::data
            State_Manager[State Manager]:::data
        end
    end
    
    subgraph External [外部服务]
        LLM[Core LLM]:::ext
    end

    %% 连接
    User <--> UI_Chat
    UI_Chat <--> Jacquard
    
    Jacquard --> Mnemosyne
    Jacquard --> NativePlugins
    Jacquard --> SR
    
    P_Builder -- "请求快照" --> Mnemosyne
    Mnemosyne -- "返回 Punchcards" --> P_Builder
    
    P_AST --> SR
    SR --> SR_JS
    SR --> SR_Lua
    
    P_Assembler --> LLM
    LLM --> P_Parser
    P_Parser -- "更新状态" --> Mnemosyne
```

---

## 2. 简化XML 协议定义 (Filament)

为了确保 LLM 输出的可解析性与鲁棒性，我们定义了一个简化版的XML协议 Filament 。该协议是 XML 的严格子集，专为流式解析和 LLM 生成优化。

### 2.1 核心语法规则

1.  **无自闭合标签**: 所有标签必须显式闭合。
    *   ✅ `<action>attack</action>`
    *   ❌ `<action value="attack" />`
2.  **无转义字符**: 内容区域视为纯文本（CDATA），解析器不处理 `<` 等转义实体。
    *   ✅ `<content>1 < 2</content>`
    *   ❌ `<content>1 < 2</content>`
3.  **浅层嵌套**: 推荐最大嵌套深度不超过 2 层，降低解析复杂度。
4.  **容错性**: 解析器支持自动闭合未闭合的标签（Auto-closing），以应对 LLM 输出中断的情况。
5.  **严格白名单 (Strict Whitelist)**: 解析器仅识别预定义的标签（如 `<thought>`, `<reply>`）。所有不在白名单内的 `<` 符号（如数学公式 `1 < 2`）一律视为普通文本，不进行标签解析。

### 2.2 标准标签集

LLM 的输出必须遵循以下结构：

```xml
<!-- 思维链 (可选) -->
<thought>
    分析用户意图...
    决定执行攻击动作...
</thought>

<!-- 状态变更 (可选) -->
<state_update>
    <set key="hp" value="90"></set>
    <add key="gold" value="10"></add>
</state_update>

<!-- 最终回复 (必须) -->
<reply>
    你挥舞长剑，击中了哥布林！
</reply>

```

---

## 3. Mnemosyne: 上下文快照提供者 (Context Snapshot Provider)

**Mnemosyne** 是数据层的核心，它不再仅仅是静态数据的仓库，而是升级为 **动态上下文生成引擎**。

### 3.1 核心职责

1.  **数据托管**: 管理所有上下文无关的内容（Lorebook, Presets, World Rules）。
2.  **快照生成**: 提供 `getPunchcards(pointer)` 接口。当 Jacquard 请求时，它根据当前的 Session Pointer，聚合所有相关数据，生成一个静态的、不可变的快照对象。
3.  **状态管理**: 维护 RPG 变量、角色状态，并处理来自 Jacquard 的状态更新请求。

### 3.2 逻辑视图：多维上下文链 (Multi-dimensional Context Chains)

虽然数据在物理上以 **增量 (Incremental)** 形式存储在 `ContextNode` 中，但在逻辑上，Mnemosyne 将其投影为数条平行的 **上下文链网 (Context Chains Net)**。Jacquard 看到的是一个凝结了现在世界线内容的快照。

1.  **History Chain (历史链)**
    *   **内容**: 标准对话记录 (User Message / AI Message)。
    *   **逻辑**: 从 Root 到 Current Pointer 的线性投影。
    *   **作用**: 提供 LLM 理解剧情所需的上下文连贯性。

2.  **State Chain (状态链)**
    *   **内容**: 结构化的 RPG 数值与状态 (JSON)。
    *   **策略**: **关键帧 + 增量 (Keyframe + Delta)**。每隔 N 个节点存储一次全量快照（Keyframe），中间节点仅存储相对于上一个节点的变更 Diff（Delta）。
    *   **作用**: 确保“时间旅行”时，世界状态能精确回滚到那一刻，同时控制数据库体积。

3.  **RAG Chain (检索增强链)**
    *   **内容**: 向量化的记忆片段与 Lore 条目。
    *   **逻辑**: 基于当前 History Chain 的语义检索结果。
    *   **作用**: 动态注入相关的背景知识。

4.  **Event Manager (事件管理器) [Future Implementation]**
    *   **定位**: 复杂的**状态机 (State Machine)**，而非简单的数据链。
    *   **内容**: 触发器 (Triggers)、任务 (Quests)、脚本事件 (Scripted Events)。
    *   **状态**: *Reserved for future development.*

### 3.3 Context Pipeline 工作流

当 Jacquard 请求快照时，Pipeline 执行以下**投影 (Projection)** 操作：
若为顺延，则选取当前快照进行更新。否则进入快照重建流程：
1.  **Trace**: 根据 Session Pointer 回溯树路径。
2.  **Project**:
    *   合并路径上的文本 -> 生成 **History Chain**。
    *   提取当前节点的 State -> 生成 **State Chain**。
    *   基于 History 进行向量检索 -> 生成 **RAG Chain**。
3.  **Assemble**: 将上述链的内容结合 Presets，封装为不可变的 `Punchcards`。

---

## 4. Jacquard: 插件化流水线 (Plugin-based Pipeline)

**Jacquard** 是逻辑层的核心，它被重新设计为一个 **Pipeline Runner**。它不包含具体的业务逻辑，而是负责按顺序执行注册的插件。

### 4.1 插件化架构

Jacquard 维护一个插件列表，每个插件实现特定的接口：

```dart
abstract class JacquardPlugin {
  Future<void> execute(JacquardContext context);
}

/// Jacquard 上下文，在插件间传递
class JacquardContext {
  Skein skein;              // 当前 Skein 对象
  Map<String, dynamic> state; // 当前状态
  String sessionId;         // 会话 ID
  SessionPointer pointer;   // 当前会话指针
  // ... 其他上下文信息
}
```

### 4.2 Skein: 绞纱 - 结构化 Prompt 容器

**Skein** 是 Jacquard 流水线处理的核心数据对象。它是一个 **异构容器 (Heterogeneous Container)**，不强制内部元素的类型一致性，只关心它们的"编织策略"（如何被组装成最终 Prompt）。


#### 4.3 核心插件

1.  **Planner Plugin**:
    *   分析用户输入，决定是否需要调用工具或修改上下文检索策略。
2.  **LLM Invoker Plugin**:
    *   调用 LLM API，获取流式响应。
3.  **Filament Parser Plugin**:
    *   实时解析 LLM 的 Filament 输出。
    *   提取 `<reply>` 推送给 UI。
    *   提取 `<state_update>` 准备后续处理。
4.  **State Updater Plugin**:
    *   将解析出的状态变更提交回 `Mnemosyne`。

### 4.4 Script Plugin Runner (脚本插件运行器)

为了支持用户自定义扩展，Jacquard 提供了沙箱化的脚本插件运行器，允许用户使用 JavaScript 或 Lua 编写自定义插件。

#### 4.4.1 设计理念

- **隔离性**：脚本运行在受限的沙箱环境中，无法访问宿主机的文件系统、网络等敏感资源。
- **API 限制**：只暴露必要的 API（如 `skein` 操作、状态读取），禁止直接访问内部对象。
- **语言支持**：优先支持 JavaScript (QuickJS 引擎) 和 Lua (LuaJIT 引擎)。


---

## 5. 详细数据流 (Detailed Data Flow)

本节描述从用户输入到状态更新的完整数据流转。

### 5.1 阶段一：准备与组装

1.  **用户输入**: 用户发送消息。
2.  **Jacquard 启动**: 初始化流水线上下文。
3.  **Skein Builder Plugin**:
    *   调用 `Mnemosyne.getPunchcards()`。
    *   Mnemosyne 内部 Pipeline 运行：检索 Lore -> 获取历史 -> 读取状态。
    *   返回 `Punchcards`。
    *   Builder 构建 `Skein` 对象。
4.  **中间件插件处理**:
    *   **Prompt AST Executor**: 执行条件逻辑。
    *   **Regex Cleaner**: 清理敏感词。
    *   **Script Plugin Runner**: 执行用户自定义脚本。
    *   **Token Budget**: 根据 Token 预算裁剪 Skein。
5.  **Prompt Assembler**:
    *   调用 `Weaver.process(skein)`。
    *   将 Skein 渲染为最终的 Filament Prompt 字符串。

### 5.2 阶段二：生成与解析

1.  **LLM Invoker**: 发送 Prompt 给 LLM。
2.  **Filament Parser**:
    *   监听流式输出。
    *   解析 `<thought>`, `<state_update>`, `<reply>`。
    *   实时更新 UI。

### 5.3 阶段三：更新与持久化

1.  **State Updater**:
    *   收集所有 `<state_update>`。
    *   调用 `Mnemosyne.updateState(delta)`。
    *   调用 `HistoryManager.addNode()` 保存对话历史。
2.  **Mnemosyne**:
    *   应用状态变更。
    *   更新指针，准备下一轮对话。

---