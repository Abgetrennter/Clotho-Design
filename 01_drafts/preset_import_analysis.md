# 预设导入分析报告：GrayWill 灰魂

**日期**: 2025-12-28
**来源**: `doc/EvaluationDoc/预设导入.json`
**目标**: 评估将 SillyTavern 预设（含 Prompt 策略、Regex 替换、JS 脚本）迁移至 Clotho 架构的可行性与方案。

---

## 1. 概览 (Overview)

该预设文件属于 "GrayWill"（灰魂）项目，具有高度定制化的特征。它不仅包含了常规的生成参数，还深度依赖：
1.  **UI 美化**: 通过 Regex 将简单的 `<xx>` 标签替换为复杂的 HTML/CSS 卡片 (`Nova Silent Sky` 风格)。
2.  **客户端干涉**: 通过 JS 脚本监听 `<attack>` 标签，执行震动、弹窗、覆盖层、跳转甚至任意代码执行 (`cmd`)。

**主要挑战**: Clotho 架构基于 Flutter 原生渲染且严禁 `eval`，无法直接运行原本基于 DOM 操作和 JS 注入的代码。需要将“代码逻辑”转译为“协议指令”。

---

## 2. 生成参数与 Prompt 结构 (Generation & Prompt)

### 2.1 参数映射
大部分生成参数可直接映射到 Clotho 的 `Jacquard` 配置中。

| ST 参数 | 值 | Clotho 映射 | 备注 |
|---|---|---|---|
| `temperature` | 1.15 | `LLMConfig.temperature` | |
| `top_p` | 0.98 | `LLMConfig.top_p` | |
| `top_k` | 50 | `LLMConfig.top_k` | |
| `min_p` | 0 | `LLMConfig.min_p` | |
| `repetition_penalty` | 1 | `LLMConfig.repetition_penalty` | |
| `openai_max_context` | 2000000 | `Mnemosyne.contextWindow` | Clotho 自动管理滑动窗口 |
| `impersonation_prompt` | `[灰魂帮我作为{{user}}简短的输出接下来的行动.]` | `Skein.ImpersonateBlock` | 标准功能 |

### 2.2 Prompt 注入与排序

该预设自定义了 `prompts` 数组和 `prompt_order`。
*   **自定义 Prompt**: "到处都是灰魂！" (System Role) -> 可迁移至 Clotho 的 `System Instruction` 或 `World Info` (Global)。
*   **Ordering**: ST 允许极其细粒度的排序。Clotho 的 `Skein` 构建器通常遵循固定逻辑结构（System -> User/Char Info -> World Info -> History）。
    *   **建议**: 保持 Clotho 标准结构通常能获得更好的指令遵循能力。如有特殊需求，需通过 `Jacquard` 的 Pipeline 配置进行调整。
*   **手动分组**: 由于预设包含大量 Prompt（如 "三选一" 的模型启用选项），建议在导入向导中提供手动分组功能，让用户自行组织和管理这些 Prompt。
---

## 3. 正则脚本分析 (Regex Scripts)

该预设包含两个主要的 Regex 脚本，主要用于 UI 变换。

### 3.1 脚本 1: 小cot折叠
*   **功能**: 将 `<think>`...`</think>` 替换为 `<details>...`.
*   **Clotho 方案**: **原生支持**。
    *   Clotho 的 `Filament` 协议原生定义了 `<thought>` 标签。
    *   UI 层 (`Presentation`) 会自动将思维链渲染为可折叠区域，无需正则替换。

### 3.2 脚本 2: 美化选项列表2 (Nova Silent Sky)
*   **功能**: 检测 `<xx>选项:描述 Tips:提示</xx>`，替换为极复杂的 HTML 卡片结构（含 CSS 动画、渐变、JS 交互）。
*   **问题**: Clotho 是 Flutter 应用，不支持在聊天气泡中渲染完整的 HTML/CSS 页面结构（虽然支持 WebView，但性能和交互隔离是问题）。
*   **Clotho 方案**: **语义映射 + 原生组件**。
    *   **语义层**: 将 `<xx>` 映射为 Filament 协议的 `<choice>` 标签。
    *   **表现层**: 开发一个名为 `NovaTheme` 的 Flutter 组件，在 `ChoiceRenderer` 中使用。
    *   **数据结构变换**:
        ```xml
        <!-- 原输入 -->
        <xx>调查:查看周围情况 Tips:可能发现线索</xx>

        <!-- 迁移后 Filament -->
        <choice>
          <option id="1">
            <label>调查</label>
            <description>查看周围情况</description>
            <hint>可能发现线索</hint>
          </option>
        </choice>
        ```
    *   **优势**: 获得原生性能（如 60fps 动画），且适配移动端/桌面端布局，无需 hack DOM。

---

## 4. JS 脚本分析 (GrayWill LLM Intervention)

这是最复杂的迁移部分。原脚本 `灰魂LLM干涉脚本` 监听 `<attack>` 标签并执行多种浏览器级操作。

### 4.1 功能矩阵与迁移策略

| ST 指令 (Attack Tag) | 功能描述 | Clotho 迁移方案 (Filament Protocol) | 安全性/可行性 |
|---|---|---|---|
| `alert(msg)` | 弹窗警告 | `<ui_component type="toast" level="warning">msg</ui_component>` | ✅ 高 |
| `title(text)` | 修改网页标题 | `<status_update target="window_title">text</status_update>` | ✅ 高 (仅桌面端有效) |
| `shake(int, dur)` | 窗口震动 | `<ui_component type="effect.shake" intensity="..." />` | ✅ 高 (Flutter 动画) |
| `overlay(html, btn)` | 全屏覆盖层 | `<ui_component type="modal.overlay">` (支持受限 HTML) | ⚠️ 中 (需清洗 HTML) |
| `download(file, txt)` | 触发文件下载 | `<tool_call name="file.save">` (需用户权限确认) | ⚠️ 中 (需沙箱隔离) |
| `redirect(url)` | 网页跳转 | `<tool_call name="browser.open">` (需用户确认) | ✅ 高 |
| `startChaos()` | 元素乱飞 | **不支持 DOM 操作**。需用 Flutter 实现特定全屏特效 (Effect Layer)。 | ❌ 原理不通，需重写特效 |
| `colorModule` | 滤镜轮转 | `<ui_component type="effect.filter_cycle">` | ✅ 高 |
| **`cmd(code)`** | **任意代码执行** | **❌ 严禁支持**。Clotho 架构设计原则禁止 `eval`。 | **🚫 阻断** |

### 4.2 核心矛盾：代码 vs 协议
原脚本允许 LLM 输出 `cmd("console.log(...)")`。这在 Clotho 中是绝对禁止的（"凯撒原则"：逻辑归代码，LLM 不执行代码）。
*   **解决方案**: 将原本通过 `cmd` 实现的逻辑，抽象为预定义的 **Native Effects** 或 **Script Plugins (Lua/QuickJS)**。
    *   例如，如果 `cmd` 用来修改变量，应使用 `<variable_update>`。
    *   如果 `cmd` 用来播放特殊音效，应使用 `<media type="audio">`。

---

## 5. 迁移建议总结 (Recommendations)

1.  **协议化改造**: 放弃 regex 和 eval，全面转向 Filament 协议。
    *   `<xx>` -> `<choice>`
    *   `<attack>` -> `<tool_call>` 或 `<ui_component>`
2.  **UI 组件开发**: 为 "Nova Silent Sky" 风格开发对应的 Flutter Widget，作为 Clotho 的内置主题或扩展包。
3.  **安全性清洗**: 在导入过程中，自动识别并移除 `cmd()` 调用，或提示用户将其转换为安全的工具调用。
4.  **特效层实现**: 在 Clotho 的 `Infrastructure` 层实现 `Vibration` (震动), `Overlay` (覆盖), `Filter` (滤镜) 等标准接口，供协议调用。

此方案能保留原预设 90% 以上的沉浸式体验（UI、特效、交互），同时解决原方案的安全隐患和性能瓶颈。
