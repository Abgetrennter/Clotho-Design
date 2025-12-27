# 第二章：系统核心架构与编排层 (Jacquard Layer)

**版本**: 1.0.0
**日期**: 2025-12-23
**状态**: Draft
**作者**: 资深系统架构师 (Architect Mode)
**源文档**: `system_architecture.md`, `mvu_integration_design.md`

---

## 1. 编排层概览 (Jacquard Overview)

**Jacquard** 是逻辑层的核心，它被重新设计为一个 **Pipeline Runner**。它不包含具体的业务逻辑，而是负责按顺序执行注册的插件。它是系统的“大脑”，通过确定性的编排来驾驭概率性的 LLM 生成。

### 1.1 核心职责
1.  **流程调度**: 协调 Prompt 组装、API 调用、结果解析等步骤。
2.  **Skein 构建**: 维护上下文容器，支持动态裁剪。
3.  **模板渲染**: 集成 Jinja2 引擎，支持高级宏逻辑和动态内容组装。
4.  **协议解析**: 实时解析 Filament 协议流，分发事件。

### 1.2 架构拓扑
```mermaid
graph TD
    classDef orch fill:#fff3e0,stroke:#e65100,stroke-width:2px;
    
    subgraph Jacquard [Jacquard Pipeline]
        Bus[Jacquard 总线]:::orch
        
        subgraph NativePlugins [原生插件流水线]
            Planner[Planner Plugin]:::orch
            Builder[Skein Builder]:::orch
            Renderer[Template Renderer (Jinja2)]:::orch
            Assembler[Prompt Assembler]:::orch
            Invoker[LLM Invoker]:::orch
            Parser[Filament Parser]:::orch
            Updater[State Updater]:::orch
        end
    end
```

---

## 2. 插件化流水线 (Pipeline Mechanics)

Jacquard 维护一个插件列表，每个插件实现特定的接口。这种设计允许系统灵活扩展，甚至支持用户自定义逻辑。

### 2.1 核心插件定义

1.  **Skein Builder Plugin**:
    *   职责: 向数据层 (Mnemosyne) 请求快照 (`Punchcards`)。
    *   产出: 初始化的 `Skein` 对象。
    
2.  **Template Renderer Plugin (Jinja2)**:
    *   **原 PromptASTExecutor**: 已升级为标准的模板渲染引擎。
    *   **职责**: 编译并执行 Skein 中的 Jinja2 模板（支持 `{% if %}`, `{% set %}` 等逻辑）。
    *   **输入**: 包含 Jinja2 语法的 Skein。
    *   **上下文**: 注入 `Mnemosyne` 状态树（只读）和 `Skein` 元数据。
    *   **产出**: 逻辑处理完毕、变量已替换的纯文本 Skein。

3.  **LLM Invoker Plugin**:
    *   职责: 调用 LLM API，获取流式响应。
    *   输入: 最终渲染的 Prompt 字符串。

4.  **Filament Parser Plugin**:
    *   职责: 实时解析 LLM 的 Filament 输出。
    *   动作: 提取 `<reply>` 推送给 UI，提取 `<state_update>` 准备后续处理。

5.  **State Updater Plugin**:
    *   职责: 收集所有状态变更指令。
    *   动作: 调用 Mnemosyne 更新状态，并持久化历史。

### 2.2 宏与脚本沙箱 (Macro & Script Sandbox)
为了支持用户自定义扩展和安全的逻辑控制，系统采用了双层沙箱策略：
1.  **Jinja2 Sandbox (Macro Layer)**: 
    *   用于 Prompt 组装阶段的文本生成和简单逻辑控制。
    *   特性: 语法简洁，天然无副作用（无法修改 Mnemosyne），适合处理“动态开关”和“内容注入”。
2.  **QuickJS/LuaJIT (Script Layer)**: 
    *   用于复杂的业务逻辑计算（如伤害公式）。
    *   特性: 功能强大，但受限于严格的 API 白名单。

---

## 3. Skein (绞纱) - 结构化 Prompt 容器

**Skein** 是 Jacquard 流水线处理的核心数据对象。它是一个 **异构容器 (Heterogeneous Container)**，模块化地管理 System Prompt, Lore, User Input 等内容。

### 3.1 为什么需要 Skein?
传统的字符串拼接方式（String Concatenation）在处理复杂上下文时难以维护且容易出错。Skein 允许我们以“块 (Block)”为单位管理 Prompt，支持动态排序、裁剪和优先级控制。
**结合 Jinja2**: 每个 Block 都可以是一段 Jinja2 模板，在渲染阶段动态求值。

### 3.2 深度注入 (Depth Injection) 与块结构
为了支持类似 SillyTavern 的高级注入机制（如“在倒数第3条消息前插入 World Info”），Skein 被重新设计为基于 **PromptBlock** 的复合结构。

#### 3.2.1 PromptBlock 定义
每个 Block 不再仅仅是字符串，而是包含元数据的原子单元：
*   **Content**: 文本内容或 Jinja2 模板。
*   **Role**: 语义角色 (System, User, Assistant, Tool)，最终映射到 API 格式。
*   **InjectionConfig**: (可选) 定义该 Block 的注入策略。
    *   `position`: `relativeToStart` (从头数) 或 `relativeToEnd` (从尾数/深度)。
    *   `depth`: 具体的偏移量索引。

#### 3.2.2 Skein 链网结构
Skein 内部维护三条逻辑链：
1.  **System Chain**: 固定的头部指令 (System Prompt, Main Scenario)。
2.  **History Chain**: 标准的对话历史记录 (Linear Chat History)。
3.  **Floating Chain (浮动链)**: 尚未确定最终位置的注入块 (World Info, Author's Note, RAG 结果)。这些块带有 `InjectionConfig`，将在编织阶段被“缝合”进历史链。

### 3.3 编织 (Weaving) 算法
在 `Assembler` 阶段之前，必须执行 **Weaving** 操作，将 `Floating Chain` 合并入 `History Chain`。

1.  **Clone**: 复制当前的 History Chain。
2.  **Sort**: 根据 `depth` 和 `priority` 对 Floating Chain 进行排序。
3.  **Inject**: 遍历 Floating Chain，根据 `relativeToEnd` 计算目标索引，将其插入到 History Chain 的特定位置。
4.  **Output**: 生成最终的有序 Block 列表供 Assembler 使用。

---

## 4. Filament 协议 v2 (Filament Protocol)

为了确保 LLM 输出的可解析性与鲁棒性，我们定义了 **Filament** 协议。这是一个 XML 的严格子集，并在 v2 版本中引入了 JSON 优化。

### 4.1 核心语法规则
1.  **无自闭合标签**: 必须显式闭合 (`<tag>...</tag>`)。
2.  **严格白名单**: 解析器仅识别预定义标签，其他 `<` 符号视为文本。
3.  **容错性**: 支持自动闭合 (Auto-closing)。

### 4.2 v2 协议升级：JSON 状态更新
为了简化 LLM 的生成负担并提高解析效率，状态变更从繁琐的 XML 标签组改为 **JSON 列表包裹三元组**。

**旧版 (v1 XML):**
```xml
<state_update>
    <set key="hp" value="90"></set>
    <add key="gold" value="10"></add>
</state_update>
```

**新版 (v2 JSON):**
*   **格式**: `[OpCode, Path, Value]`
*   **优势**: Token 更少，解析更快，类型更安全。

```xml
<state_update>
[
  ["SET", "character.mood", "happy"],
  ["ADD", "character.gold", 50],
  ["PUSH", "inventory", {"name": "Sword", "atk": 10}]
]
</state_update>
```

### 4.3 标准标签集
*   **`<thought>`**: 思维链分析区域 (不展示给用户或折叠展示)。
*   **`<analysis>`**: (可选) 显式的变量分析块，用于提升逻辑准确性。
*   **`<state_update>`**: 包含上述 JSON 数组的状态变更区。
*   **`<reply>`**: 最终展示给用户的对话内容。

### 4.4 交互示例
```xml
<analysis>
  - character.health: N (未受伤)
  - character.gold: Y (获得奖励)
</analysis>
<state_update>
[
  ["ADD", "character.gold", 100]
]
</state_update>
<reply>
这是给你的奖励，勇士。
</reply>
```
