# Clotho V1 冻结契约 (Frozen Contracts)

**版本**: 0.1.0
**日期**: 2026-04-03
**状态**: Draft
**作者**: Codex

---

## 1. 文档目的

本文档用于冻结 **V1 在进入实现前必须收口的契约**。

这些内容一旦不先冻结，后续实现会在以下位置反复返工：

- Parser 与 State Updater
- Jacquard 与 Mnemosyne 的边界
- UI 与状态树访问
- SQLite DDL 与持久化逻辑
- 测试夹具与协议样例

## 2. 契约冻结规则

冻结项的意义不是宣布“最终架构到此为止”，而是明确：

- **V1 只能按这一版执行**
- 后续若要修改，必须先更新本文件及对应 SSOT 文档

## 3. Frozen Contract A: 状态写入生命周期

### 3.1 决议

**V1 中，只有 `State Updater` 可以将 LLM 产出的状态变更写入 Session 状态。**

### 3.2 结果

- Planner 不参与 V1
- Pre-Generation 不允许修改持久化状态
- Parser 只负责解析，不负责写入
- UI 只能提交 Intent，不得直接写状态

### 3.3 影响

这条契约直接消除以下文档冲突在 V1 中的影响：

- Planner 是否可预先写 `planner_context`
- `activeQuestId` 是否在生成前生效

V1 的答案很简单：

**不启用 Planner，因此不存在预生成写状态。**

## 4. Frozen Contract B: 状态路径语法

### 4.1 决议

**V1 内部唯一合法的状态路径语法为 JSON Pointer。**

示例：

```text
/character/mood
/character/inventory/0/name
/session/turnCount
```

### 4.2 禁止项

以下语法不作为 V1 内部契约：

- 点路径 `character.description`
- SQLite 风格 `$.character.description`

### 4.3 允许的兼容方式

如果未来需要兼容导入器、人类配置或旧协议，可以在 **适配层** 做路径转换，但不得污染以下边界：

- `state_update`
- OpLog
- UI Data Projection Request
- 内部状态读写 API

## 5. Frozen Contract C: V1 Filament 核心标签

### 5.1 决议

V1 只将以下 3 个标签纳入正式契约：

- `<thought>`
- `<content>`
- `<state_update>`

### 5.2 输出约束

- `<thought>`: 仅用于语义思路承载，可选择不展示给最终用户
- `<content>`: 用户可见文本
- `<state_update>`: 必须为严格 JSON body

### 5.3 兼容策略

V1 测试夹具、系统提示、文档示例统一使用 canonical 标签。

旧标签如：

- `<think>`
- `<reply>`
- 其他 legacy 标签

最多只允许在解析兼容层存在，不允许成为 V1 正式输出示例或验收标准。

## 6. Frozen Contract D: UI 数据访问边界

### 6.1 决议

**UI 不得直接读取或修改 Mnemosyne 状态树。**

UI 只能通过 Jacquard 代理接口完成以下动作：

- 请求历史数据
- 请求状态投影
- 提交用户 Intent
- 订阅生成与状态更新事件

### 6.2 直接后果

V1 即使实现最小状态检视器，也必须走代理边界，而不是直连 SQLite 或内存状态对象。

## 7. Frozen Contract E: SQLite 最小 DDL

### 7.1 决议

V1 的最小物理持久化集合固定为：

- `sessions`
- `turns`
- `messages`
- `active_states`
- `state_oplogs`

### 7.2 明确约束

- `active_states` 只能存在 **一个** 正式定义
- 每个 Turn 的写入必须在 **单事务** 内完成
- 不要求 V1 实现 `state_snapshots`
- 不要求 V1 实现向量表

### 7.3 单事务范围

单次成功提交至少应覆盖：

1. 新 Turn
2. 用户消息
3. 助手消息
4. 通过校验的 `state_update`
5. `active_states` 回写

## 8. Frozen Contract F: 状态树范围

### 8.1 决议

V1 只保证以下根命名空间可用：

```text
/character
/session
```

### 8.2 延后命名空间

以下命名空间不进入 V1 正式契约：

```text
/world
/quests
/planner
```

## 9. Frozen Contract G: Muse 角色

### 9.1 决议

V1 中 Muse 仅承担 **Raw Gateway** 角色。

### 9.2 不包含

- Agent Host
- Skill System
- Tool Orchestration
- 多模型代理协作

## 10. Frozen Contract H: 被显式禁用的高级能力

V1 中，下列能力在架构上视为 **明确禁用**，而不是“未决定”：

- Planner
- Scheduler
- RAG Retriever
- Consolidation Worker
- Maintenance Pipeline
- Hybrid SDUI
- Branching / Time Travel

## 11. 冻结后待同步的 SSOT 文档

在进入实现前，建议至少同步修正以下文档中的冲突项：

- [`../../00_active_specs/jacquard/README.md`](../../00_active_specs/jacquard/README.md)
- [`../../00_active_specs/jacquard/planner-component.md`](../../00_active_specs/jacquard/planner-component.md)
- [`../../00_active_specs/workflows/prompt-processing.md`](../../00_active_specs/workflows/prompt-processing.md)
- [`../../00_active_specs/mnemosyne/sqlite-architecture.md`](../../00_active_specs/mnemosyne/sqlite-architecture.md)
- [`../../00_active_specs/protocols/filament-canonical-spec.md`](../../00_active_specs/protocols/filament-canonical-spec.md)

## 12. 变更流程

任何对冻结项的修改，必须遵循以下顺序：

1. 更新本文件
2. 更新对应的 `00_active_specs` 文档
3. 更新测试夹具与验收标准
4. 再进入实现修改
