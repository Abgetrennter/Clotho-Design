# 文档标准与撰写指南 (Documentation Standards)

**版本**: 1.1.0
**日期**: 2026-02-27
**状态**: Active
**适用对象**: AI 助手、文档维护者、贡献者

---

## 1. 简介 (Introduction)

本文档旨在为 Clotho 项目建立统一的文档撰写和维护标准。无论是人类作者还是 AI 助手，在创建或更新 `00_active_specs/` 下的文档时，都必须严格遵守本指南，以确保知识库的一致性、准确性和可读性。

## 2. 架构原则 (Architectural Principles)

### 2.1 单一事实来源 (Single Source of Truth, SSOT)

* **原则**: `00_active_specs/` 目录是项目的唯一权威文档源。
* **实践**:
  * **定义一次，引用多次**: 不要重复定义核心概念。例如，Jacquard 的详细逻辑应只在 [`jacquard/README.md`](../jacquard/README.md) 中定义，其他地方应使用链接引用。
  * **避免冲突**: 在写入新内容前，必须先搜索现有文档，确认是否存在冲突或重复。

## 3. 内容标准 (Content Standards)

### 3.1 语言 (Language)

* **默认语言**: **简体中文 (zh-CN)**。
* **专有名词**: 首次出现时可使用 "中文 (English)" 格式，之后使用中文或英文均可，但需保持一致。

### 3.2 术语 (Terminology)

必须严格遵守 [`../metaphor-glossary.md`](../metaphor-glossary.md) 中定义的隐喻体系。

* **Clotho**: 整个系统。
* **Jacquard**: 编排层/引擎。
* **Mnemosyne**: 数据引擎。
* **The Pattern (织谱)**: 静态定义集（原 Character Card）。
* **The Tapestry (织卷)**: 运行时实例/存档。
* **Threads (丝络)**: 动态状态流/历史记录。

🚫 **禁止使用**: 不要使用 "SillyTavern", "Character Card" , "Chat History" 等旧术语来描述新架构，但是可以引用作为在新架构中的映射内容

### 3.3 语调 (Voice)

* **专业 (Professional)**: 保持技术文档的严肃性。
* **直接 (Direct)**: 直入主题。
  * 🚫 错误: "太棒了！下面我为您展示如何配置..."
  * ✅ 正确: "配置步骤如下..."

## 4. 格式规则 (Formatting Rules)

### 4.1 结构

* 使用标准的 Markdown 标题 (#, ##, ###)。
* 文件头部必须包含 YAML/Frontmatter 风格的元数据：

    ```markdown
    # 文档标题
    **版本**: x.x.x
    **日期**: YYYY-MM-DD
    **状态**: Draft/Active/Deprecated
    ```

### 4.2 链接

* **相对链接**: 必须使用相对路径引用其他文档。
  * ✅ `[Mnemosyne](../mnemosyne/README.md)`
* **有效性检查**: 创建链接时，必须确认目标文件存在。

### 4.3 代码块

* 必须指定语言类型 (e.g., ```dart, ```yaml, ```mermaid)。
* Mermaid 图表中避免在 `[]` 内使用双引号 `""` 或括号 `()`。

---

## 5. 代码示例规范 (Code Example Standards)

### 5.1 语言选择

| 用途 | 推荐语言 | 说明 |
|------|----------|------|
| **实现代码** | **Dart** | Clotho 使用 Flutter 作为唯一技术栈 |
| **配置文件** | YAML | 用于协议定义、预设配置 |
| **数据交换** | JSON | 用于 API 响应、状态序列化 |
| **协议格式** | XML | 用于 Filament 协议示例 |
| **流程图** | Mermaid | 用于架构和流程说明 |

### 5.2 禁止使用的语言

* ❌ **TypeScript/JavaScript**: 项目不使用 Web 技术栈
* ❌ **Python**: 仅用于算法伪代码（需明确标注为伪代码）
* ❌ **Java/Kotlin/Swift**: 不使用原生移动开发语言

### 5.3 Dart 代码风格

* **类命名**: 使用 `PascalCase` (e.g., `SkeinBuilder`, `PromptBlock`)
* **接口定义**: 使用 `abstract class` 或 `mixin` (Dart 无 interface 关键字)
* **注释风格**: 使用 `///` 文档注释 (e.g., `/// Skein 构建器`)
* **缩进**: 2 空格缩进
* **文件路径注释**: 使用 `// lib/path/to/file.dart` 格式

### 5.4 示例模板

#### 接口定义

```dart
/// 接口定义示例
abstract class SkeinBuilder {
  /// 构建 Skein 实例
  ///
  /// 从 Mnemosyne 获取上下文快照并组装 Prompt
  Future<SkeinInstance> build({
    required String tapestryId,
    required String turnId,
    SkeinTemplate? template,
  });
}
```

#### 数据模型

```dart
// 数据模型示例
// lib/models/skein_instance.dart
class SkeinInstance {
  final String instanceId;
  final String templateId;
  final String tapestryId;
  final String turnId;
  
  const SkeinInstance({
    required this.instanceId,
    required this.templateId,
    required this.tapestryId,
    required this.turnId,
  });
}
```

#### 枚举类型

```dart
/// 区块类型枚举
enum BlockType {
  /// 系统指令
  systemInstruction,
  
  /// 角色设定
  characterDefinition,
  
  /// 历史记录
  chatHistory,
  
  /// 浮动资产
  floatingAsset,
}
```

### 5.5 伪代码规范

如需表达算法逻辑而非具体实现，使用以下格式：

```
// 伪代码：Weaving 算法
FUNCTION weave(instance, template):
  1. 构建骨架 (Skeleton)
  2. 锚定历史 (Anchoring)
  3. 编织浮线 (Floating Stitching)
  4. 去重 (Deduplication)
  5. 截断 (Truncation)
  RETURN 最终 Prompt
```

### 5.6 代码块语言标识

必须始终指定语言类型：

* ✅ `` ```dart ``
* ✅ `` ```yaml ``
* ✅ `` ```json ``
* ✅ `` ```xml ``
* ✅ `` ```mermaid ``
* ❌ `` ``` `` (无语言标识)
* ❌ `` ```typescript ``
* ❌ `` ```python `` (除非明确标注为伪代码)

---

## 6. 🤖 AI 审查清单 (AI Review Checklist)

AI 在提交任何文档更改前，必须执行以下自我审查：

* [ ] **重复性检查**: 本内容是否已在其他文件中存在？如果是，是否应该改为引用？
* [ ] **链接有效性**: 所有新增的 `[Link](path)` 路径是否真实存在且正确？
* [ ] **术语一致性**: 是否使用了 "Pattern", "Tapestry", "Jacquard" 等标准术语？是否避免了旧术语？
* [ ] **目录位置**: 文件是否放置在正确的子目录下（Core, Protocols, Workflows 等）？
* [ ] **语调检查**: 是否去除了 "Great", "Sure" 等对话式填充词？
* [ ] **代码示例语言**: 所有代码示例是否使用 Dart（配置/协议除外）？
