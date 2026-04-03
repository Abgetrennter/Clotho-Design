# Clotho 系统架构文档索引

**版本**: 3.2.0
**日期**: 2026-04-02
**状态**: Active

> 术语体系参见 [naming-convention.md](naming-convention.md)（技术术语）和 [metaphor-glossary.md](metaphor-glossary.md)（隐喻体系）

---

Clotho 是面向下一代 AI RPG 的高性能、确定性客户端。架构文档按领域分为六类：

## 1. 概览

- [vision-and-philosophy.md](vision-and-philosophy.md) — 愿景与设计哲学
- [architecture-principles.md](architecture-principles.md) — 架构原则
- [metaphor-glossary.md](metaphor-glossary.md) — 隐喻术语表
- [naming-convention.md](naming-convention.md) — 技术命名规范（开发者必读）

## 2. 子系统

**Jacquard 编排层** — [总览](jacquard/README.md) | [Planner](jacquard/planner-component.md) | [预设系统](jacquard/preset-system.md) | [能力系统](jacquard/capability-system-spec.md) | [插件架构](jacquard/plugin-architecture.md) | [Scheduler](jacquard/scheduler-component.md) | [Schema Injector](jacquard/schema-injector.md) | [Skein & Weaving](jacquard/skein-and-weaving.md)

**Mnemosyne 数据引擎** — [总览](mnemosyne/README.md) | [SQLite 架构](mnemosyne/sqlite-architecture.md) | [抽象数据结构](mnemosyne/abstract-data-structures.md) | [混合资源管理](mnemosyne/hybrid-resource-management.md) | [世界模型层](mnemosyne/world-model-layer.md) | [State Schema V2](mnemosyne/state_schema_v2_spec.md)

**表现层 (Stage)** — [总览](presentation/README.md)

**Muse 智能服务** — [总览](muse/README.md) | [Nexus 集成](muse/muse-nexus-integration.md) | [Provider Adapters](muse/muse-provider-adapters.md) | [Router Config](muse/muse-router-config.md) | [流式与计费](muse/streaming-and-billing-design.md)

## 3. 协议与格式 (Filament)

- [协议概述](protocols/filament-protocol-overview.md) | [输入格式](protocols/filament-input-format.md) | [输出格式](protocols/filament-output-format.md) | [解析流程](protocols/filament-parsing-workflow.md) | [Schema 库](protocols/schema-library.md) | [Jinja2 宏系统](protocols/jinja2-macro-system.md) | [接口定义](protocols/interface-definitions.md) | [跨模块接口契约草案](protocols/cross-module-interface-contracts.md)

## 4. 工作流

- [提示词处理](workflows/prompt-processing.md) | [角色卡导入](workflows/character-import-migration.md) | [迁移策略](workflows/migration-strategy.md) | [后生成处理](workflows/post-generation-processing.md)

## 5. 运行时

- [分层运行时架构](runtime/layered-runtime-architecture.md) | [运行时导读](runtime/README.md)

## 6. 基础设施

- [ClothoNexus 事件](infrastructure/clotho-nexus-events.md) | [依赖注入](infrastructure/dependency-injection.md) | [错误处理](infrastructure/error-handling-and-cancellation.md) | [文件系统抽象](infrastructure/file-system-abstraction.md) | [日志标准](infrastructure/logging-standards.md) | [多包架构](infrastructure/multi-package-architecture.md)

## 7. 参考

- [文档标准](reference/documentation_standards.md) | [宏系统规范](reference/macro-system-spec.md) | [ST 宏参考](reference/st-macro-reference.md) | [ACU 架构分析](reference/acu-architecture-analysis.md) | [架构审计](reference/architecture-audit-report.md) | [测试策略](reference/testing-strategy.md) | [历史归档](reference/legacy/)

## 阅读路径

**新用户**: vision-and-philosophy → metaphor-glossary → naming-convention → 按兴趣深入子系统
**开发者**: architecture-principles → naming-convention → 对应子系统目录

---

*最后更新: 2026-04-02*
