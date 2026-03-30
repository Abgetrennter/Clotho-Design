# Clotho 项目上下文文档 (QWEN.md)

**最后更新**: 2026-03-11
**文档版本**: 1.0.0

---

## 1. 项目概览 (Project Overview)

### 1.1 项目定位

**Clotho** 是一个面向下一代 AI 角色扮演（RPG）的高性能、确定性客户端，旨在解决现有方案（如 SillyTavern）在逻辑处理、上下文管理和性能上的根本性痛点。

- **技术栈**: Flutter (Dart) + SQLite
- **目标平台**: Windows、Android 等多端跨平台
- **核心价值**: 通过严格的架构分层，实现"逻辑升级不破坏界面，界面重构不影响逻辑"的稳健系统

### 1.2 设计哲学：凯撒原则 (The Caesar Principle)

> **"凯撒的归凯撒，上帝的归上帝"**

| 领域 | 职责 | 实现者 |
|------|------|--------|
| **凯撒的归凯撒** | 逻辑判断、数值计算、状态管理、流程控制 | 确定性代码 (Jacquard/Mnemosyne) |
| **上帝的归上帝** | 语义理解、情感演绎、剧情生成、文本润色 | LLM (大语言模型) |

**核心规则**: 绝不将业务逻辑/数学计算/状态管理放入 LLM Prompt。

---

## 2. 系统架构 (System Architecture)

### 2.1 三层物理隔离架构

```
┌─────────────────────────────────────────────────────────────┐
│                    表现层 (Presentation)                     │
│                    The Stage (舞台)                          │
│  Flutter UI, Hybrid SDUI, 只读渲染，Intent 触发              │
├─────────────────────────────────────────────────────────────┤
│                    编排层 (Jacquard)                         │
│                    The Loom (织机)                           │
│  插件化流水线，Prompt 组装，Jinja2 渲染，Filament 解析        │
├─────────────────────────────────────────────────────────────┤
│                    数据层 (Mnemosyne)                        │
│                    The Memory (记忆)                         │
│  SQLite 存储，状态快照，VWD 数据模型，Patching 机制           │
├─────────────────────────────────────────────────────────────┤
│                    基础设施 (Infrastructure)                 │
│  依赖注入 (GetIt/Riverpod)，事件总线 (ClothoNexus)，日志     │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 核心子系统

| 子系统 | 隐喻 | 技术名 | 职责 |
|--------|------|--------|------|
| **Jacquard** | 提花织机 | 编排引擎 | 流程控制、Prompt 组装、LLM 调用 |
| **Mnemosyne** | 记忆女神 | 数据引擎 | 数据存储、快照生成、状态管理 |
| **Muse** | 缪斯女神 | 智能服务 | LLM 网关、Agent 宿主、技能系统 |
| **Presentation** | 舞台 | 表现层 | UI 渲染、用户交互、事件触发 |

### 2.3 双术语体系

Clotho 采用**双术语体系**，根据场景选择：

| 场景 | 术语体系 | 示例 |
|------|---------|------|
| **架构文档** | 隐喻术语 | Tapestry (织卷), Pattern (织谱), Threads (丝络) |
| **代码实现** | 技术术语 | Session (会话), Persona (角色设定), Context (上下文) |

**术语映射表**:

| 隐喻术语 | 技术术语 | 代码示例 |
|---------|---------|---------|
| Tapestry (织卷) | Session | `final session = await getSession(id);` |
| Pattern (织谱) | Persona | `final persona = session.persona;` |
| Threads (丝络) | Context/StateTree | `final context = session.context;` |
| Punchcards (穿孔卡) | Snapshot | `final snapshot = await createSnapshot(id);` |
| Skein (绞纱) | PromptBundle | `final bundle = await assemblePrompt(id, input);` |

---

## 3. 核心协议 (Core Protocols)

### 3.1 Filament 协议 (LLM 交互语言)

**非对称交互设计**:

| 方向 | 格式 | 说明 |
|------|------|------|
| **Input (Prompt)** | XML + YAML | XML 构建骨架，YAML 描述数据（低 Token 消耗） |
| **Output (Instruction)** | XML + JSON | XML 标识意图，JSON 描述参数（严格语法） |

**输入示例**:
```xml
<system>
  <role>你是一位专业的 RPG 游戏主持人</role>
  <state yaml="true">
    character:
      hp: [80, "生命值，0 时死亡"]
      mana: 50
  </state>
</system>
```

**输出示例**:
```xml
<thought>玩家似乎想探索森林，我需要描述环境...</thought>
<content>你踏入了幽暗的森林，阳光透过树叶洒下斑驳的光影...</content>
<variable_update json="true">
  {"op": "replace", "path": "/character/location", "value": "dark_forest"}
</variable_update>
```

### 3.2 单向数据流

```
UI (只读) → Intent → Jacquard → Mnemosyne (状态变更) → Stream → UI (重绘)
```

**核心规则**: UI 层严禁直接修改 Mnemosyne 数据库或状态树。

---

## 4. 项目结构 (Project Structure)

```
d:\Project\Clotho-Design\
├── 00_active_specs/          # SSOT: 架构设计文档 (单一事实来源)
│   ├── jacquard/             # 编排层设计文档
│   ├── mnemosyne/            # 数据层设计文档
│   ├── muse/                 # 智能服务设计文档
│   ├── presentation/         # 表现层设计文档
│   ├── protocols/            # Filament 协议文档
│   ├── runtime/              # 运行时架构文档
│   ├── workflows/            # 工作流文档
│   ├── infrastructure/       # 基础设施文档
│   └── reference/            # 参考文档
├── 08_demo/                  # Flutter UI 原型 (活跃代码)
│   ├── lib/                  # Dart 源代码
│   ├── test/                 # 测试文件
│   └── pubspec.yaml          # Flutter 依赖配置
├── 09_mvp/                   # MVP 版本代码
├── 01_drafts/                # 草稿文档
├── 02_active_plans/          # 活跃计划
├── 10_references/            # 参考资料
└── 99_archive/               # 归档文档
```

---

## 5. 开发与构建 (Development & Build)

### 5.1 环境要求

- **SDK**: Dart >= 3.0.0 < 4.0.0
- **框架**: Flutter (跨平台 UI)
- **IDE**: VS Code / Android Studio / IntelliJ IDEA

### 5.2 构建命令

```bash
# 进入演示项目目录
cd 08_demo

# 安装依赖
flutter pub get

# 运行代码生成 (injectable 等)
flutter pub run build_runner build --delete-conflicting-outputs

# 运行应用 (Web 优先)
flutter run -d chrome

# 运行应用 (Windows)
flutter run -d windows

# 运行测试
flutter test

# 代码分析
flutter analyze
```

### 5.3 核心依赖

| 类别 | 包名 | 用途 |
|------|------|------|
| **状态管理** | `flutter_riverpod` | UI 状态绑定 |
| **依赖注入** | `get_it`, `injectable` | 服务注册与注入 |
| **网络** | `dio` | HTTP 客户端 |
| **数据库** | `sqflite` | SQLite 本地存储 |
| **解析** | `xml` | Filament 协议解析 |
| **工具** | `uuid`, `path` | 唯一标识符、路径处理 |

---

## 6. 架构原则 (Architectural Principles)

### 6.1 绝对约束 (The "Must-Nots")

1. **UI 层严禁包含业务逻辑**: UI 组件不得直接修改数据模型
2. **LLM 输出严禁直接执行**: 必须经过 Parser 清洗与校验，严禁 `eval`
3. **状态严禁多头管理**: 所有状态变更必须提交给 Mnemosyne 统一处理
4. **严禁 Prompt 污染**: 严禁在 Prompt 中包含复杂的逻辑运算指令

### 6.2 数据流原则

| 原则 | 说明 |
|------|------|
| **单向数据流** | UI → Intent → Logic → Data → Stream → UI |
| **SSOT** | `00_active_specs/` 是唯一权威文档源 |
| **Patching 机制** | L3 层通过 Patching 对 L2 层进行非破坏性修改 |

### 6.3 性能基调

- **首屏加载**: < 1s
- **长列表滚动**: 60fps (即使大量历史消息)
- **内存占用**: 严格控制图片与上下文缓存
- **响应时间**: 用户操作到视觉反馈 < 100ms

---

## 7. 文档导航 (Documentation Navigation)

### 7.1 快速入门路径

| 角色 | 阅读顺序 |
|------|---------|
| **新用户** | `vision-and-philosophy.md` → `metaphor-glossary.md` → `naming-convention.md` |
| **架构师** | `jacquard/README.md` → `mnemosyne/README.md` → `presentation/README.md` |
| **协议开发者** | `protocols/filament-protocol-overview.md` → `protocols/filament-input-format.md` → `protocols/filament-output-format.md` |
| **迁移工程师** | `workflows/character-import-migration.md` → `workflows/migration-strategy.md` |

### 7.2 核心文档索引

| 文档 | 路径 | 说明 |
|------|------|------|
| **架构索引** | `00_active_specs/README.md` | 文档结构导航 |
| **愿景与哲学** | `00_active_specs/vision-and-philosophy.md` | 设计理念 |
| **术语表** | `00_active_specs/metaphor-glossary.md` | 纺织隐喻体系 |
| **命名规范** | `00_active_specs/naming-convention.md` | 代码命名规则 |
| **文档标准** | `00_active_specs/reference/documentation_standards.md` | 文档撰写规范 |

---

## 8. AI 助手行为准则 (AI Assistant Guidelines)

### 8.1 三大检查 (Self-Checks)

在生成代码或提出方案前，必须通过以下检查：

1. **凯撒原则检查**:
   - 问："我是否将业务逻辑/数学/状态管理放入了 LLM Prompt？"
   - 规则：**绝不**。确定性逻辑属于代码 (Jacquard/Mnemosyne)。

2. **Filament 协议检查**:
   - 问："我如何结构化发送给 LLM 的数据？"
   - 规则：必须使用 **Filament 协议** (`XML+YAML` 输入，`XML+JSON` 输出)。

3. **单向数据流检查**:
   - 问："UI 是否直接修改了 Mnemosyne 数据库？"
   - 规则：**绝不**。UI 是只读的，必须通过 Intent 触发变更。

### 8.2 代码生成规范

| 用途 | 语言 | 说明 |
|------|------|------|
| **实现代码** | Dart | 项目唯一技术栈 |
| **配置文件** | YAML | 协议定义、预设配置 |
| **数据交换** | JSON | API 响应、状态序列化 |
| **协议格式** | XML | Filament 协议示例 |
| **流程图** | Mermaid | 架构和流程说明 |

**禁止使用**: TypeScript/JavaScript/Python (除非明确标注为伪代码)

### 8.3 术语使用

- ✅ 使用 "Pattern (织谱)", "Tapestry (织卷)", "Threads (丝络)"
- ❌ 避免使用 "Character Card", "Chat History" 等旧术语

---

## 9. 关键设计决策 (Key Design Decisions)

### 9.1 为什么选择 Flutter？

| 问题 | SillyTavern (Web) | Clotho (Flutter) |
|------|------------------|------------------|
| **性能** | 长文本渲染卡顿 | 原生 60fps 渲染 |
| **内存** | 随对话长度指数增长 | 线性增长，可控缓存 |
| **跨平台** | 浏览器依赖 | 原生编译，一致体验 |

### 9.2 Turn-Centric 架构 (v1.1)

- **核心**: 将微观叙事功能整合进 Turn 对象
- **Turn Summary**: 每个回合的摘要，用于 RAG 检索
- **优势**: 消除冗余，简化 RAG 流程

### 9.3 VWD 数据模型 (Value with Description)

```json
{
  "health": [80, "HP, 0 is dead"],  // 完整形式
  "mana": 50                         // 简写形式
}
```

- **System Prompt**: 渲染完整 `[Value, Description]`
- **UI Display**: 仅渲染 `Value`

### 9.4 稀疏快照与 OpLog

- **快照密度**: 每 50 轮对话生成全量 Keyframe
- **Delta 存储**: 使用 JSON Patch 格式的 OpLog
- **重建逻辑**: 查找最近 Keyframe → 顺序应用 Deltas

---

## 10. 当前状态与下一步 (Current Status & Next Steps)

### 10.1 设计成熟度评估

| 模块 | 版本 | 状态 | 成熟度 |
|------|------|------|--------|
| **Filament 协议** | v2.4.0 | Active | 🟢 高 |
| **Muse 智能服务** | v3.1.0 | Active | 🟢 高 |
| **导入与迁移** | v2.1.0 | Active | 🟢 高 |
| **Jacquard 编排** | v1.1.0 | Active | 🔵 中 |
| **Mnemosyne 数据** | v1.2.0 | Active | 🔵 中 |
| **表现层** | v1.2.0 | Active | 🟡 初级 |

### 10.2 下一步计划

1. **原型验证 (PoC)**:
   - 实现 MuseService (Raw Gateway) 与 Jacquard 核心流水线
   - 构建 Mnemosyne MVP，验证 VWD 与快照机制

2. **协议固化**:
   - 基于 Filament v2.4 编写测试用例

3. **UI 框架搭建**:
   - 搭建 Flutter 项目骨架
   - 实现 ClothoNexus 事件总线

4. **数据迁移工具**:
   - 开发导入向导核心分析引擎

---

## 11. 相关资源 (Related Resources)

| 资源 | 路径 | 说明 |
|------|------|------|
| **AGENTS.md** | `./AGENTS.md` | AI 助手导航手册 (Mission Control) |
| **readme.md** | `./readme.md` | 项目设计现状与详细介绍 |
| **clotho-specs.xml** | `./clotho-specs.xml` | 架构文档 XML 聚合 (61 个文档) |

---

*本文档由 AI 助手生成，基于 `00_active_specs/` 目录下的权威架构文档。*
*最后审查日期：2026-03-11*
