# 参考文档目录

**定位**: 技术参考、规范、API 文档  
**目标读者**: 技术开发者、集成工程师  
**文档状态**: 已完善 (2026-01-04)

---

## 📖 目录简介

本目录包含 Clotho 系统的技术参考文档，包括 API 规范、数据格式定义、配置参数以及对外部参考架构的深入分析。这些文档为开发者提供详细的技术参考，帮助理解系统的内部机制和扩展点。

## 📚 文档列表

### 1. 宏系统规范

- **文件**: [`macro-system-spec.md`](macro-system-spec.md)
- **简介**: Clotho 基于 Jinja2 的宏系统规范，定义了模板语法、上下文变量和安全限制。
- **核心内容**: Jinja2 语法、凯撒原则、与 ST 宏的对比迁移。

### 2. SillyTavern 宏参考

- **文件**: [`st-macro-reference.md`](st-macro-reference.md)
- **简介**: SillyTavern 宏定义的完整参考，主要用于兼容性开发和迁移对照。
- **核心内容**: 宏分类索引、功能描述、Clotho 迁移建议。

### 3. ACU 架构分析

- **文件**: [`acu-architecture-analysis.md`](acu-architecture-analysis.md)
- **简介**: 对神·数据库 (ACU) 插件的深度架构分析，解析其去中心化存储和自动更新机制。
- **核心内容**: 数据流转图、核心模块映射、对 Clotho 的设计启示。

### 4. API 参考 (计划中)

- **文件**: `api-reference.md`
- **简介**: Clotho 核心 API 的详细文档。
- **状态**: 待编写

### 5. 术语表 (计划中)

- **文件**: `glossary.md`
- **简介**: 系统核心术语的定义与解释。
- **状态**: 待编写

## 🧭 导航指南

### 从哪里开始？

如果您是**模板开发者**：

1. 阅读 [`macro-system-spec.md`](macro-system-spec.md) 掌握 Clotho 的模板语法。
2. 参考 [`st-macro-reference.md`](st-macro-reference.md) 了解如何迁移旧有的 ST 脚本。

如果您是**核心架构师**：

1. 阅读 [`acu-architecture-analysis.md`](acu-architecture-analysis.md) 理解 Mnemosyne 引擎的设计灵感来源。

### 相邻目录

- **核心架构** ([`../core/`](../core/)): 参考文档的架构背景
- **协议与格式** ([`../protocols/`](../protocols/)): 数据格式和协议规范
- **工作流与处理** ([`../workflows/`](../workflows/)): 业务流程参考
- **运行时环境** ([`../runtime/`](../runtime/)): 运行时参考

## 📝 文档更新记录

| 日期 | 版本 | 变更说明 |
|------|------|----------|
| 2026-01-04 | 1.1.0 | 补充了宏系统规范、ST 宏参考和 ACU 架构分析文档 |
| 2025-12-30 | 1.0.0 | 目录初始化 |

---

**最后更新**: 2026-01-04  
**维护者**: Clotho 技术文档团队
