# Clotho 系统架构文档索引

**版本**: 3.1.0
**日期**: 2026-03-11
**状态**: Active
**作者**: Clotho 文档重构团队

---

## 📖 术语使用说明

Clotho 项目采用**双术语体系**，请根据场景选择合适的术语：

| 场景 | 推荐术语体系 | 文档链接 |
|-----|------------|---------|
| **架构设计文档** | 隐喻体系 (Metaphor) | [`metaphor-glossary.md`](metaphor-glossary.md) |
| **代码实现** | 技术语义体系 (Technical) | [`naming-convention.md`](naming-convention.md) |
| **用户界面** | 技术语义体系 | [`naming-convention.md`](naming-convention.md) |
| **对外交流** | 视受众而定 | 两者混合使用 |

### 快速映射表

| 隐喻术语 | 技术术语 | 代码示例 |
|---------|---------|---------|
| Tapestry (织卷) | **Session** (会话) | `final session = await getSession(id);` |
| Pattern (织谱) | **Persona** (角色设定) | `final persona = session.persona;` |
| Threads (丝络) | **Context** (上下文) | `final context = session.context;` |
| Punchcards (穿孔卡) | **Snapshot** (快照) | `final snapshot = await createSnapshot(id);` |
| Skein (绞纱) | **PromptBundle** (提示词包) | `final bundle = await assemblePrompt(id, input);` |

> 💡 **简单规则**: 写代码时，请将隐喻术语"翻译"为 [`naming-convention.md`](naming-convention.md) 中的技术术语。

---

## 📖 文档简介

欢迎阅读 Clotho 系统架构文档。Clotho 是一个面向下一代 AI 角色扮演（RPG）的高性能、确定性客户端，旨在解决现有方案（如 SillyTavern）在逻辑处理、上下文管理和性能上的根本性痛点。

本文档系列采用全新的分层结构组织，旨在提供逻辑清晰、易于导航和理解的架构参考。

## 🏗️ 文档结构概览

Clotho 架构文档按逻辑领域划分为六个主要类别，每个类别包含若干详细文档：

```mermaid
graph TD
    ROOT[架构文档] --> OVERVIEW[概览 Overview]
    ROOT --> SUBSYSTEMS[子系统 Subsystems]
    ROOT --> PROTOCOLS[协议与格式 Protocols & Formats]
    ROOT --> WORKFLOWS[工作流与处理 Workflows]
    ROOT --> RUNTIME[运行时环境 Runtime]
    ROOT --> REFERENCE[参考 Reference]
    
    OVERVIEW --> O1[愿景与哲学]
    OVERVIEW --> O2[架构原则]
    OVERVIEW --> O3[术语表]
    
    SUBSYSTEMS --> S1[Jacquard 编排层]
    SUBSYSTEMS --> S2[Mnemosyne 数据引擎]
    SUBSYSTEMS --> S3[表现层]
    SUBSYSTEMS --> S5[Muse 智能服务]
    
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
    
    REFERENCE --> REF1[文档标准]
    REFERENCE --> REF2[ACU 架构分析]
    REFERENCE --> REF3[宏系统规范]
    REFERENCE --> REF4[ST 宏参考]
```

## 📚 文档类别详解

### 1. 概览 (Overview)

- **定位**: 高层次介绍与入门指引
- **内容**: 项目愿景、设计哲学、核心概念、快速入门
- **目标读者**: 新用户、项目管理者、外部合作者
- **文件列表**:
  - [`vision-and-philosophy.md`](vision-and-philosophy.md) - 愿景与哲学
  - [`architecture-principles.md`](architecture-principles.md) - 架构原则
  - [`metaphor-glossary.md`](metaphor-glossary.md) - 术语表与隐喻体系（纺织隐喻）
  - [`naming-convention.md`](naming-convention.md) - 命名规范（技术语义体系）

### 2. 子系统 (Subsystems)

- **定位**: 系统核心组件的详细设计
- **内容**: 四大子系统（编排、数据、表现、智能服务）
- **目标读者**: 系统架构师、核心开发者
- **文件列表**:
  - **Jacquard 编排层**:
    - [`jacquard/README.md`](jacquard/README.md) - Jacquard 编排层总览
    - [`jacquard/planner-component.md`](jacquard/planner-component.md) - Planning Phase (Planner) 组件
    - [`jacquard/preset-system.md`](jacquard/preset-system.md) - 预设与能力系统
    - [`jacquard/capability-system-spec.md`](jacquard/capability-system-spec.md) - 能力系统详细规范
    - [`jacquard/plugin-architecture.md`](jacquard/plugin-architecture.md) - 插件架构规范
    - [`jacquard/scheduler-component.md`](jacquard/scheduler-component.md) - Scheduler 调度器组件
  - **Mnemosyne 数据引擎**:
    - [`mnemosyne/README.md`](mnemosyne/README.md) - Mnemosyne 数据引擎总览
    - [`mnemosyne/sqlite-architecture.md`](mnemosyne/sqlite-architecture.md) - SQLite 物理存储架构
    - [`mnemosyne/abstract-data-structures.md`](mnemosyne/abstract-data-structures.md) - 抽象数据结构
    - [`mnemosyne/hybrid-resource-management.md`](mnemosyne/hybrid-resource-management.md) - 混合资源管理与 Asset 协议
  - **表现层**:
    - [`presentation/README.md`](presentation/README.md) - 表现层总览
  - **Muse 智能服务**:
    - [`muse/README.md`](muse/README.md) - Muse 智能服务总览

### 3. 协议与格式 (Protocols & Formats)

- **定位**: 系统间通信的标准化协议
- **内容**: Filament 协议规范、模板引擎、数据格式
- **目标读者**: 协议开发者、集成工程师
- **文件列表**:
  - [`filament-protocol-overview.md`](protocols/filament-protocol-overview.md) - Filament 协议概述
  - [`filament-input-format.md`](protocols/filament-input-format.md) - 输入格式 (XML+YAML)
  - [`schema-library.md`](protocols/schema-library.md) - Schema 库规范
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
  - [`README.md`](runtime/README.md) - 运行时环境导读

### 6. 参考 (Reference)

- **定位**: 技术参考与工具文档
- **内容**: 术语表、API 参考、配置指南、架构分析、**文档标准**
- **目标读者**: 所有技术用户、**文档贡献者**
- **文件列表**:
  - [`reference/documentation_standards.md`](reference/documentation_standards.md) - 文档编写与检查规范 (Documentation Writing & Checking Guidelines)
  - [`reference/macro-system-spec.md`](reference/macro-system-spec.md) - 宏系统规范 (Clotho/Jinja2)
  - [`reference/st-macro-reference.md`](reference/st-macro-reference.md) - SillyTavern 宏参考
  - [`reference/acu-architecture-analysis.md`](reference/acu-architecture-analysis.md) - ACU 架构分析
  - [`reference/README.md`](reference/README.md) - 参考文档导读

## 🚀 快速开始

### 新用户阅读路径

1. **第一步**: 阅读 [`vision-and-philosophy.md`](vision-and-philosophy.md) 理解设计理念
2. **第二步**: 阅读 [`metaphor-glossary.md`](metaphor-glossary.md) 理解核心隐喻概念
3. **第三步**: 阅读 [`naming-convention.md`](naming-convention.md) 了解技术命名规范（开发者必读）
4. **第四步**: 根据兴趣深入特定子系统目录

### 开发者阅读路径

1. **架构师**: 关注各子系统目录 (`jacquard/`, `mnemosyne/`, `presentation/`, `muse/`)
2. **协议开发者**: 关注 `protocols/` 目录
3. **迁移工程师**: 关注 `workflows/` 目录
4. **集成工程师**: 关注 `reference/` 目录

## 🔗 相关资源

- **历史归档**: [`reference/legacy/`](reference/legacy/) - 旧版设计文档
- **技术规范**: [`../doc/technical_specs/`](../doc/technical_specs/) - 详细技术规范
- **评估文档**: [`../doc/EvaluationDoc/`](../doc/EvaluationDoc/) - 评估与分析
- **计划文档**: [`../plans/`](../plans/) - 项目计划与设计

## 📝 文档更新说明

本文档系列于 2026-01-12 进行了全面重构，采用了新的分层结构和语义化命名。如果您发现任何问题或缺失，请通过项目 Issue 系统反馈。

**重要变更**:

- 将原有的 `core/` 目录内容下沉到各子系统目录 (`jacquard/`, `mnemosyne/`, `presentation/`, `muse/`)
- 将原有的 `overview/` 目录核心概念文件上浮到根目录
- 删除了 `overview/` 目录，其内容已整合到根 `README.md` 或上浮到根目录
- 将 Filament 协议文档拆分为 5 个专题文件
- 合并了迁移相关的重复内容
- 新增了术语表、API 参考等实用文档
- 将 `structure/REORGANIZATION_SUMMARY.md` 归档至 `reference/legacy/`
- 2026-02-09: 删除冗余文件，修复错误链接，优化目录结构

---

*最后更新: 2026-01-12*  
*文档版本: 3.0.0*