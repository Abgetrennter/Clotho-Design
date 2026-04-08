# 00_active_specs/ 目录整理计划

**版本**: 1.0.0
**日期**: 2026-02-09
**状态**: Draft
**作者**: 系统架构师 (Architect Mode)

---

## 一、问题概述

经过对 `00_active_specs/` 目录的全面分析，发现以下主要问题：

### 1.1 根目录文件冗余

| 文件 | 问题 | 建议 |
|------|------|------|
| `quick-introduction.md` | 与 `README.md` 内容大量重叠 | 删除，保留 README.md 作为唯一入口 |
| `mvp-demo-design-spec.md` | 属于计划文档，不属于活跃规范 | 移动到 `02_active_plans/` 目录 |
| `documentation_standards.md` | 属于参考文档 | 移动到 `reference/` 目录 |

### 1.2 链接错误

以下文档包含指向不存在的 `../core/` 路径的链接：

| 文档 | 错误链接 | 正确链接 |
|------|----------|----------|
| `protocols/filament-protocol-overview.md` | `../core/` | `../jacquard/`, `../mnemosyne/` 等 |
| `workflows/prompt-processing.md` | `../core/jacquard-orchestration.md` | `../jacquard/README.md` |
| `workflows/prompt-processing.md` | `../core/mnemosyne-data-engine.md` | `../mnemosyne/README.md` |
| `protocols/README.md` | `../core/jacquard-orchestration.md` | `../jacquard/README.md` |
| `protocols/README.md` | `../core/mnemosyne-data-engine.md` | `../mnemosyne/README.md` |
| `workflows/README.md` | `../core/` | `../jacquard/`, `../mnemosyne/` 等 |
| `runtime/README.md` | `../core/mnemosyne-data-engine.md` | `../mnemosyne/README.md` |
| `runtime/README.md` | `../core/jacquard-orchestration.md` | `../jacquard/README.md` |

### 1.3 infrastructure/README.md 内容过时

- 该文档引用了不存在的 `../core/` 路径
- 内容与当前目录结构不符
- 需要完全重写或删除（因为 infrastructure 目录下只有 README.md）

### 1.4 内容重复

- `vision-and-philosophy.md` 和 `architecture-principles.md` 中关于凯撒原则、绝对约束的内容有重复
- `quick-introduction.md` 与 `README.md` 的内容大量重复

---

## 二、整理方案

### 2.1 文件操作清单

#### 删除操作

| 操作 | 文件 | 原因 |
|------|------|------|
| 删除 | `00_active_specs/quick-introduction.md` | 与 README.md 内容重复 |
| 删除 | `00_active_specs/infrastructure/README.md` | infrastructure 目录为空，内容过时 |
| 删除 | `00_active_specs/infrastructure/` | 目录为空，无实际内容 |

#### 移动操作

| 操作 | 源路径 | 目标路径 | 原因 |
|------|--------|----------|------|
| 移动 | `00_active_specs/mvp-demo-design-spec.md` | `02_active_plans/mvp-demo-design-spec.md` | 属于计划文档 |
| 移动 | `00_active_specs/documentation_standards.md` | `00_active_specs/reference/documentation_standards.md` | 属于参考文档 |

### 2.2 链接修复清单

#### protocols/filament-protocol-overview.md

```markdown
# 修改前
- 核心架构 [`../core/`](../core/)

# 修改后
- Jacquard 编排层 [`../jacquard/README.md`](../jacquard/README.md)
- Mnemosyne 数据引擎 [`../mnemosyne/README.md`](../mnemosyne/README.md)
```

#### workflows/prompt-processing.md

```markdown
# 修改前
- 核心架构 [`../core/jacquard-orchestration.md`](../core/jacquard-orchestration.md)
- 核心架构 [`../core/mnemosyne-data-engine.md`](../core/mnemosyne-data-engine.md)

# 修改后
- Jacquard 编排层 [`../jacquard/README.md`](../jacquard/README.md)
- Mnemosyne 数据引擎 [`../mnemosyne/README.md`](../mnemosyne/README.md)
```

#### protocols/README.md

```markdown
# 修改前
- Jacquard 编排层 [`../core/jacquard-orchestration.md`](../core/jacquard-orchestration.md)
- Mnemosyne 数据引擎 [`../core/mnemosyne-data-engine.md`](../core/mnemosyne-data-engine.md)

# 修改后
- Jacquard 编排层 [`../jacquard/README.md`](../jacquard/README.md)
- Mnemosyne 数据引擎 [`../mnemosyne/README.md`](../mnemosyne/README.md)
```

#### workflows/README.md

```markdown
# 修改前
- 核心架构 ([`../core/`](../core/))

# 修改后
- Jacquard 编排层 ([`../jacquard/`](../jacquard/))
- Mnemosyne 数据引擎 ([`../mnemosyne/`](../mnemosyne/))
```

#### runtime/README.md

```markdown
# 修改前
- 数据引擎: [Mnemosyne Data Engine](../core/mnemosyne-data-engine.md)
- 编排层: [Jacquard Orchestration](../core/jacquard-orchestration.md)

# 修改后
- 数据引擎: [Mnemosyne 数据引擎](../mnemosyne/README.md)
- 编排层: [Jacquard 编排层](../jacquard/README.md)
```

### 2.3 README.md 更新

需要更新 `00_active_specs/README.md` 中的以下内容：

1. 移除对 `quick-introduction.md` 的引用
2. 移除对 `infrastructure/` 目录的引用
3. 更新 `documentation_standards.md` 的路径引用

```markdown
# 修改前
- [`quick-introduction.md`](quick-introduction.md) - AI 快速了解（根目录）
...
- **基础设施层**:
  - [`infrastructure/README.md`](infrastructure/README.md) - 基础设施层总览
...
- [`documentation_standards.md`](documentation_standards.md) - 文档编写与检查规范

# 修改后
# （移除 quick-introduction.md 引用）
...
# （移除 infrastructure 层引用）
...
- [`reference/documentation_standards.md`](reference/documentation_standards.md) - 文档编写与检查规范
```

---

## 三、整理后的目录结构

```
00_active_specs/
├── README.md                          # 主索引文档
├── vision-and-philosophy.md           # 愿景与哲学
├── architecture-principles.md         # 架构原则
├── metaphor-glossary.md               # 术语表
├── jacquard/                          # 编排层
│   ├── README.md
│   ├── planner-component.md
│   └── scheduler-component.md
├── mnemosyne/                         # 数据引擎
│   ├── README.md
│   ├── sqlite-architecture.md
│   ├── abstract-data-structures.md
│   └── hybrid-resource-management.md
├── muse/                              # 智能服务
│   └── README.md
├── presentation/                      # 表现层
│   └── README.md
├── protocols/                         # 协议与格式
│   ├── README.md
│   ├── filament-protocol-overview.md
│   ├── filament-input-format.md
│   ├── filament-output-format.md
│   ├── filament-parsing-workflow.md
│   ├── jinja2-macro-system.md
│   └── schema-library.md
├── workflows/                         # 工作流
│   ├── README.md
│   ├── prompt-processing.md
│   ├── character-import-migration.md
│   └── migration-strategy.md
├── runtime/                           # 运行时
│   ├── README.md
│   └── layered-runtime-architecture.md
└── reference/                         # 参考文档
    ├── README.md
    ├── documentation_standards.md     # 从根目录移动过来
    ├── macro-system-spec.md
    ├── st-macro-reference.md
    ├── acu-architecture-analysis.md
    └── legacy/
        └── REORGANIZATION_SUMMARY.md
```

---

## 四、执行步骤

### 阶段 1：文件移动与删除

1. 移动 `mvp-demo-design-spec.md` 到 `02_active_plans/`
2. 移动 `documentation_standards.md` 到 `reference/`
3. 删除 `quick-introduction.md`
4. 删除 `infrastructure/README.md`
5. 删除 `infrastructure/` 目录

### 阶段 2：链接修复

1. 修复 `protocols/filament-protocol-overview.md` 中的链接
2. 修复 `workflows/prompt-processing.md` 中的链接
3. 修复 `protocols/README.md` 中的链接
4. 修复 `workflows/README.md` 中的链接
5. 修复 `runtime/README.md` 中的链接

### 阶段 3：README.md 更新

1. 更新 `00_active_specs/README.md`，移除对已删除/移动文件的引用
2. 更新 `reference/README.md`，添加对 `documentation_standards.md` 的引用

### 阶段 4：验证

1. 检查所有链接是否有效
2. 确认目录结构清晰合理
3. 验证文档索引完整性

---

## 五、风险评估

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 删除 `quick-introduction.md` 可能影响现有引用 | 低 | 搜索整个项目，确认无外部引用 |
| 移动文件可能破坏现有链接 | 中 | 使用全局搜索替换更新所有引用 |
| 链接修复遗漏 | 低 | 使用自动化工具验证所有链接 |

---

## 六、后续建议

1. **建立文档审查机制**：定期检查文档冗余和链接有效性
2. **使用自动化工具**：引入 Markdown 链接检查工具
3. **文档版本控制**：对重大文档变更进行版本记录
4. **SSOT 原则强化**：确保核心概念只在单一位置定义

---

**最后更新**: 2026-02-09
**文档状态**: 草案，待审核
