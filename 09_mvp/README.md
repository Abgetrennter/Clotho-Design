# Clotho MVP Demo

Clotho 架构的最小可行产品（MVP）演示系统，验证核心架构设计理念和 Filament 协议的可行性。

## 项目概述

本 Demo 旨在展示 Clotho 架构的核心价值：
- **确定性编排**：Jacquard 编排层负责 Prompt 组装和 LLM 调用
- **Filament 协议**：XML+JSON 格式的标准化 LLM 交互协议
- **凯撒原则**：逻辑归代码，语义归 LLM

## 功能范围

### 已实现功能 (P0/P1)

| 功能 | 描述 | 状态 |
|------|------|------|
| 基础对话交互 | 用户输入 → LLM 响应 | ✅ |
| 历史记录展示 | 线性展示对话历史 | ✅ |
| Filament 协议解析 | 解析 `<think>` 和 `<content>` 标签 | ✅ |
| Persona 加载 | 加载预设角色设定 | ✅ |

### 排除功能 (MVP 阶段)

- 状态管理（VWD 变量更新、StateTree 持久化）
- Pre-Generation（意图分流、Planner）
- RAG 检索
- 混合渲染引擎（RFW + WebView）
- 状态回溯与分支

## 项目结构

```
lib/
├── core/                          # 基础设施层
│   ├── exceptions/                # 异常定义
│   │   └── clotho_exception.dart
│   └── services/                  # 核心服务
│       └── clotho_nexus.dart      # 事件总线
│
├── mnemosyne/                     # 数据引擎 (Mnemosyne)
│   ├── models/                    # 数据模型
│   │   ├── message.dart           # 消息
│   │   ├── persona.dart           # 角色设定
│   │   ├── session.dart           # 会话
│   │   ├── session_context.dart   # 会话上下文
│   │   └── turn.dart              # 回合
│   ├── repositories/              # 数据访问
│   │   ├── persona_repository.dart
│   │   ├── session_repository.dart
│   │   ├── turn_repository.dart
│   │   └── in_memory_*.dart       # 内存版实现
│   └── mnemosyne_data_engine.dart # 数据引擎主类
│
├── jacquard/                      # 编排引擎 (Jacquard)
│   ├── models/                    # 内部模型
│   │   ├── prompt_block.dart      # 提示词块
│   │   └── prompt_bundle.dart     # 提示词包
│   ├── services/                  # 核心服务
│   │   ├── filament_parser.dart   # Filament 解析器
│   │   ├── llm_service.dart       # LLM API 服务
│   │   └── prompt_assembler.dart  # 提示词组装器
│   └── jacquard_orchestrator.dart # 编排器主类
│
├── domain/                        # 领域层 (UseCases)
│   └── use_cases/
│       ├── create_turn_use_case.dart
│       └── generate_response_use_case.dart
│
├── stage/                         # 表现层 (Stage)
│   ├── screens/
│   │   └── chat_screen.dart       # 聊天主界面
│   ├── widgets/
│   │   ├── message_bubble.dart    # 消息气泡
│   │   ├── message_list.dart      # 消息列表
│   │   └── input_area.dart        # 输入区域
│   └── providers/
│       └── chat_provider.dart     # 状态管理
│
└── main.dart                      # 应用入口

assets/
└── personas/
    └── seraphina.yaml             # 预设角色
```

## 技术栈

| 组件 | 技术选型 |
|------|----------|
| UI 框架 | Flutter 3.x |
| 状态管理 | Riverpod |
| HTTP 客户端 | Dio |
| Markdown 渲染 | flutter_markdown |
| XML 解析 | xml |
| YAML 解析 | yaml |
| UUID 生成 | uuid |

## 快速开始

### 环境要求

- Flutter SDK >= 3.10.8
- Dart SDK >= 3.0.0

### 安装依赖

```bash
cd 09_mvp
flutter pub get
```

### 配置 LLM API

编辑 `lib/stage/providers/chat_provider.dart`，替换 API Key：

```dart
final llmConfigProvider = Provider<LLMServiceConfig>((ref) {
  return const LLMServiceConfig(
    baseUrl: 'https://api.openai.com/v1',
    apiKey: 'YOUR_API_KEY_HERE', // TODO: 替换为实际 API Key
    model: 'gpt-4',
  );
});
```

### 运行应用

#### Web（推荐，快速迭代）

```bash
cd 09_mvp
flutter run -d chrome
```

#### 桌面/移动设备

```bash
# Windows
flutter run -d windows

# Android
flutter run -d android

# iOS
flutter run -d ios
```

## 功能验证步骤

### 1. 启动应用

```bash
cd 09_mvp
flutter run -d chrome
```

### 2. 基础对话测试

1. 应用启动后，显示聊天界面
2. 在输入框输入："你好，你是谁？"
3. 点击发送按钮
4. 观察 AI 回复（应显示 Seraphina 的角色扮演回复）

### 3. 历史记录测试

1. 继续发送多条消息
2. 向上滚动消息列表
3. 验证历史记录正确显示

### 4. 流式输出测试

1. 发送一条消息
2. 观察 AI 回复的流式输出效果
3. 验证文本逐字显示

## 架构说明

### 分层架构

```
┌─────────────────────────────────────┐
│         Stage (表现层)               │
│  - ChatScreen                       │
│  - MessageList, MessageBubble       │
│  - InputArea                        │
└─────────────────────────────────────┘
              ↓ Intent
┌─────────────────────────────────────┐
│      Domain (领域层/UseCases)        │
│  - GenerateResponseUseCase          │
│  - CreateTurnUseCase                │
└─────────────────────────────────────┘
              ↓ Query/Command
┌─────────────────────────────────────┐
│     Jacquard (编排层)                │
│  - JacquardOrchestrator             │
│  - PromptAssembler                  │
│  - LLMService                       │
│  - FilamentParser                   │
└─────────────────────────────────────┘
              ↓ Query/Save
┌─────────────────────────────────────┐
│    Mnemosyne (数据层)                │
│  - MnemosyneDataEngine              │
│  - Repositories                     │
│  - Models (Persona, Session, Turn)  │
└─────────────────────────────────────┘
```

### 数据流

```
用户输入 → ChatProvider → JacquardOrchestrator
                              ↓
                        PromptAssembler → PromptBundle
                              ↓
                        LLMService → LLM API
                              ↓
                        FilamentParser → 解析响应
                              ↓
                        Mnemosyne → 保存 Turn
                              ↓
                        ClothoNexus → 发布事件
                              ↓
                        ChatProvider → 更新 UI
```

## Filament 协议示例

### 输入格式（Prompt）

```xml
<system>
  你是 Seraphina，一名来自森林的精灵...
</system>

<user>
  你好，你是谁？
</user>
```

### 输出格式（Response）

```xml
<think>
用户询问我的身份，我应该友好地介绍自己...
</think>

<content>
你好，我是 Seraphina，一名来自森林的精灵...
</content>
```

## 预设 Persona

Demo 内置了预设角色 "Seraphina"（森林精灵），配置文件位于 `assets/personas/seraphina.yaml`：

```yaml
id: "per_seraphina_001"
name: "Seraphina"
description: "来自森林的精灵，擅长治疗魔法"
systemPrompt: |
  你是 Seraphina，一名来自森林的精灵...
firstMessage: |
  你好，旅行者。我是 Seraphina，这片森林的守护者...
```

## 代码质量

### 运行测试

```bash
cd 09_mvp
flutter test
```

### 代码分析

```bash
cd 09_mvp
flutter analyze
```

## 相关文档

- [MVP 设计文档](../02_active_plans/mvp-demo-design-spec.md)
- [架构原则](../00_active_specs/architecture-principles.md)
- [Filament 协议概述](../00_active_specs/protocols/filament-protocol-overview.md)
- [命名规范](../00_active_specs/naming-convention.md)

## 注意事项

1. **API Key 配置**：Demo 需要配置有效的 LLM API Key 才能正常工作
2. **网络要求**：需要能够访问 LLM API 服务
3. **MVP 限制**：本 Demo 为最小可行产品，部分功能（如持久化存储）使用内存实现，重启后数据丢失

## 下一步计划

- [ ] 实现 SQLite 持久化存储
- [ ] 添加多 Persona 支持
- [ ] 实现 Pre-Generation 意图分流
- [ ] 添加 RAG 检索功能
- [ ] 实现状态回溯与分支

---

**最后更新**: 2026-03-11
**版本**: 1.0.0
