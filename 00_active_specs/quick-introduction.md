# Clotho 项目快速介绍

**文档类型**: AI/新成员快速了解  
**目标读者**: 新加入的开发者、AI 助手、项目合作者  
**预计阅读时间**: 5-10 分钟  
**最后更新**: 2025-12-30

---

## 🎯 一句话介绍

Clotho 是一个**高性能、跨平台**的下一代 AI 角色扮演（RPG）客户端，基于 **Flutter** 构建，旨在解决现有方案（如 SillyTavern）在逻辑处理、上下文管理和性能上的根本性痛点，为 Windows、Android 等多端提供一致的确定性体验。

## 📋 核心问题域

Clotho 主要解决以下三个核心问题：

| 问题领域 | 传统方案痛点 | Clotho 解决方案 |
|----------|--------------|----------------|
| **性能瓶颈** | Web 技术栈导致长文本渲染卡顿、内存泄漏 | **原生跨平台技术栈**：Flutter/Dart 驱动，实现 60fps 流畅滚动与多端统一的高性能表现 |
| **时空一致性** | 回溯、重绘、分支操作导致状态错乱 | **多重宇宙树模型**：确保世界状态严丝合缝 |
| **逻辑解耦** | UI 与业务逻辑紧密耦合，难以维护 | **三层架构分离**：表现层、编排层、数据层物理隔离 |
| **记忆叙事冲突** | 高频互动（如摸头）污染上下文，关键剧情遗忘 | **双层混合事件模型**：数值与事件分离，保证日常与剧情兼顾 |
| **多角色隐私** | “全知全能”的出戏感，无法处理秘密与误会 | **动态作用域 ACL**：基于角色的信息访问控制 |

## 🏗️ 核心架构概览

Clotho 采用 **"混合代理 (Hybrid Agency)"** 架构，严格遵循 **"凯撒原则 (The Caesar Principle)"**：

> **"Render unto Caesar the things that are Caesar's, and unto God the things that are God's."**  
> **（凯撒的归凯撒，上帝的归上帝）**

### 三大核心生态

1. **表现生态 (The Stage)**
   - **职责**: 纯粹的渲染与交互界面，**无业务逻辑**
   - **技术**: Flutter 原生 + WebView 混合渲染
   - **哲学**: "Stage & Control" 布局，沉浸式体验

2. **编排生态 (The Loom - Jacquard)**
   - **职责**: 系统的"大脑"与"总线"，插件化流水线
   - **特性**: 确定性流程编排，支持 Jinja2 模板渲染
   - **核心**: Skein（结构化 Prompt 容器）、Filament 协议解析

3. **记忆生态 (The Memory - Mnemosyne)**
   - **职责**: 系统的"海马体"，动态上下文生成引擎
   - **特性**: **双层混合事件模型**（数值/事件分离）、多维上下文链
   - **能力**: **动态 ACL 过滤**、时空回溯、状态快照、动态补丁

### 关键技术组件

| 组件 | 角色 | 关键特性 |
|------|------|----------|
| **Jacquard** | 编排层核心 | **Pre-Flash 意图分流**、插件化流水线、Skein 容器 |
| **Mnemosyne** | 数据层核心 | **混合事件存储**、**ACL 隐私控制**、Post-Flash 记忆整合 |
| **Filament 协议** | 统一交互语言 | XML+YAML 输入、XML+JSON 输出、Jinja2 集成 |
| **分层运行时** | 运行时环境 | 四层叠加模型 (L0-L3)、写时复制、动态补丁 |

## 🔄 关键工作流程

### 1. 提示词处理流程

```
用户输入 → Pre-Flash 意图分流 (L1/L2/L3) → RAG 检索 & ACL 过滤 → Skein 组装 → Main LLM 调用 → Filament 解析 → 状态更新 → (异步) Post-Flash 记忆整合
```

**核心原则**:

- **意图分流 (Intent Triage)**: 简单互动走数值通道，复杂剧情走事件通道，节省 Token
- **隐私感知 (Privacy Aware)**: 基于 ACL 过滤记忆，防止角色"全知全能"
- **晚期绑定 (Late Binding)**: 变量替换发生在发送给 LLM 的最后一刻
- **无副作用 (Zero Side-Effect)**: 渲染层是纯函数，绝不修改状态
- **结构化容器 (Structured Container)**: 使用 Skein 而非长字符串传递数据

### 2. 角色卡导入与迁移

- **策略**: "深度分析 → 双重分诊 → 专用通道" 半自动处理
- **分诊**: 世界书条目（基础设定📘、指令型⚡、代码型🧩）、正则脚本（文本替换📝、数据清洗🧹、UI注入🎨）
- **格式规范化**: "XML 包裹 YAML" 统一格式

### 3. 状态管理与运行时

- **分层模型**: Infrastructure (L0) → Global Context (L1) → Character Assets (L2) → Session State (L3)
- **Patching 机制**: L3 层对 L2 蓝图的非破坏性修改，支持角色成长、设定重写、平行宇宙
- **数据流**: Freeze → Unload → Hydrate → Resume

## 📊 系统约束与设计原则

### 绝对约束 (The "Must-Nots")

1. **UI 层严禁包含业务逻辑**: 必须通过 Intent/Event 发送给逻辑层
2. **LLM 输出严禁直接执行**: 必须经过 Parser 清洗与校验，严禁 `eval`
3. **状态严禁多头管理**: 所有状态变更必须提交给 Mnemosyne 统一处理
4. **严禁 Prompt 污染**: 复杂逻辑运算必须在 Prompt 组装前由代码完成

### 性能基调

- **首屏加载**: < 1s
- **长列表滚动**: 60fps（即使在大量消息历史下）
- **内存占用**: 严格控制图片与上下文对象缓存策略

## 🔗 重要文档链接

### 入门必读

- **[架构文档主索引](README.md)** - 完整文档目录与结构
- **[愿景与设计哲学](overview/vision-and-philosophy.md)** - 项目根本指导思想
- **[Filament 协议概述](protocols/filament-protocol-overview.md)** - 系统统一交互语言

### 核心架构

- **[Jacquard 编排层](core/jacquard-orchestration.md)** - 系统"大脑"与流水线设计
- **[Mnemosyne 数据引擎](core/mnemosyne-data-engine.md)** - 动态上下文生成引擎
- **[分层运行时架构](runtime/layered-runtime-architecture.md)** - 四层叠加模型与 Patching 机制

### 实用参考

- **[术语表](reference/glossary.md)** - 核心术语定义
- **[Jinja2 宏系统](protocols/jinja2-macro-system.md)** - 模板引擎与宏迁移映射
- **[提示词处理工作流](workflows/prompt-processing-workflow.md)** - 完整处理流程详解

## 💡 典型使用场景

### 场景 1: 新角色卡导入

```
原始 ST 角色卡 → 分析引擎扫描 → 世界书分诊 → 正则脚本分诊 → 格式规范化 → 生成 Clotho 原生结构
```

### 场景 2: 对话流程

```
用户输入 → Pre-Flash (意图识别) → Mnemosyne (RAG + ACL 检索) → Main LLM (生成) → Filament 解析 → Post-Flash (记忆整合) → UI 渲染
```

### 场景 3: 状态回溯与分支

```
选择历史消息 → Mnemosyne 重建当时状态 (含数值与事件) → 继续对话 → 创建新分支 → 独立状态演进
```

## 🚨 注意事项

1. **架构差异**: Clotho 与 SillyTavern 有根本性架构差异，不是简单升级
2. **迁移策略**: 采用"交互式迁移向导"，而非全自动黑盒转译
3. **学习曲线**: 需要理解"凯撒原则"和三大生态分离理念
4. **扩展性**: 通过插件化流水线和 Jinja2 宏系统提供强大扩展能力

## 📞 获取帮助

- **文档问题**: 查看 [README.md](README.md) 中的完整文档结构
- **架构疑问**: 阅读 [core/](core/) 目录下的核心架构文档
- **协议细节**: 参考 [protocols/](protocols/) 目录中的 Filament 协议规范
- **迁移支持**: 查看 [workflows/](workflows/) 目录中的迁移指南

---

**文档版本**: 1.0.0  
**生成时间**: 2025-12-30  
**更新说明**: 本文档为 Clotho 项目快速介绍，适用于 AI 助手和新成员快速了解项目核心概念和架构。如需详细技术细节，请参阅各专题文档。
