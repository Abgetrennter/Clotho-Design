# 辅助 LLM 组件应用设计：角色导入场景

**版本**: 1.0.0
**日期**: 2026-01-10
**状态**: Draft
**关联**: `00_active_specs/core/muse-intelligence-service.md`, `00_active_specs/workflows/character-import-migration.md`

---

## 1. 背景与目标

本文档是 **缪斯智能服务 (Muse Intelligence Service)** 在 **织谱导入与迁移系统 (Pattern Import & Migration)** 中的具体应用设计。

目标是解决从 SillyTavern 迁移到 Clotho 过程中遇到的“代码方言转换”和“复杂脚本意图识别”问题，通过挂载专用的辅助 Agent 来降低用户的认知负担。

## 2. 组件集成架构

我们将使用 `MuseAgentHost` 提供的 Agent 能力，为导入向导构建一个名为 `CodeTransmutationAgent` 的专用助手。

```mermaid
graph TD
    User[用户] -->|点击'AI 协助'| UI[导入向导 UI]
    UI -->|1. Create Agent| Host[Muse Agent Host]
    
    subgraph "Muse Service"
        Host -->|2. Instantiate| Agent[CodeTransmutationAgent]
        Agent -->|3. Load Skill| Skill[std.code_transmuter]
        Agent -->|4. Load Skill| Skill2[std.intent_classifier]
    end
    
    UI -->|5. Chat (Script Content)| Agent
    Agent -->|6. Execution| Gateway[Raw Gateway]
    Gateway -->|7. Response| Agent
    Agent -->|8. Reply (Translation/Explanation)| UI
```

## 3. 场景深度设计

### 3.1 场景 A: 复杂 EJS 代码转换 (EJS to Jinja2)

SillyTavern 的角色卡常包含复杂的 EJS 逻辑（如 `getvar`, `getwi`）。我们需要将其转换为 Clotho 的 Jinja2 格式。

#### 3.1.1 技能定义 (`std.code_transmuter`)

*   **Skill ID**: `std.code_transmuter`
*   **System Prompt**:
    ```markdown
    你是一个精通 JavaScript (EJS) 和 Python (Jinja2) 的代码转换专家。
    你的任务是将 SillyTavern 的 EJS 脚本转换为 Clotho 兼容的 Jinja2 模板。
    
    # 转换规则
    1. `getvar(name)` -> `state.get(name)`
    2. `setvar(name, val)` -> `state.set(name, val)`
    3. `<% if %>` -> `{% if %}`
    4. `{{random: a, b}}` -> `{{ ['a', 'b'] | random }}`
    
    # 输出格式
    请直接输出转换后的代码，包裹在 ```jinja2 代码块中。
    在代码块之后，简要解释你做了哪些修改。
    ```

#### 3.1.2 交互流程

1.  **识别**: 导入引擎识别出某条目包含 `<%` 标签，标记为 `TriangeCategory.code`。
2.  **提示**: UI 显示“检测到 EJS 代码，是否使用 AI 转换为 Jinja2？”
3.  **触发**: 用户点击“转换”。
4.  **执行**:
    *   UI 调用 `agent.chat("请转换以下代码:\n" + rawContent)`。
    *   Agent 返回转换后的代码。
5.  **应用**: UI 自动提取 markdown 代码块中的内容，填入“转换后预览”框供用户确认。

### 3.2 场景 B: 正则脚本意图分诊 (Regex Script Triage)

用户导入了包含大量正则脚本的角色卡，系统无法自动判断这些脚本是用来“修正文本”还是“注入 UI”。

#### 3.2.1 技能定义 (`std.intent_classifier`)

*   **Skill ID**: `std.intent_classifier`
*   **System Prompt**:
    ```markdown
    你是一个代码安全审计员。你的任务是分析正则表达式及其替换内容的意图。
    
    # 分类标准
    - `replacement`: 简单的文本修正，无 HTML/JS。
    - `cleanup`: 将内容替换为空字符串。
    - `ui_injection`: 包含 HTML 标签 (`<div>`, `<img>`) 或 `<script>`。
    
    # 输出格式 (Filament)
    <analysis>
      <intent>ui_injection</intent>
      <risk_level>high</risk_level>
      <reason>检测到 script 标签，试图执行 DOM 操作。</reason>
    </analysis>
    ```

#### 3.2.2 交互流程

1.  **批处理**: 导入向导在后台静默创建一个 Agent。
2.  **遍历**: 对每个正则脚本，调用 Agent 进行分析。
3.  **决策**:
    *   如果 `<intent>` 是 `ui_injection`，UI 将该脚本标记为红色，并建议用户“在 WebView 沙箱中运行”。
    *   如果 `<intent>` 是 `cleanup`，自动勾选“作为输出过滤器导入”。

## 4. 接口适配代码示例 (Dart)

```dart
class ImportWizardController {
  late MuseAgent _helperAgent;

  Future<void> initHelper() async {
    _helperAgent = MuseService.instance.agentHost.createAgent(
      agentId: 'import_wizard_${uuid}',
      config: AgentConfig(
        systemPrompt: "你是织谱导入助手...",
        modelPreference: ModelPreference.efficiency, // 使用快速模型进行分诊
      ),
      skills: ['std.code_transmuter', 'std.intent_classifier'],
    );
  }

  Future<String> transmuteCode(String ejsCode) async {
    final reply = await _helperAgent.chat(
      "请转换此代码: \n```javascript\n$ejsCode\n```"
    );
    return extractCodeBlock(reply.content);
  }
}
```

## 5. 总结

通过将通用 LLM 能力封装为 `CodeTransmutationAgent`，我们避免了在导入解析器中硬编码复杂的转换逻辑。这种设计不仅提高了系统的鲁棒性（可以处理未知的代码模式），还为用户提供了一个交互式的“迁移助手”，体现了“缪斯原则”在实际工程中的价值。
