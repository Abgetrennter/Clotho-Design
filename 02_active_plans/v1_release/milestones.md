# Clotho V1 里程碑计划 (Milestones)

**版本**: 0.1.0
**日期**: 2026-04-03
**状态**: Draft
**作者**: Codex

---

## 1. 里程碑目标

V1 的实现顺序必须服务于一个原则：

**始终优先推进“创建会话 → 连续对话 → 持久化恢复”主闭环。**

## 2. 里程碑总览

| 里程碑 | 名称 | 核心目标 |
|--------|------|----------|
| **M0** | 契约收口 | 清理文档冲突，冻结 V1 合同 |
| **M1** | 数据骨架 | 建立最小 SQLite / Repository / Session 骨架 |
| **M2** | 主对话闭环 | 建立输入、调用、解析、流式显示闭环 |
| **M3** | 状态写回 | 打通 `state_update` 校验、写回与恢复 |
| **M4** | 可用性硬化 | 错误处理、恢复、设置、验收与发布准备 |

## 3. M0: 契约收口

### 3.1 目标

在写代码前，先把 V1 冲突点收口。

### 3.2 任务

- 明确 V1 的 In-Scope / Out-of-Scope
- 冻结状态路径语法
- 冻结 Filament 核心标签
- 冻结 UI 访问边界
- 清理 SQLite 最小 DDL 的重复定义

### 3.3 出口条件

- [`frozen-contracts.md`](./frozen-contracts.md) 可作为实现依据
- V1 主链路不存在“同一能力三种说法”
- 关键团队成员对范围边界没有歧义

## 4. M1: 数据骨架

### 4.1 目标

建立最小持久化层与基础领域对象。

### 4.2 任务

- 建立 `sessions`
- 建立 `turns`
- 建立 `messages`
- 建立 `active_states`
- 建立 `state_oplogs`
- 建立最小 Repository 接口与实现
- 建立 Persona 加载机制

### 4.3 出口条件

- 可以创建 Session
- 可以打开已存在 Session
- 可以保存和读取线性 Turn 历史
- 可以为 Session 保存并恢复最小状态树

## 5. M2: 主对话闭环

### 5.1 目标

打通 V1 最关键的用户链路。

### 5.2 任务

- 输入区域可提交消息
- Jacquard 可加载 Context
- Jacquard 可构建最小 Prompt
- Muse Raw Gateway 可调用模型
- Filament Parser 可解析核心标签
- UI 可流式显示 `<content>`
- 成功生成后写入 Turn / Message

### 5.3 出口条件

- 用户可以连续对话至少 20 轮
- 重启前历史可见
- 失败不会破坏已提交历史

## 6. M3: 状态写回

### 6.1 目标

让系统不仅“能聊天”，还具备最小受控状态演进能力。

### 6.2 任务

- 为 `<state_update>` 建立 JSON Schema 级校验
- 仅允许合法路径写入
- 建立 State Updater
- 生成 OpLog
- 同步更新 `active_states`
- 重启后恢复状态

### 6.3 出口条件

- 合法 `state_update` 能写入并恢复
- 非法 `state_update` 被拒绝且不污染状态
- 状态写入与 Turn 写入保持一致事务边界

## 7. M4: 可用性硬化

### 7.1 目标

让 V1 从“可跑”提升到“可交付”。

### 7.2 任务

- 错误提示与重试机制
- 会话列表与基础设置
- 基础日志与调试信息
- 可选最小状态检视器
- 测试补齐
- 发布清单整理

### 7.3 出口条件

- 核心验收标准全部满足
- 关键错误场景可恢复或可解释
- 文档与实现口径一致

## 8. 依赖顺序

```mermaid
graph LR
    M0["M0 契约收口"] --> M1["M1 数据骨架"]
    M1 --> M2["M2 主对话闭环"]
    M2 --> M3["M3 状态写回"]
    M3 --> M4["M4 可用性硬化"]
```

## 9. 每个里程碑禁止引入的范围膨胀

### 9.1 M1 禁止

- 向量库
- Quest
- World Model
- Planner

### 9.2 M2 禁止

- Scheduler
- Hybrid SDUI
- Tool Call
- Muse Agent Host

### 9.3 M3 禁止

- Time Travel
- Branching
- Macro Narrative
- Consolidation Worker

### 9.4 M4 禁止

- 任何不影响首版交付的生态级扩展

## 10. 里程碑完成定义

某个里程碑只有在以下条件都满足时才算完成：

1. 对应功能主链路已打通
2. 对应测试已具备最小覆盖
3. 对应文档已更新
4. 不存在已知会损坏数据的一类问题

## 11. 关联文档

- [`./scope-in-out.md`](./scope-in-out.md)
- [`./frozen-contracts.md`](./frozen-contracts.md)
- [`./acceptance-criteria.md`](./acceptance-criteria.md)
- [`../../00_active_specs/reference/testing-strategy.md`](../../00_active_specs/reference/testing-strategy.md)
