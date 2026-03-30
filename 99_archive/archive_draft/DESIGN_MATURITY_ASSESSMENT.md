# 当前设计成熟度评估报告 (Current Design Maturity Assessment)

**日期**: 2026-01-10
**状态**: 核心审查 (Core Review)
**评估者**: 资深系统架构师 (Architect Mode)

---

## 1. 评估概览 (Executive Summary)

### 1.1 评估目的
本文档旨在对 Clotho 项目当前的设计文档（`00_active_specs/`）进行全面审计，识别从“架构设计”迈向“工程实现”过程中的缺口。目标是明确下一步的文档补全计划，确保开发团队能够进入 **L3 (可实现)** 阶段。

### 1.2 成熟度层级定义 (Maturity Levels)

*   **L0 - 概念级 (Conceptual)**: 仅确立了愿景、隐喻与核心哲学。回答“是什么”和“为什么”。
*   **L1 - 架构级 (Architectural)**: 定义了模块边界、职责划分、核心数据流与关键技术选型。回答“由什么组成”。
*   **L2 - 规格级 (Specified)**: 明确了关键接口、数据结构 (Schema)、协议格式与标准工作流。回答“如何交互”。
*   **L3 - 可实现级 (Implementable)**: 包含伪代码、算法细节、边缘情况处理、错误路径与具体 API 签名。开发人员可直接转换为代码。回答“如何编码”。

---

## 2. 子系统深度审计 (Subsystem Deep Audit)

### 2.1 Presentation Layer (The Stage)
**当前评级**: **L1.5 (架构清晰，细节待补)**

*   **已定义特性 (Defined Features)**:
    *   **布局哲学**: Stage & Control 分区，响应式三栏设计 (`core/presentation-layer.md`).
    *   **Hybrid SDUI 架构**: Native (RFW) 与 Web (WebView) 的双轨路由机制。
    *   **交互隔离**: InputDraft 单向数据流模式。
    *   **Inspector**: 基于 Schema 的数据可视化组件。

*   **待决/缺失特性 (Pending/Undocumented)**:
    *   **[Critical] RFW 协议细节**: 尚未定义 RFW 的二进制数据包格式、组件映射表以及如何动态加载 `.rfw` 文件。
    *   **[High] Web 桥接接口**: WebView 与 Dart 端的具体通信 API (`JSChannel` 消息格式) 未定义。
    *   **[Medium] 状态栏协议**: `<status_bar>` 在 Filament 协议中已定义，但前端如何解析并渲染其“自由结构”缺乏具体实现规范。
    *   **[Medium] UI 组件库**: 缺乏核心组件（如 ChatBubble, InputBox）的详细 UI/UX 规格（Props, States）。

### 2.2 Jacquard Layer (The Loom)
**当前评级**: **L2.0 (核心流程明确)**

*   **已定义特性 (Defined Features)**:
    *   **Pipeline 架构**: 明确的 9 阶段流水线 (Planner -> Builder -> Renderer ...)。
    *   **Skein 结构**: 异构容器、Block 定义、Weaving 算法 (`core/jacquard-orchestration.md`).
    *   **Jinja2 集成**: 明确了模板渲染在 Pipeline 中的位置与职责。

*   **待决/缺失特性 (Pending/Undocumented)**:
    *   **[Critical] 插件接口定义**: 缺乏 `JacquardPlugin` 的具体 Dart 接口签名 (Interface Definition)。
    *   **[High] Planner 逻辑细节**: Pre-Flash Planner 如何具体区分“数值交互”与“事件交互”？缺乏具体的 Prompt 策略或启发式规则。
    *   **[Medium] 错误恢复机制**: 当 LLM 返回非法的 Filament 格式或网络超时时，Pipeline 的重试与熔断机制未定义。
    *   **[Medium] 任务取消**: 用户中断生成时，Pipeline 如何优雅地取消正在进行的 LLM 请求与状态更新。

### 2.3 Muse Service (Intelligence)
**当前评级**: **L1.5 (架构成型，实现未定)**

*   **已定义特性 (Defined Features)**:
    *   **双层架构**: Raw Gateway 与 Agent Host 的职责分离 (`core/muse-intelligence-service.md`).
    *   **Agent 概念**: 上下文管理与技能挂载。

*   **待决/缺失特性 (Pending/Undocumented)**:
    *   **[Critical] 流式响应处理**: 缺乏从 LLM Chunk 到 Filament Parser 的流式数据管道的具体实现细节（Backpressure 处理）。
    *   **[High] Token 计费实现**: 计费模块的数据模型与统计逻辑未定义。
    *   **[Medium] 模型路由配置**: `router_config.yaml` 的具体结构未定义。

### 2.4 Mnemosyne Engine (Memory)
**当前评级**: **L2.5 (规格详尽)**

*   **已定义特性 (Defined Features)**:
    *   **数据架构**: 完整的 SQLite ER 图与 DDL 定义 (`mnemosyne/sqlite-architecture.md`).
    *   **数据模型**: VWD (Value with Description)、$meta 约束、OpLog 结构。
    *   **读写机制**: 稀疏快照、惰性求值视图、Deep Merge 算法。

*   **待决/缺失特性 (Pending/Undocumented)**:
    *   **[High] Patching 边缘情况**: 数组类型的 Patch 策略（覆盖 vs 追加 vs 指定索引修改）在 Deep Merge 算法中需更详细说明。
    *   **[Medium] 数据迁移机制**: 当 Schema 发生变更时（如应用升级），SQLite 数据库的 Migration 策略。
    *   **[Medium] 复杂查询性能**: 针对深层 JSON 路径查询的索引优化策略。

### 2.5 Infrastructure (Nexus)
**当前评级**: **L1.5 (基础稳固)**

*   **已定义特性 (Defined Features)**:
    *   **ClothoNexus**: 基于 Stream 的事件总线架构。
    *   **跨平台策略**: 依赖倒置、Repository 模式、MethodChannel 分离。

*   **待决/缺失特性 (Pending/Undocumented)**:
    *   **[High] 事件类定义**: `StateUpdatedEvent`, `UserIntentEvent` 等核心事件的具体 Payload 结构 (Dart Class) 未定义。
    *   **[High] 依赖注入方案**: 未指定具体的 DI 容器实现（GetIt? Riverpod?）及模块注册策略。
    *   **[Medium] 文件系统抽象**: 跨平台路径映射（AppDate, Cache, Temp）的具体规范。

### 2.6 Runtime Dynamics (Tapestry)
**当前评级**: **L2.0 (模型清晰)**

*   **已定义特性 (Defined Features)**:
    *   **L0-L3 分层**: 明确的层级职责与生命周期 (`runtime/layered-runtime-architecture.md`).
    *   **Patching 原理**: 写时复制与动态修补机制。

*   **待决/缺失特性 (Pending/Undocumented)**:
    *   **[High] 热重载 (Hot Reload)**: 在不重启会话的情况下，如何动态重新加载 L2 (Pattern) 的资源（如修改了 YAML 定义）？
    *   **[Medium] 会话并发**: 是否支持同时激活多个 Tapestry？如果支持，资源（内存/显存）如何调度？

---

## 3. 全系统差距分析 (System-wide Gap Analysis)

### 3.1 错误处理与恢复 (Error Handling & Recovery)
*   **缺失**: 目前文档多关注“正常路径 (Happy Path)”，缺乏统一的异常处理规范。
*   **需求**: 定义全局错误码规范 (Error Codes)、UI 层的错误呈现标准（Toast vs Dialog vs Inline）、以及关键业务的事务回滚机制。

### 3.2 配置管理 (Configuration Management)
*   **缺失**: 系统级配置（语言、主题、API Key、模型参数）的存储与同步方案未涉及。
*   **需求**: 设计 `Preferences` 模块，定义配置的 Schema、存储位置及变更通知机制。

### 3.3 安全性与隐私 (Security & Privacy)
*   **缺失**: 虽然提到了 ACL，但缺乏具体的加密存储方案（API Key 安全）、日志脱敏规范。
*   **需求**: 补充敏感数据存储规范 (SecureStorage)。

### 3.4 遥测与调试 (Telemetry & Debugging)
*   **缺失**: 缺乏日志分级标准、性能打点规范。
*   **需求**: 定义 `Logger` 接口与调试面板功能（查看实时 Prompt、Token 消耗）。

---

## 4. 后续设计行动项 (Design Action Items)

按优先级排序的文档补全计划：

### P0: 阻碍核心流程实现的缺失 (Blockers)
1.  **[Jacquard]** 撰写 `jacquard-plugin-interfaces.md`: 定义所有 Pipeline 插件的 Dart 接口签名。
2.  **[Muse]** 撰写 `muse-streaming-pipeline.md`: 详述流式响应处理、解析与背压控制逻辑。
3.  **[Infra]** 撰写 `clotho-nexus-events.md`: 定义核心事件总线的 Event Classes。
4.  **[Protocol]** 完善 `filament-parsing-workflow.md`: 补充错误修正与容错的具体算法。

### P1: 影响特定功能模块的缺失 (Critical)
5.  **[Stage]** 撰写 `sdui-rfw-protocol.md`: 定义 RFW 数据包结构与传输协议。
6.  **[Mnemosyne]** 补充 `mnemosyne-migration-strategy.md`: 数据库版本管理与迁移策略。
7.  **[Stage]** 撰写 `webview-bridge-api.md`: 定义 JS <-> Dart 通信接口。

### P2: 优化与增强类缺失 (Optimization)
8.  **[System]** 撰写 `error-handling-guidelines.md`: 全局错误码与处理规范。
9.  **[System]** 撰写 `configuration-management.md`: 用户首选项管理方案。
10. **[Runtime]** 细化 `hot-reload-mechanism.md`: 运行时资源热更流程。
