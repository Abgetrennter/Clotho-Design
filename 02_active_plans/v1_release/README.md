# Clotho V1 发布切片 (V1 Release Slice)

**版本**: 0.1.0
**日期**: 2026-04-03
**状态**: Draft
**作者**: Codex

---

## 1. 文档定位

本目录用于定义 **Clotho 首版可用版本 (V1)** 的落地切片。

它的职责不是重新定义架构，而是基于 [`00_active_specs/`](../../00_active_specs/README.md) 的现有规范，回答以下问题：

1. V1 到底做什么
2. V1 明确不做什么
3. V1 采用哪一段架构切片
4. 哪些接口与行为必须先冻结
5. 应按什么顺序实现
6. 什么条件下可以判定“首版可用”

## 2. 与 SSOT 的关系

**单一事实来源仍然是 [`00_active_specs/`](../../00_active_specs/README.md)。**

本目录只承担三类职责：

- **裁剪 (Slice)**: 从完整架构中裁出 V1 实际启用的部分
- **冻结 (Freeze)**: 对 V1 必须收口的契约给出明确决策
- **排程 (Delivery)**: 给出实现顺序与验收口径

本目录**不重复定义**以下内容：

- Jacquard 的完整插件体系
- Mnemosyne 的完整长期记忆架构
- Presentation 的完整 Hybrid SDUI 体系
- Filament 的完整协议演进历史

若本目录与 `00_active_specs/` 存在冲突，处理规则如下：

1. 涉及系统长期架构原则时，以 `00_active_specs/` 为准
2. 涉及 V1 明确禁用项、缩减项、冻结项时，以本目录为准
3. 若两者冲突且无法解释，应先修正文档再进入实现

## 3. V1 北极星

V1 的目标不是“把 Clotho 全部实现完”，而是交付一个 **可持续使用、可持久化、可恢复、可扩展的本地优先角色扮演客户端基础版**。

V1 需要形成以下最小闭环：

- 用户可以创建并打开 Session
- 用户可以与 Persona 连续对话
- AI 回复可以流式显示
- 历史记录和基础状态可以持久化并在重启后恢复
- 状态更新必须经过校验与受控写入
- UI 不直接访问底层状态树

## 4. 文档结构

| 文件 | 作用 |
|------|------|
| [`scope-in-out.md`](./scope-in-out.md) | 定义 V1 的范围边界 |
| [`architecture-slice.md`](./architecture-slice.md) | 定义 V1 启用的架构切片 |
| [`frozen-contracts.md`](./frozen-contracts.md) | 冻结 V1 必须收口的关键契约 |
| [`milestones.md`](./milestones.md) | 定义实现顺序与里程碑出口条件 |
| [`acceptance-criteria.md`](./acceptance-criteria.md) | 定义“首版可用”的验收标准 |
| [`app-structure.md`](./app-structure.md) | 定义 `11_v1_app/` 的推荐实现目录结构 |
| [`migration-sequence.md`](./migration-sequence.md) | 定义从 `08_demo/` 与 `09_mvp/` 过渡到 V1 主干的迁移顺序 |

## 5. 推荐阅读顺序

1. [`scope-in-out.md`](./scope-in-out.md)
2. [`architecture-slice.md`](./architecture-slice.md)
3. [`frozen-contracts.md`](./frozen-contracts.md)
4. [`app-structure.md`](./app-structure.md)
5. [`migration-sequence.md`](./migration-sequence.md)
6. [`milestones.md`](./milestones.md)
7. [`acceptance-criteria.md`](./acceptance-criteria.md)

## 6. V1 原则

### 6.1 先闭环，再扩展

V1 优先保证“稳定的单一主链路”，而不是并行推进所有高级能力。

### 6.2 先冻结契约，再铺实现

以下问题如果不先冻结，后续实现会反复返工：

- 状态写入生命周期
- 状态路径语法
- Filament V1 核心标签
- UI 访问边界
- SQLite 最小 DDL

### 6.3 保留演进接口，但不提前实现

V1 允许在接口层为未来能力预留扩展点，但不将以下能力纳入当前交付：

- Planner / Scheduler / RAG / Consolidation
- Hybrid SDUI 双轨渲染
- Quest / World Model / Timeline
- Muse Agent Host / Skill System
- 分支存档 / 时间旅行

## 7. 关联文档

- [`../../00_active_specs/architecture-principles.md`](../../00_active_specs/architecture-principles.md)
- [`../../00_active_specs/runtime/layered-runtime-architecture.md`](../../00_active_specs/runtime/layered-runtime-architecture.md)
- [`../../00_active_specs/jacquard/README.md`](../../00_active_specs/jacquard/README.md)
- [`../../00_active_specs/mnemosyne/README.md`](../../00_active_specs/mnemosyne/README.md)
- [`../../00_active_specs/presentation/README.md`](../../00_active_specs/presentation/README.md)
- [`../../00_active_specs/protocols/filament-protocol-overview.md`](../../00_active_specs/protocols/filament-protocol-overview.md)
- [`../../00_active_specs/protocols/interface-definitions.md`](../../00_active_specs/protocols/interface-definitions.md)

---

**维护说明**:

- 当 V1 范围变化时，优先更新 [`scope-in-out.md`](./scope-in-out.md)
- 当 V1 契约收口时，优先更新 [`frozen-contracts.md`](./frozen-contracts.md)
- 当实现推进时，优先更新 [`milestones.md`](./milestones.md)
