# 参考文档目录

**定位**: 技术参考、规范、API 文档  
**目标读者**: 技术开发者、集成工程师  
**文档状态**: 待完善 (2025-12-30)

---

## 📖 目录简介

本目录包含 Clotho 系统的技术参考文档，包括 API 规范、数据格式定义、配置参数等。这些文档为开发者提供详细的技术参考，帮助理解系统的内部机制和扩展点。

## 📚 文档列表 (待整理)

### 1. 宏系统规范

- **文件**: [`../../EvaluationDoc/macro_system_spec.md`](../../EvaluationDoc/macro_system_spec.md)
- **简介**: 详细的宏系统技术规范，包括语法定义、执行模型、安全限制。
- **状态**: 外部文档，暂未迁移

### 2. ST 宏参考

- **文件**: [`../../EvaluationDoc/micro.md`](../../EvaluationDoc/micro.md)
- **简介**: SillyTavern 宏系统的完整参考，用于迁移对照。
- **状态**: 外部文档，暂未迁移

### 3. 前端 UI 模块分析

- **文件**: [`../../EvaluationDoc/frontend-ui-modular-analysis.md`](../../EvaluationDoc/frontend-ui-modular-analysis.md)
- **简介**: 前端 UI 模块的详细分析，包括组件划分和通信机制。
- **状态**: 外部文档，暂未迁移

### 4. 历史工程化设计

- **文件**: [`../../EvaluationDoc/History_Engineering_Design.md`](../../EvaluationDoc/History_Engineering_Design.md)
- **简介**: 历史记录工程化设计的详细规范。
- **状态**: 外部文档，暂未迁移

### 5. 技术实现指南

- **文件**: [`../../EvaluationDoc/technical-implementation-guide.md`](../../EvaluationDoc/technical-implementation-guide.md)
- **简介**: 系统技术实现的详细指南。
- **状态**: 外部文档，暂未迁移

### 6. 预设导入分析

- **文件**: [`../../EvaluationDoc/preset_import_analysis.md`](../../EvaluationDoc/preset_import_analysis.md)
- **简介**: 预设导入的技术分析。
- **状态**: 外部文档，暂未迁移

### 7. 架构分析文档

- **文件**: [`../technical_specs/ACU_Architecture_Analysis.md`](../technical_specs/ACU_Architecture_Analysis.md)
- **简介**: ACU 架构的详细分析。
- **状态**: 内部文档，待迁移

### 8. JS 拆分合并分析

- **文件**: [`../technical_specs/js-split-merged-analysis.md`](../technical_specs/js-split-merged-analysis.md)
- **简介**: JS 代码拆分与合并的技术分析。
- **状态**: 内部文档，待迁移

## 🧭 导航指南

### 从哪里开始？

如果您是**技术开发者**：

1. 根据您的具体需求，查找相关的技术规范
2. 关注宏系统规范和历史工程化设计，了解核心机制

如果您是**集成工程师**：

1. 查看 API 规范和配置参数，了解系统扩展点
2. 关注迁移相关的参考文档，了解兼容性要求

### 相邻目录

- **核心架构** ([`../core/`](../core/)): 参考文档的架构背景
- **协议与格式** ([`../protocols/`](../protocols/)): 数据格式和协议规范
- **工作流与处理** ([`../workflows/`](../workflows/)): 业务流程参考
- **运行时环境** ([`../runtime/`](../runtime/)): 运行时参考

## 📝 迁移计划

当前参考文档分散在多个目录中，计划在未来版本中逐步迁移到本目录，形成统一的技术参考库。

| 优先级 | 文档 | 状态 | 计划完成时间 |
|--------|------|------|--------------|
| 高 | 宏系统规范 | 待迁移 | 2026-Q1 |
| 高 | ST 宏参考 | 待迁移 | 2026-Q1 |
| 中 | 前端 UI 模块分析 | 待迁移 | 2026-Q2 |
| 中 | 历史工程化设计 | 待迁移 | 2026-Q2 |
| 低 | 其他技术文档 | 待评估 | 待定 |

---

**最后更新**: 2025-12-30  
**维护者**: Clotho 技术文档团队
