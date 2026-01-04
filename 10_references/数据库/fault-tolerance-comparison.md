# 容错设计对比：Clotho 结构化解析 vs. ACU 逻辑验证 (Fault Tolerance Comparison)

**版本**: 1.0.0
**日期**: 2026-01-03
**状态**: Draft

---

## 1. 核心差异总结 (Core Distinction)

| 特性 | Clotho (Streaming Fuzzy Corrector) | ACU (Medusa Protocol / Checklist) |
| :--- | :--- | :--- |
| **关注点** | **结构完整性 (Structural Integrity)** | **数据/逻辑正确性 (Semantic Correctness)** |
| **执行时机** | **实时流式 (Real-time Streaming)** | **生成后 (Post-generation)** |
| **解决的问题** | 标签未闭合、顺序错乱、格式缺失 | 幻觉、ID 错误、列不对齐、约束违规 |
| **修正方式** | 自动补全标签、状态机跳转 | 触发重试 (Retry)、生成修正 Prompt |
| **成本** | 极低 (正则/状态机) | 高 (需重新调用 LLM) |

## 2. Clotho 的现有优势：结构化解析

Clotho 的 `Filament Parser` 在处理**形式语法错误**方面已经非常强大。

*   **流式修正**: 它不需要等生成结束，就能一边接收一边修正。
    *   *User*: `think>...` (缺少 `<`) -> *Parser*: 自动补全 `<think>`。
*   **状态机鲁棒性**: 即使 LLM 忘记闭合标签，只要遇到下一个顶级标签，Parser 就会自动推断闭合。
*   **结论**: 我们**不需要**借鉴 ACU 的正则表达式匹配或 JSON 提取逻辑，因为 Filament Parser 更先进。

## 3. ACU 的关键补充：逻辑与语义验证

然而，Clotho 的 Parser 无法检测**内容错误**。如果 LLM 生成了符合语法但逻辑错误的指令，Parser 会照单全收。这正是 ACU "Medusa Protocol" 的价值所在。

### 3.1 Parser 无法覆盖的盲区 (The Gap)

*   **Schema 违规**: Parser 知道这是一个合法的 JSON，但不知道 `hp` 字段必须是数字，而不是字符串 "full"。
*   **幻觉引用**: Parser 不知道 `item_id: "excalibur"` 是否真的存在于数据库中。
*   **逻辑冲突**: Parser 不知道“同时增加好感度和减少好感度”是否合法。

### 3.2 ACU 的解决方案 (Medusa Check)

ACU 强制 LLM 输出一个 Checklist：
> "索引 ID 是否严格等于表头数字？[Yes]"
> "列号是否与表头定义完美对齐？[Yes]"

这利用了 LLM 的**自我反思 (Self-Reflection)** 能力。如果是 70B+ 的模型，让它“回头看一眼”往往能发现并修正自己的错误。

## 4. 集成建议：ValidatorShuttle

我们不应该修改 Filament Parser，而应该在 Jacquard 流水线中 Parser 之后增加一个 **Validator Shuttle**。

### 4.1 验证流程
1.  **Parsing**: Filament Parser 正常解析输出，生成结构化对象 (Schema Object)。
2.  **Validation (新)**: Validator Shuttle 接收 Schema Object。
    *   **静态检查**: 使用 Zod/Joi 等库检查数据类型（如：`hp` 必须是 `number`）。
    *   **动态检查**: 检查引用完整性（如：`item_id` 必须在 Mnemosyne 物品表中存在）。
3.  **Correction (新)**:
    *   如果验证失败，Validator Shuttle **不直接报错**。
    *   它构建一个 `Correction Prompt`: *"Error: 'hp' must be a number, got 'full'. Please fix."*
    *   触发 Jacquard 的 `Invoker` 进行一次快速重试（Temperature = 0）。

### 4.2 结论
Clotho 需要的是 **"语义验证" (Semantic Validation)**，而不是更多的"结构解析"。ACU 的 Checklist 思想应该演化为 Clotho 的 `Validator Shuttle`。
