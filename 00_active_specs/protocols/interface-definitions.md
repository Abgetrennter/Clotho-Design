# Clotho 公共接口定义 (Clotho Public Interface Definitions)

**版本**: 1.0.0
**日期**: 2026-02-26
**状态**: Draft
**作者**: Clotho 架构团队
**关联文档**:
- [`dependency-injection.md`](../infrastructure/dependency-injection.md) - 依赖注入规范
- [`multi-package-architecture.md`](../infrastructure/multi-package-architecture.md) - 多包架构设计
- [`error-handling-and-cancellation.md`](../infrastructure/error-handling-and-cancellation.md) - 错误处理规范

---

## 1. 概述 (Overview)

本文档定义了 Clotho 项目的公共接口契约，解决架构审计中发现的 H-04 问题（API 接口契约未明确定义）。

### 1.1 设计原则

| 原则 | 说明 |
|------|------|
| **命名风格** | 抽象类无前缀（如 `TurnRepository`），实现类使用 `Impl` 后缀 |
| **接口粒度** | 仓储聚合（每个实体一个接口，包含所有 CRUD 操作） |
| **异常处理** | 抛出异常（使用专门的异常类型） |
| **异步模式** | `Future<T>` 用于一次性操作，`Stream<T>` 用于流式数据 |
| **文档规范** | 每个公共方法必须有完整的 dartdoc 注释 |

### 1.2 接口分层

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  (UI Components, Widgets, State Notifiers)                  │
├─────────────────────────────────────────────────────────────┤
│                    Domain Layer                              │
│  (UseCases, Entities) ← 本文档重点                           │
├─────────────────────────────────────────────────────────────┤
│                    Data Layer                                │
│  (Repositories, Data Sources) ← 本文档重点                   │
├─────────────────────────────────────────────────────────────┤
│                 Infrastructure Layer                         │
│  (Services, Platform Abstractions) ← 本文档重点              │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. 核心异常定义 (Core Exception Definitions)

### 2.1 异常层次结构

```dart
// clotho_core/lib/src/exception/clotho_exception.dart

/// Clotho 异常基类
/// 
/// 所有 Clotho 自定义异常都应继承此类。
abstract class ClothoException implements Exception {
  /// 错误码
  final String code;
  
  /// 人类可读的错误消息
  final String message;
  
  /// 技术详情（仅调试模式显示）
  final String? technicalDetails;
  
  /// 原始异常（如果有）
  final Object? originalError;
  
  /// 堆栈跟踪
  final StackTrace? stackTrace;
  
  const ClothoException({
    required this.code,
    required this.message,
    this.technicalDetails,
    this.originalError,
    this.stackTrace,
  });
  
  @override
  String toString() {
    if (technicalDetails != null) {
      return '$runtimeType($code): $message\nDetails: $technicalDetails';
    }
    return '$runtimeType($code): $message';
  }
}
```

### 2.2 基础设施层异常

```dart
// clotho_core/lib/src/exception/infrastructure_exception.dart

/// 基础设施层异常基类
abstract class InfrastructureException extends ClothoException {
  const InfrastructureException({
    required super.code,
    required super.message,
    super.technicalDetails,
    super.originalError,
    super.stackTrace,
  });
}

/// 文件系统异常
class FileSystemException extends InfrastructureException {
  final String? path;
  
  const FileSystemException({
    required String code,
    required String message,
    this.path,
    String? technicalDetails,
  }) : super(
          code: code,
          message: message,
          technicalDetails: technicalDetails,
        );
}

/// 文件未找到异常
class FileNotFoundException extends FileSystemException {
  const FileNotFoundException(String path)
      : super(
          code: 'FILE_NOT_FOUND',
          message: '文件未找到',
          path: path,
          technicalDetails: 'Path: $path',
        );
}

/// 权限拒绝异常
class PermissionDeniedException extends FileSystemException {
  const PermissionDeniedException(String path)
      : super(
          code: 'PERMISSION_DENIED',
          message: '权限拒绝',
          path: path,
          technicalDetails: 'Path: $path',
        );
}

/// 数据库异常
class DatabaseException extends InfrastructureException {
  const DatabaseException({
    required super.code,
    required super.message,
    super.technicalDetails,
    super.originalError,
  });
}

/// 网络异常
class NetworkException extends InfrastructureException {
  const NetworkException({
    required super.code,
    required super.message,
    super.technicalDetails,
    super.originalError,
  });
}
```

### 2.3 领域层异常

```dart
// clotho_core/lib/src/exception/domain_exception.dart

/// 领域层异常基类
abstract class DomainException extends ClothoException {
  const DomainException({
    required super.code,
    required super.message,
    super.technicalDetails,
    super.originalError,
    super.stackTrace,
  });
}

/// 实体未找到异常
abstract class EntityNotFoundException extends DomainException {
  final String entityId;
  final String entityType;
  
  const EntityNotFoundException({
    required this.entityId,
    required this.entityType,
    String? code,
  }) : super(
          code: code ?? 'ENTITY_NOT_FOUND',
          message: '$entityType 未找到',
          technicalDetails: 'Entity: $entityType, ID: $entityId',
        );
}

/// Turn 未找到异常
class TurnNotFoundException extends EntityNotFoundException {
  const TurnNotFoundException(String turnId)
      : super(
          entityId: turnId,
          entityType: 'Turn',
          code: 'TURN_NOT_FOUND',
        );
}

/// Session 未找到异常
class SessionNotFoundException extends EntityNotFoundException {
  const SessionNotFoundException(String sessionId)
      : super(
          entityId: sessionId,
          entityType: 'Session',
          code: 'SESSION_NOT_FOUND',
        );
}

/// 验证异常
class ValidationException extends DomainException {
  final Map<String, String> fieldErrors;
  
  const ValidationException({
    required String message,
    this.fieldErrors = const {},
  }) : super(
          code: 'VALIDATION_ERROR',
          message: message,
        );
}

/// 业务规则异常
class BusinessRuleException extends DomainException {
  const BusinessRuleException(String message)
      : super(
          code: 'BUSINESS_RULE_VIOLATION',
          message: message,
        );
}
```

### 2.4 编排层异常

```dart
// clotho_core/lib/src/exception/orchestration_exception.dart

/// 编排层异常基类
abstract class OrchestrationException extends ClothoException {
  const OrchestrationException({
    required super.code,
    required super.message,
    super.technicalDetails,
    super.originalError,
    super.stackTrace,
  });
}

/// 生成超时异常
class GenerationTimeoutException extends OrchestrationException {
  const GenerationTimeoutException({
    String? technicalDetails,
  }) : super(
          code: 'GENERATION_TIMEOUT',
          message: '生成超时',
          technicalDetails: technicalDetails,
        );
}

/// 生成取消异常
class GenerationCanceledException extends OrchestrationException {
  const GenerationCanceledException()
      : super(
          code: 'GENERATION_CANCELED',
          message: '生成已取消',
        );
}

/// Pipeline 异常
class PipelineException extends OrchestrationException {
  final String? pluginId;
  
  const PipelineException({
    required super.code,
    required super.message,
    this.pluginId,
    super.technicalDetails,
    super.originalError,
  });
}

/// Pipeline 中止异常
class PipelineAbortedException extends PipelineException {
  const PipelineAbortedException(String reason)
      : super(
          code: 'PIPELINE_ABORTED',
          message: 'Pipeline 已中止：$reason',
        );
}
```

### 2.5 智能服务层异常

```dart
// clotho_core/lib/src/exception/muse_exception.dart

/// 智能服务层异常基类
abstract class MuseException extends ClothoException {
  const MuseException({
    required super.code,
    required super.message,
    super.technicalDetails,
    super.originalError,
    super.stackTrace,
  });
}

/// Provider 过载异常
class ProviderOverloadException extends MuseException {
  final Duration? retryAfter;
  
  const ProviderOverloadException({
    this.retryAfter,
    String? technicalDetails,
  }) : super(
          code: 'PROVIDER_OVERLOAD',
          message: 'Provider 过载',
          technicalDetails: technicalDetails,
        );
}

/// 上下文超限异常
class ContextLimitExceededException extends MuseException {
  final int currentTokens;
  final int maxTokens;
  
  const ContextLimitExceededException({
    required this.currentTokens,
    required this.maxTokens,
    String? technicalDetails,
  }) : super(
          code: 'CONTEXT_LIMIT_EXCEEDED',
          message: '上下文超出限制 ($currentTokens > $maxTokens)',
          technicalDetails: technicalDetails,
        );
}

/// 安全过滤触发异常
class SafetyFilterException extends MuseException {
  final String? reason;
  
  const SafetyFilterException({
    this.reason,
    String? technicalDetails,
  }) : super(
          code: 'SAFETY_FILTER_TRIGGERED',
          message: '安全过滤已触发',
          technicalDetails: technicalDetails ?? (reason != null ? 'Reason: $reason' : null),
        );
}

/// 认证异常
class AuthenticationException extends MuseException {
  const AuthenticationException(String message)
      : super(
          code: 'AUTHENTICATION_ERROR',
          message: message,
        );
}

/// 配额耗尽异常
class QuotaExceededException extends MuseException {
  const QuotaExceededException()
      : super(
          code: 'QUOTA_EXCEEDED',
          message: '配额已耗尽',
        );
}
```

---

## 3. Repository 层接口 (Repository Layer Interfaces)

### 3.1 TurnRepository

```dart
// clotho_domain/lib/src/repository/turn_repository.dart

import '../entity/turn.dart';
import '../exception/domain_exception.dart';

/// Turn 实体的仓储接口
/// 
/// 定义了对 Turn 实体的所有数据访问操作。
/// 
/// 实现应位于 data 层（如 `clotho_data` 包）。
/// 
/// 示例:
/// ```dart
/// final turn = await repository.getById(turnId);
/// final created = await repository.create(newTurn);
/// await repository.update(updatedTurn);
/// await repository.delete(turnId);
/// ```
abstract class TurnRepository {
  /// 根据 ID 获取 Turn
  /// 
  /// 如果 Turn 不存在，抛出 [TurnNotFoundException]。
  /// 
  /// 参数:
  /// - [id]: Turn 的唯一标识符
  /// 
  /// 返回:
  /// 匹配 ID 的 [Turn] 实体
  /// 
  /// 异常:
  /// - [TurnNotFoundException]: 当 Turn 不存在时
  Future<Turn> getById(String id);
  
  /// 创建新的 Turn
  /// 
  /// 参数:
  /// - [turn]: 要创建的 Turn 实体
  /// 
  /// 返回:
  /// 创建后的 Turn（包含生成的 ID）
  /// 
  /// 异常:
  /// - [ValidationException]: 当 Turn 数据无效时
  Future<Turn> create(Turn turn);
  
  /// 更新 Turn
  /// 
  /// 参数:
  /// - [turn]: 要更新的 Turn 实体
  /// 
  /// 异常:
  /// - [TurnNotFoundException]: 当 Turn 不存在时
  /// - [ValidationException]: 当 Turn 数据无效时
  Future<void> update(Turn turn);
  
  /// 删除 Turn
  /// 
  /// 参数:
  /// - [id]: 要删除的 Turn 的 ID
  /// 
  /// 注意:
  /// 如果 Turn 不存在，不执行任何操作（静默成功）。
  Future<void> delete(String id);
  
  /// 获取会话的所有 Turns
  /// 
  /// 参数:
  /// - [sessionId]: 会话的唯一标识符
  /// 
  /// 返回:
  /// 按 [Turn.index] 升序排序的 Turn 列表
  Future<List<Turn>> getBySession(String sessionId);
  
  /// 获取会话的最后一个 Turn
  /// 
  /// 参数:
  /// - [sessionId]: 会话的唯一标识符
  /// 
  /// 返回:
  /// 会话的最后一个 Turn，如果会话为空则返回 `null`
  Future<Turn?> getLastTurn(String sessionId);
}
```

### 3.2 SessionRepository

```dart
// clotho_domain/lib/src/repository/session_repository.dart

import '../entity/session.dart';
import '../exception/domain_exception.dart';

/// Session 实体的仓储接口
/// 
/// 定义了对 Session 实体的所有数据访问操作。
abstract class SessionRepository {
  /// 根据 ID 获取 Session
  /// 
  /// 如果 Session 不存在，抛出 [SessionNotFoundException]。
  Future<Session> getById(String id);
  
  /// 创建新的 Session
  Future<Session> create(Session session);
  
  /// 更新 Session
  /// 
  /// 异常:
  /// - [SessionNotFoundException]: 当 Session 不存在时
  Future<void> update(Session session);
  
  /// 删除 Session 及其所有 Turns
  /// 
  /// 注意:
  /// 如果 Session 不存在，不执行任何操作。
  Future<void> delete(String id);
  
  /// 获取所有 Sessions
  /// 
  /// 返回:
  /// 按 [Session.updatedAt] 降序排序的 Session 列表
  Future<List<Session>> getAll();
  
  /// 获取最近的 Sessions
  /// 
  /// 参数:
  /// - [limit]: 返回的最大数量
  Future<List<Session>> getRecent({int limit = 10});
}
```

### 3.3 LoreRepository

```dart
// clotho_domain/lib/src/repository/lore_repository.dart

import '../entity/lorebook_entry.dart';

/// Lorebook 实体的仓储接口
/// 
/// 定义了对 Lorebook 条目的所有数据访问操作。
abstract class LoreRepository {
  /// 根据 ID 获取 Lorebook 条目
  Future<LorebookEntry> getById(String id);
  
  /// 创建新的 Lorebook 条目
  Future<LorebookEntry> create(LorebookEntry entry);
  
  /// 更新 Lorebook 条目
  Future<void> update(LorebookEntry entry);
  
  /// 删除 Lorebook 条目
  Future<void> delete(String id);
  
  /// 获取所有启用的 Lorebook 条目
  Future<List<LorebookEntry>> getActive();
  
  /// 根据关键词搜索 Lorebook 条目
  /// 
  /// 参数:
  /// - [keys]: 触发关键词列表
  /// 
  /// 返回:
  /// 匹配关键词的 Lorebook 条目列表
  Future<List<LorebookEntry>> searchByKeys(List<String> keys);
  
  /// 执行向量相似度搜索
  /// 
  /// 参数:
  /// - [query]: 查询文本
  /// - [topK]: 返回的最大数量
  /// - [threshold]: 相似度阈值
  Future<List<LorebookEntry>> vectorSearch({
    required String query,
    int topK = 5,
    double threshold = 0.7,
  });
}
```

---

## 4. UseCase 层接口 (UseCase Layer Interfaces)

### 4.1 GenerateResponseUseCase

```dart
// clotho_domain/lib/src/use_case/generate_response_use_case.dart

import 'dart:async';
import '../entity/turn.dart';
import '../entity/message.dart';
import '../exception/orchestration_exception.dart';
import '../exception/muse_exception.dart';

/// 生成响应用例的输入参数
class GenerateResponseParams {
  /// 会话 ID
  final String sessionId;
  
  /// 回合 ID
  final String turnId;
  
  /// 用户输入
  final String userInput;
  
  /// 生成选项
  final GenerationOptions? options;
  
  const GenerateResponseParams({
    required this.sessionId,
    required this.turnId,
    required this.userInput,
    this.options,
  });
}

/// 生成响应选项
class GenerationOptions {
  /// 模板 ID（可选，使用默认模板）
  final String? templateId;
  
  /// 超时时间
  final Duration? timeout;
  
  /// 是否流式输出
  final bool streaming;
  
  const GenerationOptions({
    this.templateId,
    this.timeout,
    this.streaming = true,
  });
}

/// 生成响应用例的输出结果
class GenerateResponseResult {
  /// 消息 ID
  final String messageId;
  
  /// 生成的内容
  final String content;
  
  /// 状态变更
  final Map<String, dynamic> stateChanges;
  
  /// 触发的事件
  final List<String> events;
  
  /// 思维链（可选）
  final String? thought;
  
  const GenerateResponseResult({
    required this.messageId,
    required this.content,
    required this.stateChanges,
    required this.events,
    this.thought,
  });
}

/// 生成内容块（用于流式输出）
class GenerationChunk {
  /// 内容片段
  final String content;
  
  /// 是否完成
  final bool isComplete;
  
  /// 元数据（可选）
  final Map<String, dynamic>? metadata;
  
  const GenerationChunk({
    required this.content,
    this.isComplete = false,
    this.metadata,
  });
}

/// 生成响应用例接口
/// 
/// 这是 Jacquard 编排层与 Muse 智能服务层之间的接口契约。
/// 
/// 示例:
/// ```dart
/// final result = await useCase.execute(GenerateResponseParams(
///   sessionId: sessionId,
///   turnId: turnId,
///   userInput: userInput,
/// ));
/// ```
abstract class GenerateResponseUseCase {
  /// 执行生成响应用例
  /// 
  /// 参数:
  /// - [params]: 生成参数
  /// 
  /// 返回:
  /// [GenerateResponseResult] 包含生成的响应和状态变更
  /// 
  /// 异常:
  /// - [GenerationTimeoutException]: 生成超时
  /// - [GenerationCanceledException]: 生成被取消
  /// - [ProviderOverloadException]: Provider 过载
  /// - [SafetyFilterException]: 安全过滤触发
  Future<GenerateResponseResult> execute(GenerateResponseParams params);
  
  /// 流式执行生成响应用例
  /// 
  /// 参数:
  /// - [params]: 生成参数
  /// 
  /// 返回:
  /// 一个 [Stream]，逐步 emit [GenerationChunk]
  /// 
  /// 异常:
  /// - 同 [execute] 方法
  Stream<GenerationChunk> executeStreaming(GenerateResponseParams params);
  
  /// 取消正在进行的生成
  /// 
  /// 参数:
  /// - [taskId]: 生成任务的 ID
  Future<void> cancel(String taskId);
}
```

### 4.2 CreateTurnUseCase

```dart
// clotho_domain/lib/src/use_case/create_turn_use_case.dart

import '../entity/turn.dart';
import '../entity/message.dart';
import '../exception/domain_exception.dart';

/// 创建回合用例的输入参数
class CreateTurnParams {
  /// 会话 ID
  final String sessionId;
  
  /// 用户消息
  final Message userMessage;
  
  const CreateTurnParams({
    required this.sessionId,
    required this.userMessage,
  });
}

/// 创建回合用例的输出结果
class CreateTurnResult {
  /// 创建的 Turn
  final Turn turn;
  
  /// 用户消息
  final Message userMessage;
  
  const CreateTurnResult({
    required this.turn,
    required this.userMessage,
  });
}

/// 创建回合用例接口
abstract class CreateTurnUseCase {
  /// 执行创建回合用例
  /// 
  /// 参数:
  /// - [params]: 创建参数
  /// 
  /// 返回:
  /// [CreateTurnResult] 包含创建的 Turn 和用户消息
  /// 
  /// 异常:
  /// - [SessionNotFoundException]: 当会话不存在时
  /// - [ValidationException]: 当参数无效时
  Future<CreateTurnResult> execute(CreateTurnParams params);
}
```

### 4.3 LoadSessionUseCase

```dart
// clotho_domain/lib/src/use_case/load_session_use_case.dart

import '../entity/session.dart';
import '../entity/turn.dart';
import '../exception/domain_exception.dart';

/// 加载会话用例的输入参数
class LoadSessionParams {
  /// 会话 ID
  final String sessionId;
  
  /// 是否加载历史 Turns
  final bool loadHistory;
  
  /// 加载的历史记录数量（0 表示全部）
  final int historyLimit;
  
  const LoadSessionParams({
    required this.sessionId,
    this.loadHistory = true,
    this.historyLimit = 0,
  });
}

/// 加载会话用例的输出结果
class LoadSessionResult {
  /// 会话实体
  final Session session;
  
  /// 历史 Turns（如果请求）
  final List<Turn>? history;
  
  const LoadSessionResult({
    required this.session,
    this.history,
  });
}

/// 加载会话用例接口
abstract class LoadSessionUseCase {
  /// 执行加载会话用例
  /// 
  /// 参数:
  /// - [params]: 加载参数
  /// 
  /// 返回:
  /// [LoadSessionResult] 包含会话实体和历史记录
  /// 
  /// 异常:
  /// - [SessionNotFoundException]: 当会话不存在时
  Future<LoadSessionResult> execute(LoadSessionParams params);
}
```

---

## 5. Service 层接口 (Service Layer Interfaces)

### 5.1 IClothoNexus

```dart
// clotho_core/lib/src/service/clotho_nexus.dart

import 'dart:async';

/// Clotho 事件基类
abstract class ClothoEvent {
  /// 事件 ID
  final String id;
  
  /// 时间戳（毫秒）
  final int timestamp;
  
  /// 元数据
  final Map<String, dynamic>? metadata;
  
  ClothoEvent({
    String? id,
    Map<String, dynamic>? metadata,
  }) : id = id ?? _generateId(),
       timestamp = DateTime.now().millisecondsSinceEpoch,
       metadata = metadata;
  
  static String _generateId() => 
      'evt_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
}

/// ClothoNexus 事件总线接口
/// 
/// 这是系统内部组件间异步通信的核心接口。
/// 
/// 示例:
/// ```dart
/// // 发布事件
/// nexus.publish(MessageEvent(
///   messageId: 'msg_123',
///   content: 'Hello',
/// ));
/// 
/// // 订阅事件
/// nexus.on<MessageEvent>().listen((event) {
///   print('New message: ${event.content}');
/// });
/// ```
abstract class IClothoNexus {
  /// 发布一个事件
  /// 
  /// 所有订阅该事件类型的监听器都会收到通知。
  /// 
  /// 参数:
  /// - [event]: 要发布的事件
  void publish(ClothoEvent event);
  
  /// 订阅特定类型的事件流
  /// 
  /// 参数:
  /// - [T]: 事件类型
  /// 
  /// 返回:
  /// 一个 [Stream]，emit 所有指定类型的事件
  Stream<T> on<T extends ClothoEvent>();
  
  /// 订阅所有事件（用于日志或调试）
  Stream<ClothoEvent> get allEvents;
  
  /// 释放资源
  void dispose();
}
```

### 5.2 ILogger

```dart
// clotho_core/lib/src/service/logger_service.dart

/// 日志级别
enum LogLevel {
  trace,
  debug,
  info,
  warning,
  error,
  fatal,
}

/// 日志服务接口
/// 
/// 提供统一的日志记录能力。
/// 
/// 示例:
/// ```dart
/// logger.info('User logged in', category: 'Auth');
/// logger.error('Failed to load data', error: e, stack: stack);
/// ```
abstract class ILogger {
  /// 记录 Trace 级别日志
  void trace(String message, {String? category, Map<String, Object>? context});
  
  /// 记录 Debug 级别日志
  void debug(String message, {String? category, Map<String, Object>? context});
  
  /// 记录 Info 级别日志
  void info(String message, {String? category, Map<String, Object>? context});
  
  /// 记录 Warning 级别日志
  void warning(String message, {
    Object? error,
    StackTrace? stack,
    String? category,
  });
  
  /// 记录 Error 级别日志
  void error(String message, {
    Object? error,
    StackTrace? stack,
    String? category,
  });
  
  /// 记录 Fatal 级别日志
  void fatal(String message, {
    Object? error,
    StackTrace? stack,
    String? category,
  });
}
```

### 5.3 IFileSystemService

```dart
// clotho_core/lib/src/service/file_system_service.dart

import 'dart:async';
import 'dart:typed_data';

/// 目录类型枚举
enum DirectoryType {
  /// 应用核心数据
  appData,
  
  /// 临时缓存
  cache,
  
  /// 会话级临时文件
  temp,
  
  /// 用户可见文档
  documents,
}

/// 文件系统服务接口
/// 
/// 提供跨平台的文件操作抽象。
abstract class FileSystemService {
  /// 初始化服务
  Future<void> initialize();
  
  /// 获取指定类型的根目录物理路径
  Future<String> getDirectoryPath(DirectoryType type);
  
  /// 将语义化路径解析为物理路径
  /// 
  /// 输入示例：`app_data://library/abc/manifest.yaml`
  /// 输出示例：`C:\Users\...\Clotho\library\abc\manifest.yaml`
  Future<String> resolvePath(String uri);
  
  /// 检查文件或目录是否存在
  Future<bool> exists(String uri);
  
  /// 读取文本文件
  Future<String> readString(String uri);
  
  /// 写入文本文件
  Future<void> writeString(String uri, String content, {bool append = false});
  
  /// 读取二进制文件
  Future<List<int>> readBytes(String uri);
  
  /// 写入二进制文件
  Future<void> writeBytes(String uri, List<int> bytes);
  
  /// 删除文件
  Future<void> deleteFile(String uri);
  
  /// 递归创建目录
  Future<void> createDirectory(String uri);
  
  /// 列出目录内容
  Future<List<String>> listFiles(String uri, {bool recursive = false});
  
  /// 删除目录及其内容
  Future<void> deleteDirectory(String uri);
  
  /// 打开文件读取流
  Stream<List<int>> openReadStream(String uri);
  
  /// 打开文件写入流
  Sink<List<int>> openWriteStream(String uri);
}
```

### 5.5 Presentation ↔ Jacquard 接口

**设计原则**: UI 组件严禁直接访问 Mnemosyne 状态树。所有数据访问必须通过本章节定义的接口进行代理。

```dart
// clotho_core/lib/src/service/jacquard_ui_adapter.dart

import 'dart:async';

/// UI Schema 请求参数
class UISchemaRequest {
  /// 状态树路径 (如：character.inventory)
  final String path;
  
  /// 是否包含元数据
  final bool includeMetadata;
  
  const UISchemaRequest({
    required this.path,
    this.includeMetadata = true,
  });
}

/// UI Schema 响应结果
class UISchemaResponse {
  /// Schema 类型 (table, card, list, tree)
  final String type;
  
  /// Schema 配置
  final Map<String, dynamic> config;
  
  /// 数据投影
  final dynamic data;
  
  /// 访问控制信息
  final ACLInfo? aclInfo;
  
  const UISchemaResponse({
    required this.type,
    required this.config,
    required this.data,
    this.aclInfo,
  });
}

/// 访问控制信息
class ACLInfo {
  /// 访问级别 (Global, Shared, Private)
  final String accessLevel;
  
  /// 是否可写
  final bool isWritable;
  
  const ACLInfo({
    required this.accessLevel,
    required this.isWritable,
  });
}

/// 数据投影请求参数
class DataProjectionRequest {
  /// 状态树路径
  final String path;
  
  /// 深度限制 (0 表示无限制)
  final int maxDepth;
  
  /// 是否包含子节点
  final bool includeChildren;
  
  const DataProjectionRequest({
    required this.path,
    this.maxDepth = 0,
    this.includeChildren = true,
  });
}

/// 数据投影响应结果
class DataProjectionResponse {
  /// 路径
  final String path;
  
  /// 数据类型
  final String dataType;
  
  /// 数据值
  final dynamic value;
  
  /// 子节点 (如果请求)
  final List<DataProjectionResponse>? children;
  
  const DataProjectionResponse({
    required this.path,
    required this.dataType,
    required this.value,
    this.children,
  });
}

/// Intent 提交请求参数
class IntentSubmitRequest {
  /// Intent 类型
  final String type;
  
  /// Intent 数据
  final Map<String, dynamic> payload;
  
  /// 源组件 ID
  final String? sourceComponentId;
  
  const IntentSubmitRequest({
    required this.type,
    required this.payload,
    this.sourceComponentId,
  });
}

/// Intent 提交响应结果
class IntentSubmitResponse {
  /// 是否成功
  final bool success;
  
  /// 结果消息
  final String? message;
  
  /// 状态变更 (如果适用)
  final Map<String, dynamic>? stateChanges;
  
  const IntentSubmitResponse({
    required this.success,
    this.message,
    this.stateChanges,
  });
}

/// UI 与 Jacquard 编排层的接口契约
///
/// 这是 Presentation 层与 Jacquard 编排层之间的唯一数据访问通道。
/// UI 组件必须通过此接口访问 Mnemosyne 状态树，严禁直接访问。
///
/// ## 使用示例:
///
/// ### Inspector 组件获取 UI Schema
/// ```dart
/// class _InspectorState extends State<Inspector> {
///   final JacquardUIAdapter _adapter = Jacquard.instance.uiAdapter;
///
///   Future<void> _onNodeSelected(String path) async {
///     // ✅ 正确：通过 Jacquard 代理访问
///     final schema = await _adapter.requestUISchema(
///       UISchemaRequest(path: path),
///     );
///     _render(schema);
///   }
/// }
/// ```
///
/// ### InputDraftController 提交 Intent
/// ```dart
/// class InputDraftController extends ChangeNotifier {
///   final JacquardUIAdapter _adapter = Jacquard.instance.uiAdapter;
///
///   Future<void> submitIntent(String type, Map<String, dynamic> payload) async {
///     final response = await _adapter.submitIntent(
///       IntentSubmitRequest(
///         type: type,
///         payload: payload,
///         sourceComponentId: 'InputDraftController',
///       ),
///     );
///
///     if (response.success) {
///       _clear();
///     }
///   }
/// }
/// ```
///
/// ## 错误示例:
///
/// ```dart
/// // ❌ 错误：UI 直接访问 Mnemosyne
/// class Inspector extends StatelessWidget {
///   void _onNodeSelected(String path) {
///     // 错误：直接读取 Mnemosyne 状态树
///     final schema = Mnemosyne.getState(path).meta.uiSchema;
///     _render(schema);
///   }
/// }
/// ```
abstract class JacquardUIAdapter {
  /// 请求 UI Schema
  ///
  /// 参数:
  /// - [request]: UI Schema 请求参数
  ///
  /// 返回:
  /// [UISchemaResponse] 包含 Schema 定义和数据投影
  ///
  /// 异常:
  /// - [PathNotFoundException]: 当路径不存在时
  /// - [AccessDeniedException]: 当访问被拒绝时
  Future<UISchemaResponse> requestUISchema(UISchemaRequest request);
  
  /// 请求数据投影
  ///
  /// 参数:
  /// - [request]: 数据投影请求参数
  ///
  /// 返回:
  /// [DataProjectionResponse] 包含数据投影
  ///
  /// 异常:
  /// - [PathNotFoundException]: 当路径不存在时
  /// - [AccessDeniedException]: 当访问被拒绝时
  Future<DataProjectionResponse> requestDataProjection(DataProjectionRequest request);
  
  /// 提交 Intent
  ///
  /// 参数:
  /// - [request]: Intent 提交请求参数
  ///
  /// 返回:
  /// [IntentSubmitResponse] 包含提交结果
  ///
  /// 异常:
  /// - [IntentValidationException]: 当 Intent 格式无效时
  /// - [IntentProcessingException]: 当 Intent 处理失败时
  Future<IntentSubmitResponse> submitIntent(IntentSubmitRequest request);
  
  /// 订阅状态同步事件
  ///
  /// 返回:
  /// 一个 [Stream]，emit 状态快照
  Stream<Map<String, dynamic>> onStateSync();
  
  /// 释放资源
  void dispose();
}
```

---

## 6. 事件定义 (Event Definitions)

### 6.1 系统事件

```dart
// clotho_core/lib/src/event/system_event.dart

/// 应用生命周期事件类型
enum AppLifecycleState {
  started,
  resumed,
  paused,
  stopped,
}

/// 系统事件基类
abstract class SystemEvent extends ClothoEvent {
  const SystemEvent({super.id, super.metadata});
}

/// 应用生命周期事件
class AppLifecycleEvent extends SystemEvent {
  final AppLifecycleState state;
  
  const AppLifecycleEvent({
    required this.state,
    super.id,
    super.metadata,
  });
}
```

### 6.2 会话事件

```dart
// clotho_core/lib/src/event/session_event.dart

/// 会话操作类型
enum SessionAction {
  created,
  loaded,
  saved,
  deleted,
}

/// 会话事件
class SessionEvent extends SystemEvent {
  final String sessionId;
  final SessionAction action;
  
  const SessionEvent({
    required this.sessionId,
    required this.action,
    super.id,
    super.metadata,
  });
}
```

### 6.3 消息事件

```dart
// clotho_core/lib/src/event/message_event.dart

/// 消息类型
enum MessageType {
  user,
  assistant,
  system,
  thought,
}

/// 消息事件
class MessageEvent extends SystemEvent {
  final String messageId;
  final String turnId;
  final MessageType type;
  final String content;
  
  const MessageEvent({
    required this.messageId,
    required this.turnId,
    required this.type,
    required this.content,
    super.id,
    super.metadata,
  });
}
```

### 6.4 错误事件

```dart
// clotho_core/lib/src/event/error_event.dart

/// 错误严重性
enum ErrorSeverity {
  info,
  warning,
  error,
  fatal,
}

/// 系统错误事件
class SystemErrorEvent extends SystemEvent {
  final String errorCode;
  final String message;
  final String? technicalDetails;
  final ErrorSeverity severity;
  final bool userActionable;
  
  const SystemErrorEvent({
    required this.errorCode,
    required this.message,
    this.technicalDetails,
    required this.severity,
    this.userActionable = false,
    super.id,
    super.metadata,
  });
}
```

---

## 7. 实体定义 (Entity Definitions)

### 7.1 Turn 实体

```dart
// clotho_domain/lib/src/entity/turn.dart

/// Turn 实体
/// 
/// 代表一次完整的用户-AI 交互回合。
class Turn {
  /// Turn ID
  final String id;
  
  /// 会话 ID
  final String sessionId;
  
  /// 回合索引（全局递增）
  final int index;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 消息列表
  final List<Message> messages;
  
  /// 状态快照（可选）
  final Map<String, dynamic>? stateSnapshot;
  
  /// 回合摘要（用于 RAG）
  final String? summary;
  
  const Turn({
    required this.id,
    required this.sessionId,
    required this.index,
    required this.createdAt,
    required this.messages,
    this.stateSnapshot,
    this.summary,
  });
  
  /// 创建空 Turn
  factory Turn.empty() {
    return Turn(
      id: '',
      sessionId: '',
      index: 0,
      createdAt: DateTime.now(),
      messages: [],
    );
  }
  
  Turn copyWith({
    String? id,
    String? sessionId,
    int? index,
    DateTime? createdAt,
    List<Message>? messages,
    Map<String, dynamic>? stateSnapshot,
    String? summary,
  }) {
    return Turn(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      index: index ?? this.index,
      createdAt: createdAt ?? this.createdAt,
      messages: messages ?? this.messages,
      stateSnapshot: stateSnapshot ?? this.stateSnapshot,
      summary: summary ?? this.summary,
    );
  }
}
```

### 7.2 Message 实体

```dart
// clotho_domain/lib/src/entity/message.dart

/// 消息角色
enum MessageRole {
  user,
  assistant,
  system,
  thought,
}

/// 消息类型
enum MessageType {
  text,
  thought,
  command,
}

/// Message 实体
class Message {
  /// 消息 ID
  final String id;
  
  /// 所属 Turn ID
  final String turnId;
  
  /// 角色
  final MessageRole role;
  
  /// 内容
  final String content;
  
  /// 类型
  final MessageType type;
  
  /// 是否激活（软删除支持）
  final bool isActive;
  
  /// 元数据
  final Map<String, dynamic> meta;
  
  const Message({
    required this.id,
    required this.turnId,
    required this.role,
    required this.content,
    this.type = MessageType.text,
    this.isActive = true,
    this.meta = const {},
  });
  
  Message copyWith({
    String? id,
    String? turnId,
    MessageRole? role,
    String? content,
    MessageType? type,
    bool? isActive,
    Map<String, dynamic>? meta,
  }) {
    return Message(
      id: id ?? this.id,
      turnId: turnId ?? this.turnId,
      role: role ?? this.role,
      content: content ?? this.content,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      meta: meta ?? this.meta,
    );
  }
}
```

### 7.3 Session 实体

```dart
// clotho_domain/lib/src/entity/session.dart

/// Session 实体
class Session {
  /// Session ID
  final String id;
  
  /// 标题
  final String title;
  
  /// 活跃的角色 ID
  final String activeCharacterId;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 最后访问时间
  final DateTime updatedAt;
  
  /// 元数据
  final Map<String, dynamic> meta;
  
  const Session({
    required this.id,
    required this.title,
    required this.activeCharacterId,
    required this.createdAt,
    required this.updatedAt,
    this.meta = const {},
  });
  
  Session copyWith({
    String? id,
    String? title,
    String? activeCharacterId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? meta,
  }) {
    return Session(
      id: id ?? this.id,
      title: title ?? this.title,
      activeCharacterId: activeCharacterId ?? this.activeCharacterId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      meta: meta ?? this.meta,
    );
  }
}
```

---

## 8. 接口测试规范 (Interface Testing Specification)

### 8.1 契约测试模板

```dart
// clotho_domain/test/repository/turn_repository_contract_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:clotho_domain/clotho_domain.dart';

/// TurnRepository 的契约测试
/// 
/// 这些测试适用于任何 TurnRepository 的实现。
abstract class TurnRepositoryContractTest {
  /// 创建测试用的 Repository 实例
  TurnRepository createRepository();
  
  /// 销毁 Repository 实例
  void destroyRepository(TurnRepository repository);
  
  /// 运行所有契约测试
  void runTests() {
    group('TurnRepository Contract Tests', () {
      late TurnRepository repository;
      late Turn testTurn;
      
      setUp(() async {
        repository = createRepository();
        testTurn = Turn.empty();
      });
      
      tearDown(() {
        destroyRepository(repository);
      });
      
      test('getById should throw TurnNotFoundException when not found', () async {
        expect(
          () => repository.getById('non-existent-id'),
          throwsA(isA<TurnNotFoundException>()),
        );
      });
      
      test('create should return Turn with generated ID', () async {
        final result = await repository.create(testTurn);
        
        expect(result.id, isNotEmpty);
        expect(result.id, isNot(equals(testTurn.id)));
      });
      
      test('update should throw when turn not found', () async {
        final nonExistentTurn = testTurn.copyWith(id: 'non-existent-id');
        
        expect(
          () => repository.update(nonExistentTurn),
          throwsA(isA<TurnNotFoundException>()),
        );
      });
      
      test('delete should not throw when turn not found', () async {
        expect(
          () => repository.delete('non-existent-id'),
          returnsNormally,
        );
      });
      
      test('getBySession should return empty list when no turns', () async {
        final result = await repository.getBySession('session-id');
        
        expect(result, isEmpty);
      });
    });
  }
}
```

---

## 9. 变更历史 (Changelog)

| 版本 | 日期 | 变更内容 | 作者 |
|------|------|----------|------|
| 1.0.0 | 2026-02-26 | 初始版本，定义核心接口契约 | Clotho 架构团队 |

---

**最后更新**: 2026-02-26  
**维护者**: Clotho 架构团队
