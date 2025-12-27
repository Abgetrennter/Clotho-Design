# ST-Prompt-Template 迁移策略与设计文档 (Migration Strategy & Design Document)

**版本**: 1.0
**状态**: Draft
**最后更新**: 2025-12-23
**参考文档**: `doc/architecture/system_architecture.md`, `doc/architecture/st_prompt_template_analysis.md`

---

## 1. 设计综述 (Design Overview)

本设计旨在解决如何将 SillyTavern 的 `ST-Prompt-Template` (EJS) 生态迁移至 `Clotho` 架构中。由于 `Clotho` 强调**数据与逻辑分离**和**确定性编排**，直接支持任意代码执行 (Arbitrary Code Execution) 是不可接受的。

因此，我们采取 **"交互式迁移向导 (Interactive Migration Wizard)"** 策略。系统不追求全自动黑盒转译，而是提供一套工具链，引导用户将老旧的 EJS 逻辑解构、提取并映射到 Clotho 的现代架构组件（Mnemosyne 状态、UI 扩展、事件触发器）中。

---

## 2. 核心迁移流程 (Migration Workflow)

迁移过程是一个半自动化的管道，包含四个核心阶段：**扫描 (Scan) -> 建议 (Suggest) -> 交互 (Interact) -> 执行 (Action)**。

```mermaid
graph TD
    Input[Legacy ST Card (JSON)] --> Scanner[代码模式扫描器]
    
    subgraph Analysis_Engine [智能分析引擎]
        Scanner --> |提取代码块| Analyzer[语义分析器]
        Analyzer -- "识别变量" --> Var_Handler[变量提取]
        Analyzer -- "识别展示" --> UI_Handler[展示逻辑提取]
        Analyzer -- "识别逻辑" --> Logic_Handler[控制流提取]
    end
    
    subgraph User_Interaction [迁移向导 UI]
        Var_Handler --> |建议:注册属性| Wizard_Var[状态配置面板]
        UI_Handler --> |建议:转为UI组件| Wizard_UI[UI 配置面板]
        Logic_Handler --> |建议:转为触发器| Wizard_Logic[事件配置面板]
        
        Wizard_Var -- "用户确认" --> Action_Schema[生成 State Schema]
        Wizard_UI -- "用户确认" --> Action_View[生成 View Config / XML]
        Wizard_Logic -- "用户确认" --> Action_Rules[生成 Event Rules]
    end
    
    Action_Schema & Action_View & Action_Rules --> Reconstructor[重构器]
    Reconstructor --> Output[Clotho Native Card]
```

---

## 3. 模式识别与映射规则 (Pattern Recognition & Mapping)

分析器将根据以下特征模式，将杂乱的 EJS 代码映射到 Clotho 的子系统中：

### 3.1 状态定义模式 (Variable Definition Pattern)
*   **特征**: `getvar('key')`, `setvar('key', val)`, `variables.key`
*   **Clotho 目标**: **Mnemosyne State Schema**
*   **迁移策略**:
    *   自动提取所有出现的变量名。
    *   推断数据类型（Int, String, Bool）。
    *   引导用户设置初始值和范围（Min/Max）。

### 3.2 状态展示模式 (Status Display Pattern)
*   **特征**: `HP: <%- hp %>`, `Status: <%- status %>` (通常出现在 System Prompt 或 First Message 中)
*   **Clotho 目标**: **UI Extensions / Filament XML**
*   **迁移策略**:
    *   **移除**原文中的文本（避免 Prompt 污染）。
    *   **生成** Filament `<status>` 模板供 LLM 读取。
    *   **配置** Clotho UI 的状态栏组件，实现可视化渲染。

### 3.3 条件逻辑模式 (Conditional Logic Pattern)
*   **特征**: `<% if (hp < 10) { %> ... <% } %>`
*   **Clotho 目标**: **Event Manager (Triggers)**
*   **迁移策略**:
    *   提取判断条件 (`hp < 10`) 作为 **Trigger Condition**。
    *   提取内部文本作为 **Action Content** (如注入 System Prompt)。
    *   将逻辑从渲染时（每次生成都跑）转为事件驱动（满足条件才触发）。

### 3.4 复杂/未知模式 (Complex/Unknown Pattern)
*   **特征**: 循环 (`while/for`), 复杂运算, IO 操作
*   **Clotho 目标**: **Legacy Script (Sandbox) / Plugin API**
*   **迁移策略**:
    *   标记为 **"Legacy"**。
    *   提供“保留原样”选项（在受限沙箱中运行）。
    *   或引导用户重写为 **Jacquard Plugin** (Dart/WASM)。

---

## 4. 模块架构设计 (Module Architecture)

### 4.1 Clotho Migration Assistant (CMA)
位于 `lib/features/migration/` 下的独立功能模块。

```dart
abstract class MigrationStrategy {
  MigrationSuggestion analyze(String codeBlock);
  Future<MigrationResult> apply(MigrationAction action, CardContext context);
}

class VariableMigrationStrategy implements MigrationStrategy { ... }
class DisplayMigrationStrategy implements MigrationStrategy { ... }
class LogicMigrationStrategy implements MigrationStrategy { ... }
```

### 4.2 Linter & Suggester
基于正则或简单的 AST 分析（使用 `html` 或 `xml` 包辅助解析类 XML 结构，正则解析 EJS 标签）来理解代码意图。

*   **Input**: `String rawContent`
*   **Output**: `List<CodeBlockIssue>`
    *   `issueType`: `variable | display | logic | complex`
    *   `originalCode`: `<%- hp %>`
    *   `suggestion`: "Map to State 'hp'"

---

## 5. UI 向导设计原型 (Wizard UI Prototype)

界面采用分步引导 (Stepper) 形式：

1.  **Overview**: 显示卡片概览，扫描到的脚本数量。
2.  **State Configuration**:
    *   列表显示所有检测到的变量。
    *   提供类型下拉框 (Int/String)。
    *   提供 "Import to Schema" 勾选框。
3.  **Logic Review**:
    *   左侧显示原始 EJS 代码块（高亮）。
    *   右侧显示“Clotho 建议”：
        *   卡片: "检测到状态展示逻辑"
        *   按钮: "转换为 UI 组件" | "转换为 XML" | "保留代码"
4.  **Finish**: 生成新卡片预览，保存。

---

## 6. 总结 (Conclusion)

通过本设计，我们不仅实现了对 ST 生态的兼容，更借此机会将非结构化的数据进行了“清洗”和“升维”。这将使用户的存量资产在 Clotho 平台上焕发新生，获得更强的性能、更好的 UI 表现和更稳定的逻辑一致性。
