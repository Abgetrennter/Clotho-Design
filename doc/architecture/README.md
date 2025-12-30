# Clotho 系统架构文档索引

**版本**: 2.0.0
**日期**: 2025-12-30
**状态**: Reorganized
**作者**: Clotho 文档重构团队

---

## 📖 文档简介

欢迎阅读 Clotho 系统架构文档。Clotho 是一个面向下一代 AI 角色扮演（RPG）的高性能、确定性客户端，旨在解决现有方案（如 SillyTavern）在逻辑处理、上下文管理和性能上的根本性痛点。

本文档系列采用全新的分层结构组织，旨在提供逻辑清晰、易于导航和理解的架构参考。

## 🏗️ 文档结构概览

Clotho 架构文档按逻辑领域划分为六个主要类别，每个类别包含若干详细文档：

```mermaid
graph TD
    ROOT[架构文档] --> OVERVIEW[概览 Overview]
    ROOT --> CORE[核心架构 Core Architecture]
    ROOT --> PROTOCOLS[协议与格式 Protocols & Formats]
    ROOT --> WORKFLOWS[工作流与处理 Workflows]
    ROOT --> RUNTIME[运行时环境 Runtime]
    ROOT --> REFERENCE[参考 Reference]
    
    OVERVIEW --> O1[愿景与哲学]
    OVERVIEW --> O2[架构原则]
    OVERVIEW --> O3[快速入门]
    
    CORE --> C1[Jacquard 编排层]
    CORE --> C2[Mnemosyne 数据引擎]
    CORE --> C3[表现层]
    CORE --> C4[基础设施层]
    
    PROTOCOLS --> P1[Filament 协议概述]
    PROTOCOLS --> P2[输入格式 (XML+YAML)]
    PROTOCOLS --> P3[Jinja2 宏系统]
    PROTOCOLS --> P4[输出格式 (XML+JSON)]
    PROTOCOLS --> P5[解析流程]
    
    WORKFLOWS --> W1[提示词处理工作流]
    WORKFLOWS --> W2[角色卡导入与迁移]
    WORKFLOWS --> W3[迁移指南]
    
    RUNTIME --> R1[分层运行时架构]
    RUNTIME --> R2[状态管理与 Patching]
    
    REFERENCE --> REF1[术语表]
    REFERENCE --> REF2[API 参考]
    REFERENCE --> REF3[配置指南]
```

## 📚 文档类别详解

### 1. 概览 (Overview)
- **定位**: 高层次介绍与入门指引
- **内容**: 项目愿景、设计哲学、核心概念、快速入门
- **目标读者**: 新用户、项目管理者、外部合作者
- **文件列表**:
  - [`vision-and-philosophy.md`](overview/vision-and-philosophy.md) - 愿景与哲学
  - [`architecture-principles.md`](overview/architecture-principles.md) - 架构原则
  - [`quick-introduction.md`](quick-introduction.md) - AI 快速了解（根目录）

### 2. 核心架构 (Core Architecture)
- **定位**: 系统核心组件的详细设计
- **内容**: 三大生态（编排、数据、表现）与基础设施
- **目标读者**: 系统架构师、核心开发者
- **文件列表**:
  - [`jacquard-orchestration.md`](core/jacquard-orchestration.md) - Jacquard 编排层
  - [`mnemosyne-data-engine.md`](core/mnemosyne-data-engine.md) - Mnemosyne 数据引擎
  - [`presentation-layer.md`](core/presentation-layer.md) - 表现层
  - [`infrastructure-layer.md`](core/infrastructure-layer.md) - 基础设施层

### 3. 协议与格式 (Protocols & Formats)
- **定位**: 系统间通信的标准化协议
- **内容**: Filament 协议规范、模板引擎、数据格式
- **目标读者**: 协议开发者、集成工程师
- **文件列表**:
  - [`filament-protocol-overview.md`](protocols/filament-protocol-overview.md) - Filament 协议概述
  - [`filament-input-format.md`](protocols/filament-input-format.md) - 输入格式 (XML+YAML)
  - [`jinja2-macro-system.md`](protocols/jinja2-macro-system.md) - Jinja2 宏系统
  - [`filament-output-format.md`](protocols/filament-output-format.md) - 输出格式 (XML+JSON)
  - [`filament-parsing-workflow.md`](protocols/filament-parsing-workflow.md) - 解析流程

### 4. 工作流与处理 (Workflows)
- **定位**: 具体业务处理流程
- **内容**: 提示词处理、角色卡迁移、用户交互
- **目标读者**: 功能开发者、迁移专家
- **文件列表**:
  - [`prompt-processing.md`](workflows/prompt-processing.md) - 提示词处理工作流
  - [`character-import-migration.md`](workflows/character-import-migration.md) - 角色卡导入与迁移
  - [`migration-strategy.md`](workflows/migration-strategy.md) - 迁移策略

### 5. 运行时环境 (Runtime)
- **定位**: 系统运行时行为与状态管理
- **内容**: 分层运行时架构、状态管理、Patching 机制
- **目标读者**: 运行时工程师、状态管理开发者
- **文件列表**:
  - [`layered-runtime-architecture.md`](runtime/layered-runtime-architecture.md) - 分层运行时架构
  - [`state-management-and-patching.md`](runtime/state-management-and-patching.md) - 状态管理与 Patching

### 6. 参考 (Reference)
- **定位**: 技术参考与工具文档
- **内容**: 术语表、API 参考、配置指南
- **目标读者**: 所有技术用户
- **文件列表**:
  - [`glossary.md`](reference/glossary.md) - 术语表
  - [`api-reference.md`](reference/api-reference.md) - API 参考
  - [`configuration.md`](reference/configuration.md) - 配置指南

## 🚀 快速开始

### 新用户阅读路径
1. **第一步**: 阅读 [`quick-introduction.md`](quick-introduction.md) 快速了解项目
2. **第二步**: 阅读 [`overview/vision-and-philosophy.md`](overview/vision-and-philosophy.md) 理解设计理念
3. **第三步**: 浏览 [`core/`](core/) 目录了解核心组件
4. **第四步**: 根据兴趣深入特定领域

### 开发者阅读路径
1. **架构师**: 关注 `core/` 和 `runtime/` 目录
2. **协议开发者**: 关注 `protocols/` 目录
3. **迁移工程师**: 关注 `workflows/` 目录
4. **集成工程师**: 关注 `reference/` 目录

## 🔗 相关资源

- **历史归档**: [`legacy_archive/`](../legacy_archive/) - 旧版设计文档
- **技术规范**: [`technical_specs/`](../technical_specs/) - 详细技术规范
- **评估文档**: [`EvaluationDoc/`](../EvaluationDoc/) - 评估与分析
- **计划文档**: [`plans/`](../../plans/) - 项目计划与设计

## 📝 文档更新说明

本文档系列于 2025-12-30 进行了全面重组，采用了新的分层结构和语义化命名。如果您发现任何问题或缺失，请通过项目 Issue 系统反馈。

**重要变更**:
- 将原有的 10 个数字前缀文件重组为 6 个逻辑类别
- 将 Filament 协议文档拆分为 5 个专题文件
- 合并了迁移相关的重复内容
- 新增了快速介绍、术语表、API 参考等实用文档

---

*最后更新: 2025-12-30*  
*文档版本: 2.0.0*