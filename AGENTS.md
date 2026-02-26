# Clotho 项目 AI 助手指南

**项目类型**: 设计/文档仓库（AI RPG 客户端架构设计）  
**主要语言**: 简体中文 (zh-CN)  
**目标实现技术栈**: Flutter/Dart (跨平台客户端)

---

## 1. 项目概述

Clotho 是一个面向下一代 AI 角色扮演（RPG）的高性能、确定性客户端的设计文档仓库。本仓库包含系统架构、设计规范、协议定义和技术分析文档。项目致力于解决现有方案（如 SillyTavern）在逻辑处理、上下文管理和性能上的根本性痛点。

### 1.1 核心痛点与解决方案

| 痛点 | 现有方案问题 | Clotho 解决方案 |
|------|-------------|----------------|
| **性能瓶颈** | Web 技术栈在长文本渲染和内存管理上存在先天劣势 | 采用 **Flutter** 原生编译，实现 Windows/Android 多端高性能体验 |
| **逻辑混沌** | 逻辑处理与界面表现高度耦合，过度依赖 LLM 进行逻辑判断 | 严格三层架构隔离，**凯撒原则**确保确定性逻辑由代码掌控 |
| **时空错乱** | 回溯、重绘、分支操作中上下文状态易失一致 | **织卷模型 (Tapestry Model)** + 快照机制支持无损时间回溯 |

### 1.2 设计哲学：凯撒原则 (The Caesar Principle)

> **"Render unto Caesar the things that are Caesar's, and unto God the things that are God's."**  
> **(凯撒的归凯撒，上帝的归上帝)**

- **凯撒的归凯撒 (Code's Domain)**：逻辑判断、数值计算、状态管理、流程控制。这些必须由确定性的代码严密掌控，**绝不外包给 LLM**。
- **上帝的归上帝 (LLM's Domain)**：语义理解、情感演绎、剧情生成、文本润色。这是 LLM 的"神性"所在，系统应让其专注于此。

---

## 2. 系统架构概览

### 2.1 三层物理隔离架构

```
┌─────────────────────────────────────────────────────────────┐
│                      表现层 (The Stage)                      │
│                   Flutter UI / WebView                      │
│                      【无业务逻辑】                          │
├─────────────────────────────────────────────────────────────┤
│                    编排层 (The Loom - Jacquard)              │
│           插件化流水线 / Prompt 组装 / 协议解析              │
│                    【确定性编排】                            │
├─────────────────────────────────────────────────────────────┤
│                  数据层 (The Memory - Mnemosyne)             │
│            多维上下文链 / 动态快照 / 时空回溯                │
│                    【唯一状态源】                            │
├─────────────────────────────────────────────────────────────┤
│                     基础设施 (Infrastructure)                │
│           依赖注入 / 跨平台抽象 / ClothoNexus 总线          │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 纺织隐喻体系 (核心术语)

系统采用完整的纺织隐喻体系，所有文档和代码应使用以下标准术语：

| 术语 (EN) | 术语 (CN) | 传统概念 | 技术定义 |
|-----------|----------|----------|----------|
| **Clotho** | **Clotho** | - | 整个应用系统 |
| **Jacquard** | **Jacquard** | Orchestration Layer | 编排引擎，系统的核心调度器 |
| **Mnemosyne** | **Mnemosyne** | Data Engine | 数据引擎，存储中枢与动态投影生成者 |
| **The Pattern** | **织谱** | Character Card | 静态定义集（只读蓝图） |
| **The Tapestry** | **织卷** | Chat / Session | 运行时实例/存档 |
| **Threads** | **丝络** | Message History | 动态状态流/历史记录 |
| **Skein** | **绞纱** | - | 结构化容器，Prompt 组装过程中的临时载体 |
| **Filament** | **纤丝** | Protocol | 交互协议 (XML+YAML/JSON) |
| **Punchcards** | **穿孔卡** | Snapshot | 世界状态快照 |

---

## 3. 目录结构与单一事实来源 (SSOT)

### 3.1 核心架构文档 (`00_active_specs/`)

**`00_active_specs/` 是项目的唯一权威文档源。** 在回答任何关于项目架构、功能、数据结构或工作流的问题前，**必须**先查阅该目录下的相关文档。

#### 文档组织结构

```
00_active_specs/
├── README.md                          # 架构文档索引（入口点）
├── vision-and-philosophy.md           # 愿景与哲学（凯撒原则）
├── architecture-principles.md         # 架构原则
├── metaphor-glossary.md               # 术语表与隐喻体系
│
├── infrastructure/                    # 基础设施层
│   ├── README.md                      # 基础设施概览
│   ├── dependency-injection.md        # 依赖注入
│   ├── clotho-nexus-events.md         # ClothoNexus 事件总线
│   ├── file-system-abstraction.md     # 文件系统抽象
│   ├── error-handling-and-cancellation.md  # 错误处理
│   └── logging-standards.md           # 日志规范
│
├── jacquard/                          # 编排层 (The Loom)
│   ├── README.md                      # Jacquard 概览
│   ├── planner-component.md           # 规划器组件
│   ├── preset-system.md               # 预设系统
│   ├── scheduler-component.md         # 调度器组件
│   ├── skein-and-weaving.md           # 丝络与织造
│   └── plugin-architecture.md         # 插件架构
│
├── mnemosyne/                         # 数据引擎 (The Memory)
│   ├── README.md                      # Mnemosyne 概览
│   ├── abstract-data-structures.md    # 抽象数据结构
│   ├── hybrid-resource-management.md  # 混合资源管理
│   └── sqlite-architecture.md         # SQLite 架构
│
├── presentation/                      # 表现层 (The Stage)
│   ├── README.md                      # 表现层概览
│   ├── 01-design-tokens.md ~ 17-animation.md  # UI 设计规范
│   ├── hybrid-sdui.md                 # 混合 SDUI
│   └── webview-bridge-api.md          # WebView 桥接 API
│
├── muse/                              # 智能服务
│   ├── README.md                      # Muse 概览
│   └── streaming-and-billing-design.md # 流式与计费设计
│
├── protocols/                         # 协议与格式
│   ├── README.md                      # 协议概览
│   ├── filament-protocol-overview.md  # Filament 协议总览
│   ├── filament-input-format.md       # 输入格式 (XML+YAML)
│   ├── filament-output-format.md      # 输出格式 (XML+JSON)
│   ├── filament-parsing-workflow.md   # 解析工作流
│   ├── jinja2-macro-system.md         # Jinja2 宏系统
│   └── schema-library.md              # Schema 库
│
├── workflows/                         # 工作流
│   ├── README.md                      # 工作流概览
│   ├── prompt-processing.md           # 提示词处理流程
│   ├── character-import-migration.md  # 角色卡导入与迁移
│   ├── migration-strategy.md          # 迁移策略
│   └── post-generation-processing.md  # 生成后处理
│
├── runtime/                           # 运行时架构
│   ├── README.md                      # 运行时概览
│   └── layered-runtime-architecture.md # 分层运行时架构 (L0-L3)
│
└── reference/                         # 参考文档
    ├── README.md                      # 参考文档索引
    ├── documentation_standards.md     # 文档编写规范
    ├── macro-system-spec.md           # 宏系统规范
    ├── st-macro-reference.md          # SillyTavern 宏参考
    └── acu-architecture-analysis.md   # ACU 架构分析
```

### 3.2 工作目录

| 目录 | 用途 |
|------|------|
| `01_drafts/` | 设计草稿（工作进行中，未定型） |
| `02_active_plans/` | 活跃计划（具体功能的详细规范） |
| `03_actvie_craft/` | 详细工艺规范（组件设计与分析） |
| `08_demo/` | **Flutter 演示应用** - 包含可运行的 UI 原型代码 |
| `10_references/` | 外部参考资料与分析（第三方框架、数据库分析等） |
| `15_meta_crital/` | 元批判分析（设计审计与审查） |
| `18_draw/` | 架构图文件（DrawIO 格式） |
| `66_gift/` | 补充材料与额外资源 |
| `99_archive/` | 历史归档（已弃用的设计） |

### 3.3 工具脚本 (`scripts/`)

| 脚本 | 用途 |
|------|------|
| `merge_specs_to_xml.py` | 将 `00_active_specs/` 下的 Markdown 文档合并为 `clotho-specs.xml` |

---

## 4. 代码与演示项目

### 4.1 Flutter 演示应用 (`08_demo/`)

目录包含一个可运行的 Flutter 演示应用，用于验证 UI 设计规范：

```yaml
# pubspec.yaml 关键配置
name: clotho_ui_demo
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.9    # 状态管理
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
```

#### 项目结构

```
08_demo/
├── lib/
│   ├── main.dart                    # 应用入口
│   ├── theme/
│   │   ├── app_theme.dart           # 主题配置
│   │   └── design_tokens.dart       # 设计令牌
│   ├── models/
│   │   ├── message.dart             # 消息模型
│   │   └── state_node.dart          # 状态节点模型
│   ├── screens/
│   │   └── home_screen.dart         # 主屏幕
│   └── widgets/
│       ├── inspector/               # 检查器组件
│       ├── layout/                  # 布局组件
│       ├── navigation/              # 导航组件
│       └── stage/                   # 舞台组件
├── pubspec.yaml
└── web/                             # Web 构建输出
```

#### 构建命令

```bash
# 进入演示目录
cd 08_demo

# 获取依赖
flutter pub get

# 运行调试（Chrome）
flutter run -d chrome

# 构建 Web 版本
flutter build web

# 运行测试
flutter test

# 代码分析
flutter analyze
```

### 4.2 文档处理脚本 (`scripts/`)

```bash
# 合并规格文档为 XML
python scripts/merge_specs_to_xml.py

# 输出：clotho-specs.xml（项目根目录）
```

---

## 5. 文档标准与撰写规范

### 5.1 语言与语调

- **默认语言**：简体中文 (zh-CN)
- **专有名词**：首次使用 "中文 (English)" 格式，之后保持一致
- **语调**：
  - ✅ 专业 (Professional)：保持技术文档的严肃性
  - ✅ 直接 (Direct)：直入主题
  - ❌ 禁止："Great", "Sure", "Certainly" 等对话式填充词

### 5.2 文件头部元数据格式

每个文档必须包含以下头部元数据：

```markdown
# 文档标题

**版本**: x.x.x
**日期**: YYYY-MM-DD
**状态**: Draft/Active/Deprecated
**作者**: 作者名称
```

### 5.3 术语使用规范

必须严格遵守 `00_active_specs/metaphor-glossary.md` 定义的隐喻体系：

| 必须使用 (New) | 禁止用于新架构 (Legacy) |
|----------------|------------------------|
| The Pattern / 织谱 | Character Card / 角色卡 |
| The Tapestry / 织卷 | Chat / Session / 对话 |
| Threads / 丝络 | Message History / 历史记录 |
| Lore / Texture | World Info / 世界书 |
| Punchcards | Snapshot / 快照 |

**例外**：仅在描述与传统概念的映射关系时，可以引用旧术语。

### 5.4 链接规范

- 使用相对路径引用其他文档
- 创建链接前必须确认目标文件存在
- 示例：`[Jacquard 概览](../jacquard/README.md)`

### 5.5 Mermaid 图表规范

- 避免在 `[]` 内使用双引号 `""` 或括号 `()`
- 使用标准 Markdown 标题层级 (`#`, `##`, `###`)
- 代码块必须指定语言类型

---

## 6. AI 审查清单 (Review Checklist)

在提交任何文档更改前，必须执行以下自我审查：

- [ ] **SSOT 检查**: 内容是否与 `00_active_specs/` 中的规范冲突？
- [ ] **重复性检查**: 内容是否已在其他文件中存在？如果是，是否应该改为引用？
- [ ] **链接有效性**: 所有新增的 `[Link](path)` 相对路径是否真实存在且正确？
- [ ] **术语一致性**: 是否使用了 "Pattern", "Tapestry", "Jacquard" 等标准术语？
- [ ] **目录位置**: 文件是否放置在正确的子目录下？
- [ ] **语调检查**: 是否去除了 "Great", "Sure" 等对话式填充词？

---

## 7. 关键设计规范速查

### 7.1 Filament 协议格式

**输入 (Prompt)**: XML + YAML
```xml
<filament>
  <context>
    <system>系统指令</system>
    <history>
      - role: user
        content: "用户消息"
    </history>
  </context>
</filament>
```

**输出 (Instruction)**: XML + JSON
```xml
<filament>
  <thought>推理过程</thought>
  <content>回复内容</content>
  <variable_update>
    {"hp": 80, "mood": "happy"}
  </variable_update>
</filament>
```

### 7.2 运行时分层 (L0-L3)

| 层级 | 名称 | 内容 | 可变性 |
|------|------|------|--------|
| L0 | Infrastructure | Prompt Template、API 配置 | 只读 |
| L1 | Environment | 用户 Persona、全局 Lorebook | 只读 |
| L2 | The Pattern | 织谱（原角色卡） | 只读 |
| L3 | The Threads | 丝络（状态补丁、历史记录） | 读写 |

**Patching 机制**: L3 通过补丁对 L2 进行非破坏性修改，支持平行宇宙存档。

### 7.3 Jacquard 流水线插件顺序

```
Input → [Planner] → [Skein Builder] → [Template Renderer] → [Invoker] → [Parser] → Output
         意图规划      上下文构建         Jinja2 渲染         LLM 调用     协议解析
```

### 7.4 绝对约束 (The "Must-Nots")

1. **UI 层严禁包含业务逻辑**: UI 组件不得直接修改数据模型，必须通过 Intent/Event 发送给逻辑层
2. **LLM 输出严禁直接执行**: 必须经过 Parser 清洗与校验，严禁 `eval`
3. **状态严禁多头管理**: 所有状态变更必须提交给 Mnemosyne 统一处理
4. **严禁 Prompt 污染**: 严禁在 Prompt 中包含复杂的逻辑运算指令

---

## 8. 开发与测试策略

### 8.1 设计成熟度评估

| 模块 | 版本 | 状态 | 成熟度 |
|------|------|------|--------|
| Filament 协议 | v2.3.0 | Draft | 🟢 高 |
| Muse 智能服务 | v3.0.0 | Draft | 🟢 高 |
| 导入与迁移工作流 | v2.1.0 | Active | 🟢 高 |
| 运行时架构 | v1.1.0 | Draft | 🔵 中 |
| Jacquard 编排层 | v1.0.0 | Draft | 🔵 中 |
| Mnemosyne 数据引擎 | v1.0.0 | Draft | 🔵 中 |
| 表现层 (Stage) | v1.0.0 | Draft | 🟡 初级 |
| 基础设施 | v1.0.0 | Draft | 🟡 初级 |

### 8.2 测试策略

由于本项目是设计文档仓库，"测试"主要指：

1. **文档一致性测试**: 确保各文档间无冲突
2. **链接有效性测试**: 确保所有相对链接指向存在的文件
3. **术语一致性测试**: 确保使用标准纺织隐喻术语
4. **原型验证**: 通过 `08_demo/` 验证 UI 设计可行性

### 8.3 原型验证步骤

```bash
# 1. 运行演示应用验证 UI 设计
cd 08_demo
flutter run -d chrome

# 2. 合并规格文档检查完整性
python scripts/merge_specs_to_xml.py

# 3. 检查生成的 XML 是否完整
# 查看 clotho-specs.xml 中的分类统计
```

---

## 9. 安全与隐私考虑

### 9.1 设计阶段安全原则

- **沙箱隔离**: 脚本运行在受限沙箱中（特别是 WebView 中的第三方内容）
- **输入验证**: 所有外部输入（包括 LLM 输出）必须经过严格验证
- **权限控制**: 细粒度的数据访问权限（ACL）
- **隐私保护**: 用户数据本地优先，可选加密存储

### 9.2 协议安全

- Filament 协议输出必须经过 Parser 清洗
- 严禁直接执行 LLM 生成的代码或脚本
- 状态变更必须通过 Mnemosyne 统一处理

---

## 10. 协作与贡献指南

### 10.1 文档更新流程

1. **查阅现有规范**: 首先阅读 `00_active_specs/` 相关文件
2. **确定文档位置**: 根据内容类别选择正确子目录
3. **应用标准格式**: 使用标准头部元数据，遵循术语规范
4. **执行审查清单**: 完成 AI 审查清单中的所有检查项
5. **更新版本号**: 修改文档版本和日期

### 10.2 自定义技能

项目包含一个自定义 CLI 技能：

- **路径**: `.roo/skills/clotho-documentation-author/SKILL.md`
- **用途**: 在创建或更新 `00_active_specs/` 文档时确保符合项目标准
- **功能**: 验证文档位置、术语一致性、格式规则和审查清单

### 10.3 自动引用指令

1. **始终先查阅规范**: 回答架构、功能、数据结构或工作流问题时，必须先查阅 `00_active_specs/` 中的相关文件
2. **不要猜测**: 如果 `00_active_specs/` 中已定义实现细节，不要凭空猜测
3. **上下文意识**: `00_active_specs/` 是活跃上下文，需要"记住"模块工作方式时，应阅读相应文件

---

## 11. 关联资源

### 11.1 必读入口文档

| 文档 | 用途 |
|------|------|
| `00_active_specs/README.md` | 架构文档索引（首要入口） |
| `00_active_specs/vision-and-philosophy.md` | 理解设计理念（凯撒原则） |
| `00_active_specs/metaphor-glossary.md` | 理解核心术语 |
| `00_active_specs/reference/documentation_standards.md` | 文档编写规范 |

### 11.2 外部参考框架 (`10_references/`)

- **AgentSkills**: Agent 技能框架源代码
- **LittleWhiteBox**: 第三方故事框架
- **ERA**: 变量框架
- **Character Card Spec v3**: 角色卡规范 v3.0 参考

### 11.3 架构图

- `18_draw/high_level_arch.drawio` - 高层架构图
- `18_draw/data_flow_pipeline.drawio` - 数据流管道图
- `18_draw/database_erd.drawio` - 数据库 ERD 图

---

*本文档最后更新: 2026-02-13*  
*AGENTS.md 版本: 2.0.0*
