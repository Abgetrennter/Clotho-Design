# Clotho V1 范围边界 (Scope In / Out)

**版本**: 0.1.0
**日期**: 2026-04-03
**状态**: Draft
**作者**: Codex

---

## 1. 目标定义

V1 的目标是交付一个 **单用户、本地优先、可持久化的角色对话基础产品**，验证以下核心价值：

- 分层架构可以闭环运行
- Jacquard 可以稳定驱动主对话通道
- Mnemosyne 可以作为唯一状态权威源
- Filament 可以承担 LLM 边界协议
- UI 可以在不直连状态树的前提下完成交互

## 2. 目标用户

V1 面向两类用户：

1. **核心内部用户**
   - 用于验证架构是否可落地
   - 用于验证首版信息架构与交互主链路
2. **早期体验用户**
   - 能够创建 Persona 会话
   - 能够进行连续对话
   - 能够重启后恢复历史和基础状态

## 3. 平台策略

### 3.1 主平台

- **Windows Desktop**: V1 主交付平台

### 3.2 次平台

- **Web / Android**: 仅做兼容性验证，不作为 V1 发布门槛

## 4. In-Scope

### 4.1 P0 必须包含

| 模块 | 内容 | 说明 |
|------|------|------|
| **Session 管理** | 创建、打开、删除、列出 Session | 最小存档闭环 |
| **Persona 加载** | 从本地资源加载 Persona | 不做复杂导入链路 |
| **主对话通道** | 输入消息、调用 LLM、流式显示回复 | 主价值链 |
| **历史持久化** | 持久化 Turn / Message 并可恢复 | 重启后可继续 |
| **基础状态管理** | 支持受控 `state_update` 写入与恢复 | 仅限最小状态树 |
| **Filament 核心协议** | `<thought>`、`<content>`、`<state_update>` | 不引入扩展标签族 |
| **受控 UI 访问** | UI 通过 Jacquard 代理访问数据 | 不允许直连 Mnemosyne |
| **错误反馈** | 网络失败、解析失败、写入失败可见 | 不能静默损坏数据 |

### 4.2 P1 可作为 V1 末尾增强

| 模块 | 内容 | 说明 |
|------|------|------|
| **最小状态检视器** | 只读 Raw/Tree 视图 | 仅用于调试和用户理解 |
| **基础设置页** | Provider 配置、本地模型配置 | 不做复杂多路由管理 |
| **最小 Persona 管理** | 多 Persona 选择与切换 | 不含生态级导入器 |

## 5. Out-of-Scope

以下能力明确不纳入 V1：

| 类别 | 内容 | 原因 |
|------|------|------|
| **Pre-Generation 智能编排** | Planner、Focus 切换、Goal Planning | 先保证主链路稳定 |
| **自动化与调度** | Scheduler、周期任务、楼层触发 | 复杂度高，非首版核心 |
| **长期记忆增强** | RAG、Turn Summary 检索、Macro Narrative | 先做可靠存储，再做检索 |
| **异步记忆整理** | Consolidation Worker、Maintenance Pipeline | 延后到 V1 之后 |
| **复杂世界状态** | World Model、Timeline、Faction、Economy | 首版不做模拟型世界引擎 |
| **任务系统** | Quest、Objective、Spotlight | 依赖 Planner 契约收口 |
| **高级渲染生态** | Hybrid SDUI、RFW、WebView Fallback | 首版不引入双轨渲染复杂度 |
| **扩展协议体系** | Tool Call、Choice、UI Component 等扩展 Schema | 先冻结核心协议 |
| **分支与回溯** | Time Travel、Branching、历史分叉 | 需要完整 Snapshot 策略 |
| **Muse Agent Host** | Agent、Skill、ReAct、导入向导智能助手 | 首版只保留 Raw Gateway |
| **多用户 / ACL** | Shared / Private / Conditional 作用域 | 首版只做单用户单本地实例 |
| **云同步** | WebDAV、文件同步、增量同步协议 | 延后到稳定存储后 |

## 6. V1 最小产品画像

V1 的产品形态建议收敛为：

- 左侧：Session 列表
- 中间：聊天主界面
- 底部：输入区域与生成状态
- 可选右侧：基础状态检视器

不要求在 V1 中实现：

- 三栏复杂自适应策略的全部细节
- 混合消息状态槽生态
- 任何外部 UI 扩展包

## 7. V1 最小状态范围

V1 建议只支持以下状态命名空间：

```text
/character/*
/session/*
```

以下命名空间延后：

```text
/world/*
/quests/*
/planner/*
```

## 8. V1 非功能边界

### 8.1 必须满足

- 本地优先，不依赖云端数据库
- 崩溃或中断后，已提交的 Turn 不损坏
- 非法 `state_update` 不得污染状态树
- UI 不得绕过 Jacquard 直接读写状态

### 8.2 暂不追求

- 全平台一致体验
- 大规模历史下的最终性能上限
- 插件市场与扩展生态兼容
- 所有高级协议扩展的向后兼容

## 9. 范围控制原则

当某项能力同时满足以下条件时，默认 **延后**：

1. 需要新增一条独立异步流水线
2. 需要引入新的协议标签家族
3. 需要引入新的存储链或向量库
4. 不影响“创建会话 → 连续对话 → 重启恢复”主闭环

## 10. 关联文档

- [`./architecture-slice.md`](./architecture-slice.md)
- [`./frozen-contracts.md`](./frozen-contracts.md)
- [`../../00_active_specs/jacquard/README.md`](../../00_active_specs/jacquard/README.md)
- [`../../00_active_specs/mnemosyne/README.md`](../../00_active_specs/mnemosyne/README.md)
- [`../../00_active_specs/presentation/README.md`](../../00_active_specs/presentation/README.md)
