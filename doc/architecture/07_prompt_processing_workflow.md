# 第七章：提示词处理工作流 (Prompt Processing Workflow)

**版本**: 1.0.0
**日期**: 2025-12-27
**状态**: Draft
**关联文档**: `02_jacquard_orchestration.md`, `03_mnemosyne_data_engine.md`, `macro_system_spec.md`

---

## 1. 工作流概览 (Workflow Overview)

Clotho 的提示词处理流程是一个高度结构化、确定性的流水线（Pipeline）。它遵循 **“晚期绑定 (Late Binding)”** 和 **“无副作用 (Zero Side-Effect)”** 原则，确保 LLM 接收到的始终是基于最新状态的纯净文本。

整个流程由 **Jacquard** 编排层驱动，核心数据载体是 **Skein (绞纱)**。

### 1.1 核心流程图

```mermaid
graph TD
    UserInput((用户输入)) --> Planner[1. Planner: 意图规划]
    Planner --> SkeinBuilder[2. Skein Builder: 原始构建]
    
    subgraph DataFetch [数据获取]
        Mnemosyne[(Mnemosyne State)] -.->|快照 (Snapshot)| SkeinBuilder
        Lorebook[(Lorebook)] -.->|词条 (Entries)| SkeinBuilder
    end
    
    SkeinBuilder --> RawSkein[Raw Skein (含 Jinja2 模板)]
    
    subgraph Rendering [3. 模板渲染层 (Template Rendering)]
        RawSkein --> Renderer[Template Renderer]
        JinjaEng[Jinja2 Engine] -.->|解析与执行| Renderer
        Renderer -->|逻辑控制 {% if %}| ProcSkein[中间态 Skein]
        Renderer -->|变量替换 {{ val }}| FinalSkein[Final Skein (纯文本)]
    end
    
    FinalSkein --> Assembler[4. Assembler: 最终拼接]
    Assembler --> String[Prompt String]
    String --> Invoker[5. LLM Invoker]
```

---

## 2. 详细处理阶段 (Detailed Stages)

### 2.1 第一阶段：意图规划 (Planner)

* **输入**: 用户发送的消息文本、当前会话 ID。
* **职责**:
  * 分析用户意图（正常对话、指令执行、重试等）。
  * 决定使用哪个 **Prompt Template**（例如：默认对话模板、冒险模式模板）。
  * 路由到相应的 Pipeline 分支。
* **产出**: `PlanContext` (包含模板 ID 和初始指令)。

### 2.2 第二阶段：Skein 构建 (Skein Builder)

* **输入**: `PlanContext`
* **职责**: 初始化 `Skein` 容器，并填充**原始数据**。
  * **快照获取**: 向 `Mnemosyne` 请求当前时间点 (`TimePointer`) 的状态快照 (`Punchcards`)。这是一个**只读的深拷贝**。
  * **上下文检索**: 根据语义检索相关的 Lorebook 条目。
  * **装填**:
    * 将 System Template 填入 `System Chain`。
    * 将历史对话填入 `History Chain`。
    * 将检索到的 World Info 和 Author's Note 封装为带 `InjectionConfig` 的 PromptBlock，填入 `Floating Chain`。
* **关键点**: 此时 Block 中的内容包含 **未处理的 Jinja2 标签**。
* **产出**: `Raw Skein`。

### 2.3 第三阶段：模板渲染 (Template Renderer)

这是流程的核心，负责将动态逻辑转化为静态文本。

* **输入**: `Raw Skein`, `Mnemosyne Snapshot` (作为 Context)。
* **引擎**: **Jinja2 (Dart)**。
* **职责**:
    1. **编译**: 解析所有 Block 中的 Jinja2 语法。
    2. **逻辑执行**: 运行控制流。
        * *示例*: `{% if is_night %}` -> 检查 Context 中的 `is_night` 变量，决定是否保留夜间描述。
    3. **动态拼装**: 处理 `{% set frag %}...{% endset %}`，将复杂文本块存入临时变量并注入。
    4. **变量替换**: 将 `{{ char }}` 替换为 "Seraphina"，将 `{{ state.gold }}` 替换为 "100"。
* **安全沙箱**:
  * 渲染过程**严禁**修改 Mnemosyne 数据库。
  * 禁止文件/网络访问。
  * 所有变量仅在渲染周期内有效。

### 2.4 第四阶段：最终拼接 (Assembler)

* **输入**: `Final Skein`。
* **职责**: 将分散的 Block 链编织并转换为 LLM 请求体。
* **操作流程 (OpenAI Mode)**:
    1. **Weaving (编织)**: 将 `Floating Chain` 中的块，根据其 `depth` (如倒数第2条) 插入到 `History Chain` 的对应索引中。
    2. **Format**: 将 `System Chain` 和编织后的 `History Chain` 转换为 JSON 列表 `[{role: "system", ...}, {role: "user", ...}]`。
    3. **Truncate**: (可选) 如果超长，根据优先级丢弃旧的 History Block。
* **产出**: `JSON Object` (发送给 API 的 Body)。

### 2.5 第五阶段：LLM 调用 (Invoker)

* **输入**: `String`。
* **职责**: 调用底层 API (OpenAI, Anthropic, Local) 发送请求并接收流式响应。

---

## 3. 数据流变迁 (Data Transformation)

| 阶段 | 数据对象 | 状态描述 | 示例内容 |
| :--- | :--- | :--- | :--- |
| **Input** | `UserMessage` | 原始输入 | "你好，你是谁？" |
| **Build** | `Raw Skein` | **含模版** | `Hello, I am {{ char }}. {% if mood=='angry' %}Go away!{% endif %}` |
| **Render** | `Final Skein` | **纯文本** | "Hello, I am Seraphina. Go away!" (假设 mood=='angry') |
| **Assemble** | `Prompt String` | **含格式** | `<|im_start|>assistant\nHello, I am Seraphina...<|im_end|>` |

---

## 4. 设计原则总结

1. **Late Binding (晚期绑定)**:
    * 变量替换发生在发送给 LLM 的**最后一刻**。这确保了如果用户在生成前一秒修改了状态（如修改了名字），Prompt 会立即反映最新值，无需重启会话。

2. **Zero Side-Effect (无副作用)**:
    * 渲染层 (`TemplateRenderer`) 是**纯函数**：`f(Template, State) -> Text`。
    * 它绝对不会因为渲染了 `{% if %}` 而改变 `state.hp`。状态变更只能通过 LLM 输出后的 `Parser` 阶段进行。

3. **Structured Container (结构化容器)**:
    * 使用 `Skein` 而非长字符串传递数据，允许我们在 Pipeline 的任何阶段对特定部分（如 System Prompt）进行独立修改、替换或调试。
