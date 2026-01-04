# Clotho 文档架构优化方案

**版本**: 1.0.0
**日期**: 2025-12-30
**状态**: Proposal
**作者**: 资深系统架构师 (Roo)

---

## 1. 现状诊断 (Status Diagnosis)

经过对 `structure/` 目录下文档的深入分析，发现以下内容冗余与结构模糊问题：

### 1.1 内容重复 (Content Redundancy)

| 冲突模块 | 文件 A | 文件 B | 冲突描述 | 证据 |
| :--- | :--- | :--- | :--- | :--- |
| **设计哲学** | `core/vision-and-philosophy.md` | `overview/vision-and-philosophy.md` | 两份文件在“核心价值主张”、“凯撒原则”、“核心功能抽象”等章节内容几乎完全一致。 | A 文件与 B 文件的 1-3 节结构与文字高度重合，仅仅是标题层级略有不同。 |
| **Patching 机制** | `core/layered-runtime-architecture.md` | `core/mnemosyne-data-engine.md` | 两份文件都详细描述了 Patching 的工作原理、应用场景和 Deep Merge 逻辑。 | A 文件的第 3 节与 B 文件的第 6 节重复阐述了 Patching 原理，导致维护时需双重更新。 |
| **运行时架构** | `runtime/README.md` | `core/layered-runtime-architecture.md` | `runtime/` 目录目前为空壳，仅通过 README 指向 `core/` 下的文件，造成导航路径的断裂。 | `runtime/README.md` 仅包含索引，实际内容全在 `core/` 中。 |

### 1.2 结构评估 (Structure Assessment)

*   **目录层级不清**: `core/` 目录目前承载了过多的职责，既包含了具体的组件设计（Jacquard, Mnemosyne），又包含了高层的愿景（Vision）和动态的运行时架构（Runtime）。这违反了“关注点分离”原则。
*   **Overview 边界模糊**: `overview/` 应当作为项目的门户，包含对所有技术人员（不仅是核心开发者）的通用介绍。目前的 `core/vision-and-philosophy.md` 使得 `overview` 的地位被弱化。
*   **Runtime 模块独立性缺失**: 运行时环境（Session, State, Patching）是 Clotho 最独特的特性之一，理应拥有独立的顶级目录来存放其详细设计，而不是寄居在 `core/` 下或仅作为一个索引目录。

---

## 2. 结构评估与原则 (Principles)

为了实现 **“高内聚、低耦合”** 的文档架构，我们遵循以下重构原则：

1.  **单一数据源 (SSOT)**: 任何核心概念（如 Patching 机制）的定义性描述只出现一次，其他地方通过引用链接。
2.  **动静分离**: 
    *   `core/`: 存放系统的**静态组件**设计（三大生态、基础设施）。
    *   `runtime/`: 存放系统的**动态行为**描述（分层模型、状态流转、生命周期）。
3.  **金字塔结构**: 从 `overview` (宏观) -> `core` (组件) -> `runtime` (机制) -> `protocols/workflows` (细节)。

---

## 3. 重构方案 (Refactoring Plan)

### 3.1 建议的文件变更列表

| 操作 | 文件路径 | 说明 |
| :--- | :--- | :--- |
| **删除** | `structure/core/vision-and-philosophy.md` | 内容已包含在 `structure/overview/` 中，保留 `overview` 版本作为全局入口。 |
| **移动** | `structure/core/layered-runtime-architecture.md` -> `structure/runtime/layered-runtime-architecture.md` | 将运行时架构文档归位到 `runtime/` 目录，使该目录名副其实。 |
| **修改** | `structure/core/mnemosyne-data-engine.md` | **精简 Patching 章节**。移除原理性描述，仅保留与数据存储结构（VWD, Schema）相关的实现细节，并链接到 `runtime/` 文档。 |
| **修改** | `structure/runtime/layered-runtime-architecture.md` | **增强流程描述**。作为 Patching 机制的主定义文档，详细描述分层逻辑。 |
| **更新** | `structure/README.md` & `structure/overview/architecture-panorama.md` | 更新所有断裂的链接以反映上述文件移动。 |
| **归档** | `structure/REORGANIZATION_SUMMARY.md` | 该文件是上次重构的日志，建议移动到 `structure/reference/legacy/` 或直接归档，保持根目录整洁。 |

### 3.2 推荐目录结构树

```text
structure/
├── overview/                      # [宏观层] 项目门户
│   ├── architecture-panorama.md   # 架构全景图与导航
│   ├── architecture-principles.md # 核心架构原则
│   └── vision-and-philosophy.md   # 愿景与设计哲学 (SSOT)
├── core/                          # [组件层] 静态架构组件
│   ├── infrastructure-layer.md    # 基础设施
│   ├── jacquard-orchestration.md  # 编排层 (Jacquard)
│   ├── mnemosyne-data-engine.md   # 数据引擎 (Mnemosyne) - 侧重存储与Schema
│   └── presentation-layer.md      # 表现层
├── runtime/                       # [动态层] 运行时与状态
│   ├── layered-runtime-architecture.md # 分层运行时与 Patching (SSOT)
│   └── README.md                  # 运行时导读
├── workflows/                     # [流程层] 业务流
│   ├── prompt-processing.md
│   ├── character-import-migration.md
│   └── migration-strategy.md
├── protocols/                     # [协议层] 接口与格式
│   ├── filament-*.md
│   └── jinja2-macro-system.md
├── reference/                     # [参考层] 字典与规范
│   └── README.md
├── quick-introduction.md          # 快速入门
└── README.md                      # 文档总索引
```

---

## 4. 维护建议 (Maintenance Guidelines)

1.  **交叉引用检查**: 每次移动或重命名文件时，必须使用搜索工具（如 VS Code 全局搜索）查找并更新所有引用该文件的链接。
2.  **模板化头部**: 保持所有 Markdown 文件的 YAML Front Matter (或顶部表格) 统一，包含 `版本`、`维护者`、`关联文档` 字段，便于追踪依赖关系。
3.  **定期审查**: 每季度审查一次 `mnemosyne` 和 `runtime` 目录，确保数据结构的更新没有导致文档与代码实现脱节。
