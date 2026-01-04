# 文件整理与重构计划

## 1. 目标
解决目前文档分散、新旧混杂的问题。建立清晰的 **"生效中 (Active)"** vs **"已归档 (Archived)"** vs **"参考 (Reference)"** 的层级结构。

## 2. 拟定目录结构
我们将统一使用 `docs/` 作为文档根目录（目前根目录下有 `doc/`, `structure/`, `plans/`, `参考文件/` 等多个入口，过于混乱）。

```text
docs/
├── 00_active_specs/         <-- (原 structure/) 目前的项目真理，生效的设计文档
│   ├── core/
│   ├── overview/
│   ├── protocols/
│   ├── runtime/
│   └── workflows/
│
├── 01_drafts/               <-- (原 doc/EvaluationDoc/) 正在进行的评估、草稿、杂项
│
├── 10_references/           <-- (原 参考文件/) 外部参考、竞品分析
│   ├── database/
│   ├── character_card_v3/
│   └── ...
│
├── 99_archive/              <-- 所有历史遗留、已执行计划、旧版本设计
│   ├── legacy_architecture/ <-- (原 doc/architecture/) 重构前的设计
│   ├── legacy_plans/        <-- (原 plans/) 已经执行过的设计方案
│   ├── legacy_ui/           <-- (原 doc/ui-design-specs/) 旧版UI设计
│   └── legacy_misc/         <-- (原 doc/legacy_archive/) 更早期的归档
│
└── assets/                  <-- (原 draw/) 图片、图表源文件
```

## 3. 详细迁移映射表

| 原路径 | 目标路径 | 说明 |
| :--- | :--- | :--- |
| **structure/** | **docs/00_active_specs/** | **核心操作**。这是目前的“生效”文档。 |
| **doc/EvaluationDoc/** | **docs/01_drafts/** | 杂项容器，建议后续进一步分类，暂时先统一移动。 |
| **参考文件/** | **docs/10_references/** | 统一使用英文路径名，避免中文路径带来的潜在工具兼容性问题。 |
| **doc/architecture/** | **docs/99_archive/legacy_architecture/** | 明确标记为 legacy，避免混淆。 |
| **plans/** | **docs/99_archive/legacy_plans/** | 这些计划已执行或过时，归档。 |
| **doc/ui-design-specs/** | **docs/99_archive/legacy_ui/** | 旧版 UI 设计。 |
| **doc/legacy_archive/** | **docs/99_archive/legacy_misc/** | 原有的归档再次归档。 |
| **draw/** | **docs/assets/draw/** | 将绘图文件归拢到文档资源目录下。 |

## 4. 执行步骤

1.  **创建目录骨架**
    - 创建 `docs/00_active_specs`
    - 创建 `docs/01_drafts`
    - 创建 `docs/10_references`
    - 创建 `docs/99_archive` 及其子目录
    - 创建 `docs/assets`

2.  **移动文件**
    - 将 `structure/*` 移动到 `docs/00_active_specs/`
    - 将 `doc/EvaluationDoc/*` 移动到 `docs/01_drafts/`
    - 将 `参考文件/*` 移动到 `docs/10_references/`
    - 将 `doc/architecture/*` 移动到 `docs/99_archive/legacy_architecture/`
    - 将 `plans/*` 移动到 `docs/99_archive/legacy_plans/` (注意：本计划文件自身保留或移动后更新路径)
    - 将 `doc/ui-design-specs/*` 移动到 `docs/99_archive/legacy_ui/`
    - 将 `draw/*` 移动到 `docs/assets/draw/`

3.  **后续清理**
    - 删除空的 `doc/` 目录
    - 删除空的 `structure/` 目录
    - 删除空的 `plans/` 目录
    - 删除空的 `参考文件/` 目录
    - 删除空的 `draw/` 目录

## 5. 待确认事项
- [ ] 是否同意将中文路径 `参考文件` 重命名为 `docs/10_references`？
- [ ] `plans/` 目录下是否有正在执行中、不应归档的计划？(如有，请指明，我们将它们移入 `docs/01_drafts` 或 `docs/plans` active 目录)
