# Clotho 项目 AI 助手指南

**项目类型**: 设计/文档仓库
**主要语言**: 简体中文 (zh-CN)

## 1. 项目概述

Clotho 是一个面向下一代 AI 角色扮演（RPG）的高性能、确定性客户端的设计文档仓库。本仓库包含系统架构、设计规范、协议定义和技术分析文档。我们致力于解决现有方案（如 SillyTavern）在逻辑处理、上下文管理和性能上的痛点。

## 2. 单一事实来源 (SSOT)

`00_active_specs/` 目录是项目的唯一权威文档源。在回答任何关于项目架构、功能、数据结构或工作流的问题前，**必须**先查阅该目录下的相关文档。

## 3. 目录结构

### 3.1 核心文档 (00_active_specs/)
- `README.md` - 架构文档索引（入口点）
- `vision-and-philosophy.md` - 愿景与哲学（凯撒原则）
- `architecture-principles.md` - 架构原则
- `metaphor-glossary.md` - 术语表与隐喻体系

### 3.2 子系统
- `infrastructure/` - 基础设施层
- `jacquard/` - 编排层（The Loom）
- `mnemosyne/` - 数据引擎
- `presentation/` - 表现层（The Stage）
- `muse/` - 智能服务

### 3.3 协议与格式
- `protocols/` - Filament 协议、输入/输出格式、宏系统

### 3.4 工作流
- `workflows/` - 提示词处理、角色卡迁移

### 3.5 参考文档
- `reference/documentation_standards.md` - 文档编写规范

### 3.6 工作目录
- `01_drafts/` - 设计草稿（工作进行中）
- `02_active_plans/` - 活跃计划（具体功能的规范）
- `03_actvie_craft/` - 详细规范（组件设计与分析）
- `10_references/` - 外部参考资料与分析
- `15_meta_crital/` - 元批判分析（设计审计与审查）
- `99_archive/` - 历史归档（已弃用的设计）

## 4. 文档标准

所有文档必须遵循 `00_active_specs/documentation_standards.md` 中的规范。

### 4.1 语言
- **默认语言**：简体中文 (zh-CN)
- **专有名词**：首次使用 "中文 (English)" 格式，之后保持一致

### 4.2 术语与隐喻
必须严格遵守 `00_active_specs/metaphor-glossary.md` 定义的纺织隐喻体系：

| 术语 (EN) | 术语 (CN) | 含义 |
| :--- | :--- | :--- |
| **Clotho** | **Clotho** | 整个系统 |
| **Jacquard** | **Jacquard** | 编排层/引擎 (The Loom) |
| **Mnemosyne** | **Mnemosyne** | 数据引擎 (The Memory) |
| **The Pattern** | **织谱** | 静态定义集 (原 Character Card) |
| **The Tapestry** | **织卷** | 运行时实例/存档 |
| **Threads** | **丝络** | 动态状态流/历史记录 |

### 4.3 语调
- **专业 (Professional)**：保持技术文档的严肃性
- **直接 (Direct)**：直入主题
- **禁止**：使用 "Great", "Sure", "Certainly" 等对话式填充词

### 4.4 格式
- 使用标准 Markdown 标题 (#, ##, ###)
- 文件头部必须包含 YAML/Frontmatter 元数据：
  ```markdown
  # 文档标题
  **版本**: x.x.x
  **日期**: YYYY-MM-DD
  **状态**: Draft/Active/Deprecated
  ```
- 代码块必须指定语言类型
- Mermaid 图表中避免在 `[]` 内使用双引号 `""` 或括号 `()`

## 5. AI 审查清单 (Review Checklist)

在提交任何文档更改前，必须执行以下自我审查：

- [ ] **SSOT 检查**: 内容是否与 `00_active_specs/` 中的规范冲突？
- [ ] **重复性检查**: 内容是否已在其他文件中存在？如果是，是否应该改为引用？
- [ ] **链接有效性**: 所有新增的 `[Link](path)` 相对路径是否真实存在且正确？
- [ ] **术语一致性**: 是否使用了 "Pattern", "Tapestry", "Jacquard" 等标准术语？
- [ ] **目录位置**: 文件是否放置在正确的子目录下？
- [ ] **语调检查**: 是否去除了 "Great", "Sure" 等对话式填充词？

## 6. 自动引用指令

1.  **始终先查阅规范**：回答架构、功能、数据结构或工作流问题时，必须先查阅 `00_active_specs/` 中的相关文件。
2.  **不要猜测**：如果 `00_active_specs/` 中已定义实现细节，不要凭空猜测。
3.  **上下文意识**：`00_active_specs/` 是活跃上下文，需要"记住"模块工作方式时，应阅读相应文件。
