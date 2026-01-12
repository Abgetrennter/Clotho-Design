# 缪斯智能服务架构 (The Muse Intelligence Service)

**版本**: 3.0.0
**日期**: 2026-01-10
**状态**: Draft
**作者**: Clotho 架构团队
**关联**: `architecture-principles.md`, `jacquard-orchestration.md`, `infrastructure-layer.md`

---

## 1. 核心理念：智能中枢 (Intelligence Hub)

MuseService 是 Clotho 系统的**中央智能调度中枢**。它摒弃了将“主模型”与“辅助模型”在基础设施层面割裂的做法，转而采用分层治理（Layered Governance）模型。

> **"凯撒掌管律法 (Code)，上帝掌管灵魂 (Jacquard)，而缪斯掌管肉体与连接 (MuseService)。"**

### 1.1 双重职责
MuseService 同时承担着两种角色：
1.  **对于上帝 (Jacquard)**: 它是一个**透明网关 (Raw Gateway)**。Jacquard 拥有绝对的控制权，直接通过 MuseService 访问底层 LLM 资源，不经过任何中间处理。
2.  **对于凡人 (Other Clients)**: 它是一个**Agent 宿主 (Agent Host)**。Import Wizard、UI 组件等只需提供 Prompt（灵魂），MuseService 负责提供对话管理、技能调用等基础设施（肉体）。

---

## 2. 系统架构 (System Architecture)

### 2.1 架构分层图

```mermaid
graph TD
    subgraph "Clients (Consumers)"
        Jacquard[Jacquard (Roleplay Loop)]
        Import[Import Wizard]
        UI[Frontend UI]
    end

    subgraph "Muse Intelligence Service (Core)"
        Gateway[Raw Intelligence Gateway]
        AgentHost[Muse Agent Host]
        
        subgraph "Infrastructure"
            Router[Model Router]
            Billing[Billing & Rate Limit]
        end
    end

    subgraph "External World"
        OpenAI
        Anthropic
        LocalLLM
    end

    %% Jacquard 走 Raw 通道
    Jacquard -->|1. Raw Request (RP Prompt)| Gateway
    Gateway -->|2. Route & Bill| Router
    
    %% 普通 Client 走 Agent 通道
    Import -->|3. Create Agent| AgentHost
    UI -->|3. Create Agent| AgentHost
    
    AgentHost -->|4. Managed Request| Gateway
    Router -->|5. Connect| OpenAI & Anthropic & LocalLLM
```

---

## 3. 层级 1: 透明网关 (The Raw Gateway)

这是 MuseService 的底座，为系统内所有 LLM 调用提供统一的入口。

### 3.1 职责
*   **连接性 (Connectivity)**: 适配 OpenAI, Anthropic, Google, Local (Ollama) 等多种 API 协议。
*   **路由 (Routing)**: 根据配置将请求分发给指定的 Provider。
*   **治理 (Governance)**: 统一的 Token 计费、速率限制、鉴权、日志记录。
*   **无感知 (Agnostic)**: **绝不**修改 Prompt，**绝不**维护会话状态。

### 3.2 接口定义

```dart
/// 原始智能网关接口
abstract class IntelligenceGateway {
  /// 执行一次性生成
  Future<LLMResponse> executeRaw({
    required ModelConfig config,
    required List<RawMessage> messages,
    GenerationOptions? options,
  });

  /// 执行流式生成
  Stream<LLMChunk> streamRaw({
    required ModelConfig config,
    required List<RawMessage> messages,
    GenerationOptions? options,
  });
}
```

---

## 4. 层级 2: Agent 宿主 (The Agent Host)

建立在 Gateway 之上的应用层服务，为非 Jacquard 模块提供开箱即用的 Agent 能力。

### 4.1 核心概念：MuseAgent
一个 `MuseAgent` 是一个轻量级的智能体实例。
*   **Client 提供**: System Prompt (Persona/Instruction)。
*   **Host 提供**: 
    *   **Context Management**: 自动维护 `List<Message>` 历史，处理滑窗。
    *   **Skill System**: 自动挂载并调度注册的工具（如搜索、代码转换）。
    *   **Orchestration**: 处理 Chain-of-Thought, ReAct 循环等。

### 4.2 接口定义

```dart
/// Agent 宿主服务
abstract class MuseAgentHost {
  /// 创建一个新的 Agent 实例
  MuseAgent createAgent({
    required String agentId,
    required AgentConfig config, // 包含 System Prompt, Model Preference
    List<String> skills = const [], // 挂载的技能 ID
  });
}

/// 运行中的 Agent 实例
abstract class MuseAgent {
  /// 发送消息并获取回复
  Future<AgentReply> chat(String userMessage);
  
  /// 获取当前上下文摘要
  Future<String> summarizeContext();
  
  /// 销毁实例
  void dispose();
}
```

---

## 5. 技能系统 (The Skill System)

Agent Host 允许通过 ID 挂载标准化的技能。

### 5.1 技能注册表 (Skill Registry)
MuseService 维护一个全局的技能注册表，模块可以注册自定义技能。

```dart
class MuseSkillDefinition {
  final String id; // e.g., 'std.code_transmuter'
  final String description;
  final Schema inputSchema;
  final Schema outputSchema;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>) handler;
}
```

### 5.2 标准技能库

| 技能 ID | 描述 | 典型场景 |
| :--- | :--- | :--- |
| `std.summarizer` | 文本摘要 | PostFlash, 记忆压缩 |
| `std.translator` | 多语言翻译 | UI 本地化, 聊天翻译 |
| `std.code_transmuter` | 代码/格式转换 | Import Wizard (EJS -> Jinja2) |
| `std.web_search` | 联网搜索 | 知识问答 Agent |

---

## 6. 案例研究：导入向导 (Import Wizard Integration)

### 6.1 场景：交互式代码转换
用户在导入角色卡时，遇到复杂的正则脚本，不知道如何处理。

1.  **Initialization**: 
    Import Wizard 请求 MuseService 创建一个专用 Agent。
    ```dart
    final agent = museHost.createAgent(
      agentId: 'import_helper_${uuid}',
      config: AgentConfig(
        systemPrompt: "你是一个资深的代码迁移专家，精通 JavaScript 和 Jinja2...",
        modelPreference: ModelPreference.smart, // 使用 Claude 3.5 Sonnet
      ),
      skills: ['std.code_transmuter'] // 挂载代码转换技能
    );
    ```

2.  **Interaction**:
    用户在 UI 中提问：“这个脚本是干嘛的？”
    Import Wizard 调用 `agent.chat("这个脚本是干嘛的？\n\n${scriptContent}")`。

3.  **Execution**:
    *   MuseAgent 自动将用户输入加入历史。
    *   MuseAgent 调用 Gateway 发送请求。
    *   LLM 回复：“这是一个 UI 注入脚本... 我可以使用 `std.code_transmuter` 帮你转换。”
    *   MuseAgent 识别 Tool Call，执行 `std.code_transmuter`。
    *   MuseAgent 将转换结果反馈给用户。

4.  **Completion**:
    用户满意后，Import Wizard 调用 `agent.dispose()` 释放资源。

---

## 7. 与 Jacquard 的协作 (Pre/PostFlash)

PreFlash (预处理) 和 PostFlash (后处理) 是 Jacquard 编排流程中的关键环节。由于这些任务通常涉及对 Context 的深度理解和极其复杂的 Prompt 工程（如无损压缩、知识图谱提取），**Jacquard 将直接使用 Raw Gateway 来执行这些任务**，而不是委托给通用的 MuseAgent。

*   **PreFlash (e.g., Summarization)**:
    *   **Jacquard**: 自主构建压缩 Prompt，精确控制保留哪些关键信息。
    *   **MuseService**: 仅作为 Raw Gateway 提供 LLM 推理能力。
    
*   **PostFlash (e.g., Extraction)**:
    *   **Jacquard**: 自主构建提取 Prompt，定义复杂的输出 Schema。
    *   **MuseService**: 仅作为 Raw Gateway 提供 LLM 推理能力。

这种设计确保了 Jacquard 对核心编排逻辑的绝对控制，避免了 MuseAgent 通用逻辑对高精度任务的干扰。

---

## 8. 总结

通过 **“Raw Gateway + Agent Host”** 的双层架构，MuseService 成功解决了“上帝与缪斯”的矛盾：
*   **Gateway** 统一了基础设施，确保了计费和连接的单一来源。
*   **Agent Host** 封装了复杂性，让普通模块能轻易获得智能能力。
*   **Jacquard** 保持了独立性，不受限于通用的 Agent 逻辑，可以自由地进行深度编排。
