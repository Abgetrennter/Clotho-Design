# Mnemosyne 2.0 数据结构与实现规范

**版本**: 2.1.0 (Dart Revised)
**日期**: 2026-01-04
**状态**: Approved Spec
**来源**: ACU Integration Proposal, Mnemosyne Data Engine 1.0

---

## 1. 核心设计理念

本规范定义了 Mnemosyne 引擎 2.0 版的核心数据结构。主要变更点在于吸取了 ACU (js-split-merged) 插件在长线叙事中的成功经验，引入了 **双层叙事链 (Dual-Layer Narrative Chain)**、**显式引用 (Explicit Linking)** 和 **增强型 VWD 模型**。

实现语言已从 TypeScript 变更为 **Dart**，以适配 Clotho App 的 Flutter 技术栈。

---

## 2. 基础类型系统 (Type System)

### 2.1 VWD (Value with Description)

VWD 是 Mnemosyne 的原子数据单元，解决了 LLM 对纯数值缺乏感知的问题。

#### 2.1.1 存储结构 (Storage Schema)
持久化时采用紧凑的元组格式，减少 JSON 体积。

```json
[80, "Current Health Points"]
```

#### 2.1.2 运行时模型 (Dart Model)
Dart 层使用自定义 `Converter` 处理 JSON 序列化。

```dart
import 'package:json_annotation/json_annotation.dart';

part 'vwd.g.dart';

@JsonSerializable()
class VWD<T> {
  T value;
  String description;

  VWD(this.value, this.description);

  /// Custom converter logic handled here or in a separate JsonConverter class
  factory VWD.fromJson(List<dynamic> json) {
    if (json.length < 2) throw FormatException("Invalid VWD tuple");
    return VWD(json[0] as T, json[1] as String);
  }

  List<dynamic> toJson() => [value, description];

  static VWD<T> from<T>(dynamic data, [String desc = ""]) {
    if (data is VWD<T>) return data;
    if (data is List && data.length == 2) {
      return VWD(data[0] as T, data[1] as String);
    }
    return VWD(data as T, desc);
  }
}
```

### 2.2 OpLog (Operation Log)
基于 JSON Patch 扩展的操作日志。

```dart
@JsonSerializable()
class OpLogEntry {
  final String op; // 'replace', 'add', 'remove', 'move'
  final String path; // JSON Pointer
  final dynamic value;
  final int timestamp;

  OpLogEntry({
    required this.op,
    required this.path,
    this.value,
    required this.timestamp,
  });
}
```

---

## 3. 叙事链 (Narrative Chain)

采用双层结构，分离"微观事实"与"宏观剧情"，直接映射 ACU 的 Summary/Outline 表格结构。

### 3.1 Micro-Log (微观日志)
**定位**: 每一轮对话的"客观黑匣子"。
**对应 ACU**: `Summary Table`

```dart
@JsonSerializable()
class MicroLog {
  final String id;
  @JsonKey(name: 'turn_id')
  final int turnId;
  final int timestamp;
  
  /// 核心内容: 高保真、零解读的客观事实
  final String summary;
  
  // 上下文快照
  final String location;
  @JsonKey(name: 'active_entities')
  final List<String> activeEntities; 
  
  // 索引引用 (对应 ACU AMxx)
  @JsonKey(name: 'ref_code')
  final String? refCode; 
  
  // 原始数据源
  @JsonKey(name: 'source_msg_id')
  final String sourceMsgId;

  MicroLog({
    required this.id,
    required this.turnId,
    required this.timestamp,
    required this.summary,
    required this.location,
    required this.activeEntities,
    this.refCode,
    required this.sourceMsgId,
  });
}
```

### 3.2 Macro-Event (宏观事件)
**定位**: 剧情章节的"目录索引"。
**对应 ACU**: `Outline Table`

```dart
@JsonSerializable()
class MacroEvent {
  final String id;
  final String title;
  final String summary;
  
  @JsonKey(name: 'start_turn')
  final int startTurn;
  @JsonKey(name: 'end_turn')
  final int endTurn;
  
  /// 子节点引用列表
  @JsonKey(name: 'child_refs')
  final List<String> childRefs; 
  
  final List<String> keywords;

  MacroEvent({
    required this.id,
    required this.title,
    required this.summary,
    required this.startTurn,
    required this.endTurn,
    required this.childRefs,
    required this.keywords,
  });
}
```

---

## 4. 事件链 (Event Chain)

**定位**: 关键逻辑节点 (Quest, Achievement)，具备跨越时空的引用能力。

```dart
@JsonSerializable()
class GlobalEvent {
  @JsonKey(name: 'event_id')
  final String eventId;
  
  final String type; // 'quest', 'achievement', 'milestone', 'fact'
  
  final String name;
  final String description;
  final String status; // 'active', 'completed', 'failed', 'inactive'
  
  final int timestamp;
  @JsonKey(name: 'turn_id')
  final int turnId;
  
  /// 显式引用 (Explicit Narrative Linking)
  /// 支持多源溯源，解决 RAG "有大概无细节" 的痛点
  @JsonKey(name: 'source_refs')
  final List<String> sourceRefs; // ["log:log_id_1", "msg:msg_id_2"]
  
  /// 扩展元数据 (对应 ACU Global Data)
  final Map<String, dynamic>? metadata;

  GlobalEvent({
    required this.eventId,
    required this.type,
    required this.name,
    required this.description,
    required this.status,
    required this.timestamp,
    required this.turnId,
    required this.sourceRefs,
    this.metadata,
  });
}
```

---

## 5. 状态树与元数据 ($meta)

### 5.1 StateMeta
所有状态节点均支持 `$meta` 字段，用于定义行为约束。

```dart
@JsonSerializable()
class StateMeta {
  final Map<String, dynamic>? template;
  final List<String>? required;
  final bool? extensible;
  
  final bool? updatable;
  final String? necessary; // 'self', 'children', 'all'
  
  @JsonKey(name: 'ui_schema')
  final Map<String, dynamic>? uiSchema;

  StateMeta({
    this.template,
    this.required,
    this.extensible,
    this.updatable,
    this.necessary,
    this.uiSchema,
  });
}
```

---

## 6. 迁移与兼容性

1.  **ACU 数据导入**:
    *   读取 ACU `sheet_3NoMc1wI` (Summary) -> 转换为 `MicroLog`。
    *   读取 ACU `sheet_PfzcX5v2` (Outline) -> 转换为 `MacroEvent`，保留 `AMxx` 引用关系。
2.  **旧版 Mnemosyne 升级**:
    *   将扁平的 History Chain 逐步迁移至 Narrative Chain 结构（可通过 Batch Pipeline 后台处理）。
