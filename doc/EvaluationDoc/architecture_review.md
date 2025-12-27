# Clotho 架构决策记录 (Architecture Decision Record)

**日期**: 2025-12-19
**状态**: 已确认 (Confirmed)
**参考文档**: `doc/architecture/system_architecture.md`, `doc/History_Engineering_Design.md`

---

## 1. 关键架构决策 (Key Architectural Decisions)

基于架构审查与用户反馈，确立以下核心设计原则：

### 1.1 状态存储策略：关键帧 + 增量 (Keyframe + Delta)
*   **背景**: 原设计中 `ContextNode` 存储全量 `stateSnapshot`，可能导致数据库体积随对话长度线性甚至指数级增长。
*   **决策**: 采用 **关键帧 (Keyframe) + 增量 (Delta)** 策略。
    *   **机制**: 每隔 N 个节点（例如 10 或 50）存储一次全量状态快照（Keyframe）。
    *   **增量**: 中间节点仅存储相对于上一个节点的变更 Diff（Delta）。
    *   **读取**: 读取状态时，从最近的 Keyframe 开始应用后续的 Delta。
*   **状态**: ✅ 已确认。

### 1.2 Filament 解析安全：严格白名单 (Strict Whitelist)
*   **背景**: Filament 协议规定内容无转义，LLM 生成的数学符号（如 `1 < 2`）可能干扰解析。
*   **决策**: 维护严格的 **白名单 (Strict Whitelist)**。
    *   **机制**: 解析器仅识别预定义的标签（如 `<thought>`, `<reply>`, `<state_update>`）。
    *   **容错**: 所有不在白名单内的 `<` 符号一律视为普通文本，不进行标签解析。
    *   **Prompt**: 在 System Prompt 中明确告知 LLM 仅使用白名单内的标签。
*   **状态**: ✅ 已确认。

### 1.3 Jacquard 机制：暂缓中断恢复 (Defer Suspend & Resume)
*   **背景**: 高级 Agent 可能需要异步中断。
*   **决策**: **暂不引入** "中断-恢复"机制。
*   **原因**: 现阶段无明确需求，且增加系统复杂度。列为未来特性。
*   **状态**: ⏸️ 暂缓 (Future Scope)。

### 1.4 性能优化：暂缓热路径缓存 (Defer Hot Path Caching)
*   **背景**: 长对话回溯可能存在性能瓶颈。
*   **决策**: **暂不引入** 热路径缓存。
*   **原因**: 预期对话长度不超过 2000 轮，全量回溯的性能在可接受范围内。
*   **状态**: ⏸️ 暂缓 (Not Needed)。

---

## 2. 实施路线图 (Implementation Roadmap)

根据上述决策调整后的实施计划：

### Phase 1: 核心数据层 (Foundation)
*   **目标**: 建立支持多重宇宙树的数据库结构。
*   **任务**:
    1.  [ ] **Drift Schema**: 初始化数据库，实现 `ContextNode`, `MessageNode`, `Session` 等核心表结构。
    2.  [ ] **HistoryRepository**: 实现树状节点的插入、查询与更新接口。
    3.  [ ] **ProjectionService**: 实现从树状结构到线性历史的 `TraceBack` 投影算法。
    4.  [ ] **Unit Tests**: 编写单元测试，重点验证"回溯"算法与"分支切换"逻辑的正确性。

### Phase 2: 业务逻辑层 (Engine)
*   **目标**: 实现状态管理与快照机制。
*   **任务**:
    1.  [ ] **Mnemosyne**: 实现系统的单一事实来源 (Single Source of Truth)。
    2.  [ ] **Snapshot Strategy**: 实现 **关键帧 + 增量** 的存储与还原逻辑。
    3.  [ ] **Context Assembly**: 实现 `Punchcards` 的聚合逻辑。

### Phase 3: 编排层 (Jacquard)
*   **目标**: 实现插件化流水线与 Filament 解析。
*   **任务**:
    1.  [ ] **Pipeline Core**: 定义 `JacquardPlugin` 接口与 `JacquardRunner`。
    2.  [ ] **Filament Parser**: 升级 `StreamFilamentParser`，实现 **白名单过滤** 逻辑。
    3.  [ ] **Prompt Assembler Shuttle**: 实现 Shuttle，对接 `Mnemosyne` 获取 Punchcards 并组装 Prompt。
    4.  [ ] **Mock LLM**: 实现 `MockLLMInvoker`，打通从 Input 到 Filament 解析的完整链路。

### Phase 4: 表现层 (Presentation)
*   **目标**: 接入 UI 并验证交互。
*   **任务**:
    1.  [ ] **ChatPage Refactor**: 改造现有 ChatPage，接入真实的 `Jacquard`。
    2.  [ ] **Branch UI**: 实现简单的"历史分支导航" UI，验证多重宇宙树的交互体验。