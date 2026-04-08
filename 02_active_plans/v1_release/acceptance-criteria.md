# Clotho V1 验收标准 (Acceptance Criteria)

**版本**: 0.1.0
**日期**: 2026-04-03
**状态**: Draft
**作者**: Codex

---

## 1. 文档目的

本文档定义 V1 进入“可用”状态所必须满足的验收标准。

它关注的是：

- 用户是否能完成核心任务
- 数据是否可靠
- 状态是否受控
- 协议与边界是否守住

## 2. 发布判定原则

只有当以下四类标准全部满足时，V1 才可判定为“首版可用”：

1. **功能闭环成立**
2. **数据一致性成立**
3. **错误场景可处理**
4. **文档与测试口径一致**

## 3. 功能验收

### 3.1 Session 管理

- 用户可以创建新 Session
- 用户可以查看 Session 列表
- 用户可以重新打开旧 Session
- 用户可以删除 Session

### 3.2 Persona 加载

- 用户可以为 Session 选择 Persona
- Persona 的基础系统设定能进入 Prompt
- 切换 Session 时，Persona 绑定关系正确恢复

### 3.3 主对话流程

- 用户可以输入消息并提交
- 助手回复可以流式显示
- 完成后消息会持久化
- 连续多轮对话不会覆盖已有历史

## 4. 状态验收

### 4.1 基础状态读写

- 系统能为 Session 维护最小状态树
- 合法 `state_update` 能成功写入
- 非法 `state_update` 会被拒绝
- 拒绝非法写入时，历史与状态不损坏

### 4.2 重启恢复

- 应用重启后，Session 历史可恢复
- 应用重启后，`active_states` 可恢复
- 恢复后的状态与最后一次成功提交一致

## 5. 协议验收

### 5.1 Filament 输入 / 输出

- V1 正式链路使用 canonical 标签
- `<content>` 必须可正确渲染
- `<thought>` 必须可正确解析
- `<state_update>` 必须是合法 JSON

### 5.2 解析容错

- LLM 输出缺少 `<thought>` 时，系统仍可继续
- `<content>` 缺失时，应返回明确错误或进入降级策略
- `<state_update>` 解析失败时，不得影响消息持久化

## 6. 数据一致性验收

### 6.1 单事务提交

以下内容必须作为同一成功提交单元处理：

- Turn
- 用户消息
- 助手消息
- 合法状态变更
- `active_states` 回写

### 6.2 中断与失败

- 网络错误不应写入半个 Turn
- 解析错误不应污染状态树
- 写库失败不应导致“有消息没状态”或“有状态没历史”的断裂结果

## 7. UI 边界验收

- UI 不直接读取 Mnemosyne
- UI 不直接写入 Mnemosyne
- 所有状态读取均通过 Jacquard 代理
- 所有状态写入均通过 Intent → Jacquard → State Updater 流程

## 8. 错误处理验收

以下错误类别必须对用户或开发者可见：

- Provider 不可用
- 超时
- Filament 解析失败
- `state_update` 非法
- SQLite 写入失败

最低要求：

- 用户看到明确失败反馈
- 开发者可在日志中定位错误阶段
- 系统不会因为单次失败进入不可恢复状态

## 9. 测试验收

### 9.1 必须具备的测试类型

- 单元测试：Parser、State Updater、Repository、路径校验
- 集成测试：Jacquard ↔ Mnemosyne、Jacquard ↔ Muse、Presentation ↔ Jacquard
- 基础 UI 测试：发送消息、展示流式结果、恢复历史

### 9.2 最低测试门槛

- V1 主链路有自动化测试覆盖
- 至少有一条完整 E2E 路径被稳定执行
- 所有冻结契约至少各有一个对应测试

## 10. Gating Scenarios

### 10.1 场景 A: 创建并连续对话

1. 创建 Session
2. 发送首条消息
3. 收到流式回复
4. 再发送至少 3 条消息
5. 历史顺序正确

### 10.2 场景 B: 状态写入与恢复

1. 发送一条会触发 `state_update` 的消息
2. 状态树成功更新
3. 关闭应用
4. 重启并重新打开 Session
5. 状态仍与关闭前一致

### 10.3 场景 C: 非法输出隔离

1. 模拟 LLM 返回非法 `state_update`
2. 系统拒绝写入
3. 消息仍保留或明确失败回滚
4. 原状态不被污染

## 11. 非目标说明

以下能力不作为 V1 验收前提：

- Planner 聚焦切换
- Quest 完整生命周期
- RAG 检索命中效果
- Hybrid SDUI 动态组件
- Branching / Time Travel
- Muse Agent / Skill 调用

## 12. 发布建议门槛

当以下条件同时满足时，建议进入 V1 发布候选：

- 所有 P0 功能完成
- 所有冻结契约已有实现与测试
- 不存在 P0 级数据损坏问题
- 文档中不存在关键冲突未清理项

## 13. 关联文档

- [`./scope-in-out.md`](./scope-in-out.md)
- [`./architecture-slice.md`](./architecture-slice.md)
- [`./frozen-contracts.md`](./frozen-contracts.md)
- [`./milestones.md`](./milestones.md)
- [`../../00_active_specs/reference/testing-strategy.md`](../../00_active_specs/reference/testing-strategy.md)
