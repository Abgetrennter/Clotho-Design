# Clotho x ACU 集成路线图 (Clotho x ACU Integration Roadmap)

**版本**: 1.1.0
**日期**: 2026-01-03
**状态**: Draft
**目标**: 通过集成 Auto Card Updater (ACU) 插件中经过验证的稳定性和记忆模式，强化 Clotho 的架构。

---

## Phase 1: Mnemosyne Schema 强化 (数据层)

**目标**: 增强数据引擎，支持显式的叙事链接和递归规划状态。

### 1.1 `GlobalEvent` Schema 更新
*   **任务**: 扩展 `GlobalEvent` schema 以支持对原始聊天日志的显式引用（"AMxx" 模式）。 
*   **行动**:
    *   修改 `structure/core/mnemosyne-data-engine.md` 中的 Schema 定义。
    *   在 `GlobalEvent` 中增加 `linked_logs` (List<String>) 字段。
    *   在 `ChatMessage` 元数据中增加 `snapshot_ref` (String)，允许无需完全重放即可进行“时间旅行”查找。

### 1.2 `SessionState` 扩展以支持规划器
*   **任务**: 为“叙事规划器”创建一个专用槽位。
*   **行动**:
    *   在 L3 Session State Schema 中增加 `planner_context`。
    *   定义结构: `{"current_goal": string, "pending_steps": list, "last_plan_summary": string}`。
    *   这对应于 ACU 的 `$6` 占位符机制。

---

## Phase 2: Jacquard 流水线扩展 (编排层)

**目标**: 引入异步维护和语义级自我修正能力 (Semantic Self-Correction)。

### 2.1 异步批处理处理器 ("Updater" 等价物)
*   **任务**: 创建一种用于后台任务的新流水线类型，支持 Fail-Fast 和断点续传。
*   **行动**:
    *   在 `structure/core/jacquard-orchestration.md` 中定义 `MaintenancePipeline`。
    *   实现 `BatchProcessorShuttle`:
        *   接受一系列消息 ID。
        *   请求 `Mnemosyne` 在 `start_index` 处回填 (hydrate) 状态。
        *   生成总结/状态更新。
        *   通过 `OpLog` 提交变更。

### 2.2 验证 Shuttle (语义级 "Medusa" 协议)
*   **任务**: 在 Filament 结构修复后，增加逻辑/语义验证步骤。
*   **行动**:
    *   创建 `ValidatorShuttle` 规范 (作为 `FilamentParser` 的下游)。
    *   逻辑:
        *   接收 `FilamentParser` 的输出 (此时结构已由 Fuzzy Corrector 修复)。
        *   **语义检查 (Semantic Check)**: 验证数据一致性 (e.g., 引用 ID 是否存在? 数值是否越界? 逻辑是否自洽?)。
        *   如果无效，构造一个包含错误详情的 `RepairPrompt` 并重新调用 LLM（最大重试次数 = 1）。

---

## Phase 3: Filament 协议更新 (接口层)

**目标**: 标准化新的输入和输出。

### 3.1 递归规划标签
*   **任务**: 定义规划器如何与生成器通信。
*   **行动**:
    *   在 Filament 输入协议 (`structure/protocols/filament-input-format.md`) 中增加 `<planner_context>` 标签。
    *   在 Filament 输出协议 (`structure/protocols/filament-output-format.md`) 中增加 `<update_plan>` 标签，以便模型更新其自己的计划。

### 3.2 验证标签
*   **任务**: 正式化“清单”输出。
*   **行动**:
    *   在输出协议中增加可选的 `<verification>` 块。
    *   示例: `<verification>Checked: ID Match [x]</verification>`。

---

## Phase 4: 实施顺序

1.  **Schema 更新**: 首先修改 Mnemosyne 定义 (Phase 1)。
2.  **协议定义**: 更新 Filament 规范以支持新标签 (Phase 3)。
3.  **Shuttle 逻辑**: 设计 Batch & Validation shuttle 的详细逻辑 (Phase 2)。
4.  **集成测试**: 模拟“长聊天”场景以验证批处理和记忆稳定性。
