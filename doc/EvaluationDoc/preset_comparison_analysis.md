# Preset Comparison: GrayWill (Import) vs. Yuan (Import)

| 特性 | GrayWill (`预设导入.json`) | Yuan (`元.json`) | Clotho 迁移策略 (Updates) |
| :--- | :--- | :--- | :--- |
| **Prompt Order** | 显式定义 `prompt_order` | 显式定义 `prompt_order` | **保持不变**。两者都依赖 `prompt_order` 数组，当前的 `SequenceStrategy` 可完美兼容。 |
| **Injection Depth** | 大量使用 (如 `depth: 4`) | 大量使用 (如 `depth: 4`, `depth: 0`) | **保持不变**。当前的 `DepthStrategy` 逻辑通用。 |
| **Regex Scripts** | **有** (用于 UI 修改/选项) | **无** (未发现类似 Regex 脚本) | **兼容**。Yuan 预设更纯粹，不需要复杂的 `<choice>` 转换，直接导入即可。 |
| **JS Scripts** | **有** (用于 `eval`/Dom 操作) | **无** (未发现 `<script>` 或 `cmd`) | **兼容**。Yuan 预设无不安全代码，风险更低。 |
| **Prompt 内容** | 复杂的 System/COT 引导 | 复杂的 System/COT 引导 | **保持不变**。都使用了 `{{setvar}}` 等宏，需通过变量映射表处理。 |
| **自定义宏** | 很多 (如 `{{getvar::思维链}}`) | 很多 (如 `{{setvar::梁元_...}}`) | **保持不变**。都需要“变量映射”步骤。Yuan 使用了大量中文变量名，Clotho 的 Jinja2 引擎原生支持 Unicode 变量名，无压力。 |
| **特殊标记** | `<thinking>`, `<ui_component>` | `<thinking>`, `<rigorous_thinking>` | **保持不变**。都是标准的 XML 标签，Filament 协议原生支持。 |

## 结论

`doc/EvaluationDoc/元.json` ("Yuan" 预设) 在结构上与 "GrayWill" 高度一致，但更纯粹（不包含 Regex/JS Hack）。这验证了我们的设计方向是正确的：

1.  **通用性强**: `Sequence` + `Depth` 策略足以覆盖这两种预设的编排需求。
2.  **安全性高**: Yuan 预设不需要额外的安全清洗步骤，导入流程会更顺畅。
3.  **变量映射是关键**: 两者都大量使用 ST 的变量系统 (`setvar`/`getvar`)，这再次强调了向导中 "Variable Mapping" 步骤的重要性。

无需针对 `元.json` 修改现有的 `plans/preset-import-design-spec.md` 或 `doc/design-specs/prompt_migration_spec.md`。现有的设计完全能够处理它。
