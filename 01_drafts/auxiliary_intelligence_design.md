# 辅助智能架构：缪斯原则 (The Muses Principle)

**版本**: 0.1.0
**日期**: 2026-01-10
**状态**: Draft
**作者**: Clotho 架构团队
**关联**: `architecture-principles.md`, `jacquard-orchestration.md`

---

## 1. 核心理念：缪斯原则 (The Muses Principle)

在凯撒原则 (The Caesar Principle) 的二元对立（代码逻辑 vs LLM 扮演）之外，我们引入第三个维度：**缪斯 (The Muses)**。

> **"凯撒掌管律法，上帝掌管灵魂，而缪斯掌管灵感与技艺。"**

### 1.1 定义
缪斯是指系统中独立于主对话流程（Main Chat Loop）之外的 **辅助性 LLM 任务**。它们不直接参与角色的扮演，而是作为系统的“副驾驶”或“秘书”，利用 LLM 强大的非结构化数据处理能力，解决那些**代码难以通过确定性逻辑解决，且主 LLM 不应分心处理**的任务。

### 1.2 核心特征
1.  **独立上下文 (Isolated Context)**: 缪斯任务拥有独立的、极简的上下文窗口，不加载沉重的历史聊天记录，仅加载任务所需的片段。
2.  **独立模型配置 (Independent Configuration)**: 可以（且建议）使用更快速、更廉价的模型（如 GPT-4o-mini, Claude 3 Haiku）来执行。
3.  **功能性导向 (Function-Oriented)**: 它们的 Prompt 是为了完成特定工作（总结、提取、转换），而不是为了沉浸式扮演。
4.  **结果结构化 (Structured Output)**: 必须通过 Filament 协议输出结构化数据，以便系统自动采纳。

---

## 2. 架构设计

### 2.1 缪斯信道 (The Muse Channels)
我们在 Jacquard 编排层之外，设计一套并行的**异步任务总线**。

```mermaid
graph TD
    User[用户操作] -->|触发| MuseClient[缪斯客户端]
    System[系统事件] -->|触发| MuseClient
    
    subgraph "Main Stage"
        Chat[主对话流]
    end
    
    subgraph "The Muses (Auxiliary Layer)"
        MuseClient -->|构建任务| Task[Muse Task]
        Task -->|特定 Prompt| MiniLLM[Utility LLM (e.g. 4o-mini)]
        MiniLLM -->|Filament Out| Parser[Muse Parser]
    end
    
    Parser -->|State Update| Mnemosyne[Mnemosyne 数据库]
    Parser -->|UI Fill| UI[前端界面]
```

### 2.2 交互模式

#### A. 主动辅助 (Active Assistance) - "魔法棒"
用户在界面上点击“AI 辅助”按钮（例如在编辑记忆条目时）。
*   **输入**: 用户选中的文本或当前输入框的内容。
*   **任务**: "请润色这段文字"、"请将其扩写为环境描写"。
*   **输出**: 直接回填到输入框。

#### B. 被动维护 (Passive Maintenance) - "图书管理员"
系统在后台自动触发的任务。
*   **触发**: 累积 50 条对话后。
*   **任务**: "请阅读这 50 条对话，生成一段 200 字的摘要"。
*   **输出**: 存入 Mnemosyne 的 `summary_chain`。

#### C. 决策咨询 (Consultation) - "神谕"
当用户想要推进剧情但不知如何操作时。
*   **输入**: 当前场景概况。
*   **任务**: "给出 3 个剧情发展分支建议"。
*   **输出**: 在 UI 上显示选项卡供用户选择。

---

## 3. 标准化 Prompt 模板

缪斯任务使用独立的 Prompt 模板库，不与角色卡混淆。

### 3.1 结构
```yaml
task_id: "memory_summarizer"
model_preference: "efficiency" # 偏向速度
input_schema:
  - messages: List[Message]
output_schema:
  format: "xml"
  root_tag: "summary"
system_prompt: |
  你是一个专业的图书管理员。你的任务是阅读对话记录，并生成客观、简洁的摘要。
  请忽略无关的闲聊，专注于关键剧情节点。
  输出格式必须为: <summary>内容...</summary>
```

---

## 4. 与现有原则的融合

| 维度 | 凯撒 (Code) | 上帝 (Main LLM) | 缪斯 (Auxiliary LLM) |
| :--- | :--- | :--- | :--- |
| **职责** | 逻辑、算数、存储 | 角色扮演、情感 | 数据清洗、摘要、建议 |
| **思维** | 确定性 (Deterministic) | 沉浸式 (Immersive) | 分析式 (Analytical) |
| **上下文** | 全局状态 | 滑动窗口 + 记忆 | 仅任务相关片段 (One-shot) |
| **模型** | CPU/GPU 本地代码 | SOTA 大模型 (Opus/GPT-4) | 高速小模型 (Haiku/Mini) |

## 5. 典型应用场景列表

1.  **记忆压缩 (Memory Compression)**: 定期将对话历史压缩为摘要。
2.  **档案整理 (Profile Parsing)**: 从非结构化的用户输入中提取角色属性（如从一段自述中提取“年龄”、“发色”）。
3.  **智能标签 (Auto Tagging)**: 为聊天记录或存档自动打上语义标签（“战斗”、“恋爱”、“日常”）。
4.  **格式转换 (Format Transmuter)**: 将用户输入的自然语言动作转换为标准的 XML 剧本格式。
5.  **图景重绘 (Scene Painting)**: 根据当前对话生成 SD/DALL-E 的提示词。

---

**下一步计划**:
1. 在 `architecture-principles.md` 中正式确立“缪斯原则”。
2. 在 Jacquard 架构中定义 `MuseService` 接口。
3. 制定第一批缪斯任务的 Prompt 模板。
