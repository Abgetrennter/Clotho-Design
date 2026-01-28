# Mnemosyne 数据结构实现提案

**版本**: 0.1.0
**日期**: 2026-01-04
**状态**: Draft
**目标**: 定义 Mnemosyne 引擎的核心数据结构、TypeScript 接口与 JSON Schema，融合 ACU 的最佳实践。

---

# Mnemosyne 数据结构实现提案 (Dart Version)

**版本**: 0.2.0 (Dart Revised)
**日期**: 2026-01-04
**状态**: Draft
**目标**: 定义 Mnemosyne 引擎的核心数据结构、Dart 类与 JSON Schema，融合 ACU 的最佳实践。

---

## 1. 核心类型定义 (Core Types)

### 1.1 VWD (Value with Description)

Mnemosyne 使用 "值+描述" 的元组结构来增强 LLM 对数值的理解。

#### Dart 实现
为了支持 JSON 序列化（`[value, description]`）和运行时类型安全，我们需要自定义 `Converter`。

```dart
import 'package:json_annotation/json_annotation.dart';

part 'vwd.g.dart';

/// VWD - Value With Description
/// 用于存储 RPG 状态中的数值及其语义描述。
/// 
/// Storage Format (JSON): [value, description]
@JsonSerializable()
class VWD<T> {
  T value;
  String description;

  VWD(this.value, this.description);

  /// 从 List<dynamic> 反序列化
  factory VWD.fromJson(List<dynamic> json) {
    if (json.length < 2) throw FormatException("Invalid VWD tuple");
    return VWD(json[0] as T, json[1] as String);
  }

  /// 序列化为 List<dynamic>
  List<dynamic> toJson() => [value, description];
  
  /// 便捷工厂方法
  static VWD<T> from<T>(dynamic data, [String desc = ""]) {
    if (data is VWD<T>) return data;
    if (data is List && data.length == 2) {
      return VWD(data[0] as T, data[1] as String);
    }
    return VWD(data as T, desc);
  }
}
```

### 1.2 OpLog (Operation Log)

基于 JSON Patch 标准，但针对 RPG 场景进行了扩展。

```dart
enum OpType { replace, add, remove, move, copy, test }

@JsonSerializable()
class OpLogEntry {
  final OpType op;
  final String path; // JSON Pointer, e.g., "/characters/alice/hp"
  final dynamic value;
  final String? from; // Only for move/copy
  final int timestamp;
  final String? source; // 触发源，e.g., "user_interaction", "world_event"

  OpLogEntry({
    required this.op,
    required this.path,
    this.value,
    this.from,
    required this.timestamp,
    this.source,
  });

  // factory OpLogEntry.fromJson(...)
  // Map<String, dynamic> toJson(...)
}

@JsonSerializable()
class StateDelta {
  @JsonKey(name: 'turn_id')
  final int turnId;
  final List<OpLogEntry> ops;

  StateDelta({required this.turnId, required this.ops});
}
```

---

## 2. 叙事链结构 (Narrative Chain Schema)

融合 ACU 的 "Summary Table" (Micro) 和 "Outline Table" (Macro) 概念。

### 2.1 Micro-Log (微观日志)

对应 ACU 的 **总结表 (Summary Table)**。记录每一轮对话的客观事实。

```dart
@JsonSerializable()
class MicroLog {
  final String id; // UUID
  
  @JsonKey(name: 'turn_id')
  final int turnId;
  
  final int timestamp;
  
  /// 核心内容: 高保真、零解读的客观事实
  final String summary;
  
  // 上下文快照
  final String location;
  
  @JsonKey(name: 'active_entities')
  final List<String> activeEntities; // 参与者 ID
  
  /// 索引引用 (对应 ACU AMxx)
  @JsonKey(name: 'ref_code')
  final String? refCode; 
  
  /// 原始数据源
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

### 2.2 Macro-Event (宏观大纲)

对应 ACU 的 **总体大纲 (Outline Table)**。对 Micro-Log 进行聚合，形成章节大纲。

```dart
@JsonSerializable()
class MacroEvent {
  final String id;
  final String title;     // 章节标题
  final String summary;   // 剧情梗概
  
  @JsonKey(name: 'start_turn')
  final int startTurn;
  
  @JsonKey(name: 'end_turn')
  final int endTurn;
  
  /// 子节点引用列表
  /// 存储 ref_code 以保持人类可读性，LLM 可直接生成此列表
  @JsonKey(name: 'child_refs')
  final List<String> childRefs; // ["AM1024", "AM1025", ...]
  
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

## 3. 事件链结构 (Event Chain Schema)

用于存储关键逻辑节点（Quest, Achievement, Milestones），强调 **显式叙事链接 (Explicit Narrative Linking)**。

```dart
enum EventType { quest, achievement, milestone, fact }
enum EventStatus { active, completed, failed, inactive }

@JsonSerializable()
class GlobalEvent {
  @JsonKey(name: 'event_id')
  final String eventId; 
  
  final EventType type;
  
  final String name;
  final String description;
  final EventStatus status;
  
  final int timestamp;
  
  @JsonKey(name: 'turn_id')
  final int turnId;
  
  /// 显式引用 (Explicit Narrative Linking)
  /// 支持多源溯源，解决 RAG "有大概无细节" 的痛点
  /// 格式: "type:id"
  @JsonKey(name: 'source_refs')
  final List<String> sourceRefs; // ["log:log_id_1", "msg:msg_id_2"]
  
  /// 扩展元数据
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

## 4. 状态树与元数据 ($meta)

### 4.1 Meta Schema ($meta)

所有状态节点均支持 `$meta` 字段，用于定义行为约束。

```dart
enum NecessityLevel { self, children, all }

@JsonSerializable()
class StateMeta {
  /// 结构约束: 子节点默认模板 (Deep Merge)
  final Map<String, dynamic>? template;
  
  /// 必须存在的 Key
  final List<String>? required;
  
  /// 是否允许 LLM 添加新 Key
  final bool? extensible;
  
  /// 权限控制: 只读锁
  final bool? updatable;
  
  /// 删除保护
  final NecessityLevel? necessary;
  
  /// VWD 集成: 当前节点的语义描述
  final String? description;
  
  /// 表现层 (Presentation)
  @JsonKey(name: 'ui_schema')
  final UISchema? uiSchema;

  StateMeta({
    this.template,
    this.required,
    this.extensible,
    this.updatable,
    this.necessary,
    this.description,
    this.uiSchema,
  });
}

@JsonSerializable()
class UISchema {
  final String? widget; // 'text', 'number', 'slider', 'table'
  final List<UIColumn>? columns;
  final bool? hidden;

  UISchema({this.widget, this.columns, this.hidden});
}

@JsonSerializable()
class UIColumn {
  final String key;
  final String header;
  final String? width;

  UIColumn({required this.key, required this.header, this.width});
}
```
