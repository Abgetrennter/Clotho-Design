# 00_active_specs 设计文档完整性审计报告

> **审计日期**: 2026-04-02
> **审计范围**: `00_active_specs/` 全部 75 篇设计文档
> **审计目标**: 评估逻辑设计是否全面，识别需要完善的部分

---

## 一、总体评估

文档体系在**架构设计层面**已经相当成熟，核心数据流、子系统边界、协议格式都有明确定义。但在**可实施性细节**上存在系统性缺口。

各子系统完成度估算：

| 子系统 | 文档数 | 完成度 | 定性评价 |
|--------|--------|--------|----------|
| Stage / Presentation | ~25 篇 | ~90% | 组件规格详尽，状态管理清晰，异常态需补充 |
| Workflows | 5 篇 | ~95% | Prompt 处理管线端到端完整，迁移方案周全 |
| Infrastructure | 8 篇 | ~85% | DI / 日志 / 错误分类完善，监控策略缺失 |
| Muse | 5 篇 | ~80% | 接口与流式架构定义完整，Provider 实现缺口大 |
| Jacquard | 8 篇 | ~80% | 编排管线架构闭环，运行时细节不足 |
| Protocols | 8 篇 | ~80% | Filament 协议核心完整，校验规则和安全边界模糊 |
| Mnemosyne | 6 篇 | ~75% | 数据模型完整，运维与演进策略薄弱 |
| Runtime | 2 篇 | ~70% | 层级模型清晰，初始化与并发模型缺失 |
| 顶层文档 | 5 篇 | ~70% | 原则与术语到位，存在截断和状态矛盾 |

---

## 二、跨子系统横切缺口（最关键）

这些缺口影响多个子系统，不补全会导致实现时各模块无法对接。

### 2.1 端到端集成流程未串通

- **涉及**: 全局
- **现状**: `workflows/prompt-processing.md` 定义了 8 阶段管线，各子系统各自闭环，但缺少从用户点击到 UI 刷新的完整调用链验证。
- **缺口**: 需要一个完整的时序图：用户操作 → Stage 发出 Intent → Jacquard 编排 → Muse 调用 LLM → Filament 解析 → Mnemosyne 写入 → ClothoNexus 事件 → Riverpod 更新 UI。
- **影响**: 无法验证各子系统接口是否真正对齐，实现时可能出现契约断裂。

### 2.2 错误传播与恢复策略不完整

- **涉及**: Jacquard / Muse / Mnemosyne
- **现状**: `infrastructure/error-handling-and-cancellation.md` 定义了错误分类体系，`module-error-handling-strategies.md` 定义了各模块策略。
- **缺口**:
  - LLM 调用超时 / 断流时的降级策略（重试？缓存响应？用户提示？）
  - 部分写入的事务回滚规则（Filament 解析到一半出错时，已执行的状态变更如何处理）
  - Plugin 执行失败的隔离机制（Circuit Breaker 模式）
  - 跨子系统错误传播链（Muse 报错 → Jacquard 如何感知 → Stage 如何展示）
- **影响**: 实现时每个开发者会自行决定错误处理方式，导致行为不一致。

### 2.3 并发与竞态模型缺失

- **涉及**: Runtime / Mnemosyne / Jacquard
- **现状**: 所有文档均以单线程、单 Session 视角描述。
- **缺口**:
  - 多 Session 并发场景下的状态一致性保证
  - Deep Merge 操作的并发安全性（是否需要锁？粒度？）
  - SQLite 写锁策略（WAL 模式？连接池？）
  - ClothoNexus 事件的有序性保证（同一事件是否可能乱序到达？）
- **影响**: 多 Session 场景可能产生数据竞争、状态不一致。

### 2.4 Schema 演进与版本迁移策略空白

- **涉及**: Mnemosyne / Protocols
- **现状**: `mnemosyne/state_schema_v2_spec.md` 定义了 v2 原型链机制，`sqlite-architecture.md` 定义了表结构。
- **缺口**:
  - v1 → v2 的数据迁移路径（自动？手动？迁移脚本？）
  - 未来 schema 版本的管理策略（语义化版本号？兼容性矩阵？）
  - 数据库 migration 的具体执行方案（启动时检查？惰性迁移？）
  - 迁移失败时的回滚策略
- **影响**: 用户升级时可能面临数据丢失或不可用。

---

## 三、各子系统缺失清单

### 3.1 Jacquard（编排引擎）

| # | 缺失项 | 来源文档 | 详细说明 |
|---|--------|----------|----------|
| J-1 | Planner Tier 1 Prompt 模板与降级条件 | `planner-component.md` | 提到 Tier 0（确定性）+ Tier 1（轻量 LLM）分层，但 Tier 1 调用 LLM 的 prompt 模板、超时上限、降级回 Tier 0 的具体条件均未定义 |
| J-2 | Plugin 发现与加载机制 | `plugin-architecture.md` | 定义了接口和生命周期，但未说明插件如何被发现、注册、以及第三方插件的安全沙箱边界 |
| J-3 | Skein 大规模 Token 编织的性能特性 | `skein-and-weaving.md` | 编织算法已定义，但缺少超长上下文（>128k token）下的内存估算、语义去重的 O(n²) 复杂度处理策略 |
| J-4 | Capability 热重载行为 | `capability-system-spec.md` | 未定义运行时切换 Capability 时的状态迁移和插件重编排策略 |
| J-5 | Scheduler 事件总线实现细节 | `scheduler-component.md` | Counter 触发和事件触发的机制已定义，但事件总线的具体实现（内存？持久化？去重？）未明确 |

### 3.2 Mnemosyne（数据引擎）

| # | 缺失项 | 来源文档 | 详细说明 |
|---|--------|----------|----------|
| M-1 | 数据库备份 / 恢复与损坏处理 | `sqlite-architecture.md` | 有完整 DDL 但无备份策略。本地优先架构下 SQLite 损坏场景需要明确的恢复路径（自动修复？从 Snapshot 重建？） |
| M-2 | 原型链循环引用检测 | `state_schema_v2_spec.md` | `$_prototype` 机制未定义循环引用的防护，运行时可能导致无限递归 |
| M-3 | 资源去重与冲突解决 | `hybrid-resource-management.md` | content-addressable 存储已定义，但同一 URI 指向不同内容哈希时的解决策略未说明 |
| M-4 | World Model 一致性校验 | `world-model-layer.md` | 世界状态变更后缺少约束校验（如：角色不能同时出现在两个地点、经济系统总量守恒） |
| M-5 | 长 Session 内存管理 | `abstract-data-structures.md` | Turn-Centric 架构下，数百轮对话的 ActiveTurn 在内存中的管理策略（LRU 淘汰？惰性加载？）未定义 |
| M-6 | 数据验证机制 | `sqlite-architecture.md` | 写入前缺乏数据校验层，无法防止不合法状态进入持久层 |

### 3.3 Muse（AI 服务层）

| # | 缺失项 | 来源文档 | 详细说明 |
|---|--------|----------|----------|
| Mu-1 | Anthropic / Ollama / Gemini 适配器实现规格 | `muse-provider-adapters.md` | 统一接口已定义但仅完成了 OpenAI 实现，其余只有占位说明 |
| Mu-2 | Ollama 本地模型 Token 计数方案 | `streaming-and-billing-design.md` | 本地模型无标准 tokenizer，billing 依赖精确计数，但估算策略未定义（tiktoken 近似？字符比例？） |
| Mu-3 | A/B 测试与模型灰度路由 | `muse-router-config.md` | 5 种路由策略已定义但缺少实验性路由的分流、指标采集与回滚机制 |
| Mu-4 | Skill System 标准库 | `muse/README.md` | Skill 框架已定义但无标准库实现，开发者缺少参考 |

### 3.4 Stage / Presentation（展示层）

| # | 缺失项 | 来源文档 | 详细说明 |
|---|--------|----------|----------|
| S-1 | 组件 Loading / Error / Empty 状态规格 | 多个组件文档 | 各组件 spec 偏重正常态，异常态的视觉规格和交互行为不够统一（应建立统一的异常态模式） |
| S-2 | 平台手势差异处理 | `04-responsive-layout.md` | 响应式布局已定义，但触屏手势（滑动返回、长按菜单、右键上下文菜单）的平台适配未覆盖 |
| S-3 | Accessibility 实施细节 | `accessibility.md` | 无障碍规格存在但偏原则性，缺少具体的语义化标签标准和屏幕阅读器适配方案 |

### 3.5 Runtime（运行时）

| # | 缺失项 | 来源文档 | 详细说明 |
|---|--------|----------|----------|
| R-1 | 应用初始化启动序列 | `layered-runtime-architecture.md` | 层级模型已定义，但 App 启动时各层的初始化顺序、依赖检查、失败处理（某个服务初始化失败是阻塞还是降级？）未文档化 |
| R-2 | 多 Session 并发管理 | `layered-runtime-architecture.md` | 同时运行多个 Session 的资源隔离、状态切换、内存预算分配策略未定义 |
| R-3 | L2 → L3 Patch 生命周期管理 | `layered-runtime-architecture.md` | Patch 的创建、合并、丢弃的具体触发条件和清理规则不完整（何时 Patch 会自动合并回 L2？废弃 Patch 如何回收？） |

### 3.6 Protocols（协议层）

| # | 缺失项 | 来源文档 | 详细说明 |
|---|--------|----------|----------|
| P-1 | Filament 输入校验规则 | `filament-input-format.md` | XML+YAML 结构已定义但缺少：格式错误的诊断信息、最大嵌套深度限制、恶意输入的防护 |
| P-2 | Filament 输出校验与错误 JSON 处理 | `filament-output-format.md` | XML+JSON 输出已定义但缺少：畸形 JSON 的容错策略、OpCode 执行失败时的错误信封格式 |
| P-3 | 宏系统扩展机制 | `jinja2-macro-system.md` | 宏映射完整但缺少用户自定义宏的注册接口和安全边界 |
| P-4 | Schema 版本兼容性矩阵 | `schema-library.md` | Schema 存储和注入机制已定义，但版本间的兼容性关系、升级/降级行为未说明 |

---

## 四、文档体系自身的问题

| # | 问题 | 位置 | 说明 |
|---|------|------|------|
| D-1 | **vision-and-philosophy.md 末尾截断** | `vision-and-philosophy.md:94` | 文件在"性能分析器"相关内容处不完整，内容被截断 |
| D-2 | **architecture-principles.md 状态矛盾** | `architecture-principles.md` | 文档头部标记 Active 但正文第 194 行声明 "Draft, pending architecture review committee approval" |
| D-3 | **顶层 README 标题与内容不符** | `README.md` | 标题含"隐喻体系与术语表"但实际是索引导航页 |
| D-4 | **缺少全局架构可视化图** | 全局 | 无一张完整的架构图展示四子系统的交互关系和数据流向（文字描述分散在多处） |
| D-5 | **术语文档重复且缺少速查表** | `metaphor-glossary.md` + `naming-convention.md` | 两份文档有重复内容但未交叉引用，且缺少一个精简的单页术语速查表 |
| D-6 | **文档版本信息不一致** | 多处 | 部分文档有 version/date frontmatter，部分没有，缺乏统一的版本管理规范 |

---

## 五、建议优先级排序

### P0 — 阻塞实现（建议立即处理）

1. **补全端到端时序图** — 用户操作 → 各子系统协作 → 状态落盘 → UI 刷新的完整调用链
2. **定义错误传播与降级策略** — 尤其 LLM 调用链路的超时、重试、降级、用户反馈
3. **修复文档自身问题** D-1（截断）、D-2（状态矛盾）、D-3（标题不符）

### P1 — 影响核心功能（建议在实现对应模块前完成）

4. **Mnemosyne 备份恢复策略** — 本地优先架构下的数据安全保障
5. **Schema 演进与数据库 migration 方案** — 确保升级路径可行
6. **Planner Tier 1 Prompt 模板和降级条件** — 编排引擎的核心决策路径
7. **并发模型与竞态安全** — 多 Session 场景的数据一致性保证
8. **Runtime 启动序列文档** — 确保应用可靠启动

### P2 — 完善性补充（建议在 Beta 阶段前完成）

9. **各 Provider Adapter 实现规格** — Anthropic / Ollama / Gemini 的具体适配方案
10. **插件发现与沙箱机制** — 第三方扩展的安全边界
11. **Filament 协议校验规则** — 输入输出的格式校验和安全防护
12. **组件异常态规格统一化** — 建立 Loading / Error / Empty 的统一模式
13. **原型链循环引用检测** — 防止运行时无限递归

### P3 — 锦上添花（建议在正式发布前完成）

14. **全局架构可视化图** — 一张图纵览四子系统交互
15. **术语速查单页** — 开发者快速参考
16. **性能基准与压测场景** — 为性能优化提供量化目标
17. **文档版本管理规范** — 统一所有文档的 frontmatter 格式

---

## 六、与现有文档的交叉索引

本报告识别的缺口与现有文档的对应关系：

| 缺口编号 | 建议新增/补充的文档 | 关联现有文档 |
|----------|-------------------|-------------|
| 2.1 | `workflows/end-to-end-sequence-diagrams.md`（新增） | `workflows/prompt-processing.md` |
| 2.2 | `infrastructure/error-propagation-strategy.md`（补充） | `infrastructure/error-handling-and-cancellation.md` |
| 2.3 | `runtime/concurrency-model.md`（新增） | `runtime/layered-runtime-architecture.md` |
| 2.4 | `mnemosyne/schema-migration-guide.md`（新增） | `mnemosyne/state_schema_v2_spec.md`, `mnemosyne/sqlite-architecture.md` |
| J-1 | `jacquard/planner-component.md`（补充 Tier 1 节） | — |
| M-1 | `mnemosyne/sqlite-architecture.md`（补充备份恢复节） | — |
| R-1 | `runtime/startup-sequence.md`（新增） | `runtime/layered-runtime-architecture.md` |

---

*本报告基于 2026-04-02 的文档快照生成。随着文档更新，部分缺口可能已被解决。*
