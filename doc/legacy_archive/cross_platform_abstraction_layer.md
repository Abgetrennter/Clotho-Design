# 跨平台抽象层技术设计文档 (Technical Design Document)

**项目名称**: Neuropean  
**版本**: 1.0.0  
**状态**: 拟定中  
**作者**: 资深Flutter架构师 (Meow Mode)  
**日期**: 2025-12-18

---

## 1. 架构设计综述 (Architecture Overview)

为了实现 `Neuropean` 项目在 Android 和 Windows 端的长期稳定性与可维护性，本抽象层设计严格遵循 **依赖倒置原则 (Dependency Inversion Principle, DIP)**。

### 1.1 核心设计理念
传统的架构往往是上层 UI 直接调用底层原生 API，这会导致 UI 代码与特定平台（如 Android SDK 或 Win32 API）强耦合。
本设计采用 **Clean Architecture (整洁架构)** 结合 **Repository Pattern (仓储模式)**，将依赖关系反转：

*   **UI 层 (Presentation Layer)**：只依赖于纯 Dart 编写的抽象接口（Domain Layer）。
*   **原生实现层 (Data Layer)**：依赖并实现上述抽象接口，负责具体的平台调用。

### 1.2 架构分层图解

```mermaid
graph TD
    UI[Flutter UI / Presentation] -->|依赖| Domain[Domain Layer (纯Dart抽象接口)]
    Data[Data Layer (Repository实现)] -->|实现| Domain
    Data -->|调用| Channel[MethodChannel / FFI]
    Channel -->|通信| Native[Android (Kotlin) / Windows (C++)]
```

### 1.3 解耦机制
*   **编译期解耦**：UI 层代码中不包含任何 `dart:io` (Platform check) 或 `package:flutter/services` (MethodChannel) 的直接引用。
*   **运行时注入**：使用依赖注入（DI）容器（如 `get_it`），根据当前运行平台动态注入对应的 Repository 实现类（例如 `AndroidCharacterRepository` 或 `WindowsCharacterRepository`）。

---

## 2. 抽象接口定义规范 (Abstract Interface Definition)

所有跨端功能必须首先在 Domain 层定义接口契约。

### 2.1 接口契约标准
接口定义必须纯净，不依赖任何平台特定库。

*   **命名规范**：以 `I` 开头或以 `Repository/Service` 结尾，如 `INativeFileSystem` 或 `LlmInferenceService`。
*   **方法签名**：
    *   所有跨端调用必须是 **异步** 的。
    *   **Command (指令)**：返回 `Future<void>` 或 `Future<Result>`。
    *   **Query (查询)**：返回 `Future<T>`。
    *   **Event (事件流)**：返回 `Stream<T>`（用于下载进度、LLM Token 流式输出）。

### 2.2 数据传输对象 (DTO) 模型
严禁直接在层间传递 `Map<String, dynamic>`。必须定义强类型的 DTO。

*   **Request DTO**：用于向原生层发送参数（例如 `GenerationConfigDto`）。
*   **Response DTO**：用于接收原生层返回的数据。
*   **序列化**：建议使用 `json_serializable` 或 `freezed`，确保在 Dart 端和 Native 端（Kotlin/C++）有一一对应的序列化结构。

**示例代码结构 (Dart):**
```dart
abstract class ILlmService {
  // 启动推理引擎
  Future<void> initialize(InitConfigDto config);
  
  // 流式生成回复
  Stream<GenerationChunkDto> generateStream(String prompt);
}
```

---

## 3. 跨端通信与实现策略 (Cross-Platform Communication)

针对 Android 和 Windows 的特性，采用差异化的通信策略以平衡开发效率与运行性能。

### 3.1 Android 端通信方案
*   **技术选型**：**MethodChannel** (Standard)。
*   **适用场景**：文件选择、权限请求、简单的系统信息获取。
*   **实现细节**：
    *   使用 Kotlin 编写 `MainActivity` 或独立的 `FlutterPlugin`。
    *   利用 Kotlin Coroutines 处理原生端的异步任务，避免阻塞 UI 线程。

### 3.2 Windows 端通信方案
由于 Windows 端可能涉及高性能计算（如本地 LLM 推理），采用混合策略：

*   **策略 A：MethodChannel (C++)**
    *   **适用场景**：窗口管理、系统托盘、注册表读取等低频 OS 交互。
    *   **实现**：使用 Flutter 官方 C++ 封装，处理 `flutter::MethodCall`。
*   **策略 B：Dart FFI (Foreign Function Interface)**
    *   **适用场景**：**高频调用、大数据传输**（如 AI 模型推理、图像处理）。
    *   **优势**：无序列化开销，直接内存访问，性能接近原生。
    *   **实现**：将核心逻辑封装为 `.dll`，Dart 端通过 `ffi` 包直接绑定 C 接口。

### 3.3 大数据与高频调用优化
*   **二进制传输**：对于图片或大文本，避免使用 String/JSON，改用 `Uint8List` (Binary Messenger)。
*   **共享内存 (Shared Memory)**：在 Windows FFI 场景下，对于超大模型权重加载，使用内存映射文件，避免数据拷贝。

---

## 4. 差异化适配与生命周期管理 (Differentiation & Lifecycle)

抽象层需屏蔽平台差异，对外暴露统一的行为。

### 4.1 生命周期差异屏蔽
*   **Android**：关注 `onPause` (后台挂起) 和 `onResume`。需处理进程被杀后的状态恢复。
*   **Windows**：关注窗口关闭事件 (`CloseRequest`)、最小化到托盘。
*   **统一方案**：定义 `AppLifecycleObserver` 接口，在 Data 层分别监听 Android 的 `ActivityLifecycleCallbacks` 和 Windows 的 `WindowProc` 消息，统一转换为 Dart 端的 `AppLifecycleState` 流。

### 4.2 权限管理抽象
*   **设计**：定义统一的 `PermissionService`。
*   **Android**：调用 `Activity.requestPermissions`。
*   **Windows**：通常无需运行时权限，直接返回 `Granted`，或检查管理员权限。
*   **策略**：UI 层只调用 `requestPermission(PermissionType.storage)`，无需关心底层是弹窗还是直接通过。

---

## 5. 容错与稳定性设计 (Fault Tolerance & Stability)

跨端调用是崩溃的高发区，必须建立严密的防御机制。

### 5.1 异常转化机制
原生层的错误（Exception/Error）绝不能直接抛给 UI 层。

1.  **Native 层捕获**：
    *   **Kotlin**: 使用 `runCatching {}` 块包裹所有 Channel 处理逻辑。
    *   **C++**: 使用 `try-catch` 块，防止异常逃逸导致 Crash。
2.  **错误码映射**：
    *   定义统一的错误码枚举（如 `NATIVE_IO_ERROR`, `MODEL_LOAD_FAILED`）。
    *   Native 层返回 `PlatformException(code, message, details)`。
3.  **Dart 层转化**：
    *   Repository 实现层捕获 `PlatformException`。
    *   **转化为 Domain Failure**：将底层异常转化为业务可理解的 `Failure` 对象（如 `ServerFailure`, `CacheFailure`），利用 `Either<Failure, Success>` 类型返回。

### 5.2 崩溃防护
*   **类型安全检查**：在 Native 接收参数时，严格检查参数类型（如 `call.argument<String>("id")`），若类型不匹配直接返回错误，而非空指针崩溃。
*   **主线程保护**：耗时操作（IO、推理）强制在后台线程（Kotlin Dispatchers.IO / C++ std::thread）执行，防止阻塞 UI 导致 ANR (Application Not Responding)。

---

## 6. 可测试性方案 (Testability)

为了保证业务逻辑的正确性，必须在不依赖真实设备的情况下进行测试。

### 6.1 Mock 策略
由于 UI 层只依赖 Domain 接口，我们可以轻松 Mock 掉底层实现。

*   **工具**：使用 `mockito` 或 `mocktail`。
*   **方法**：
    1.  为 `INativeService` 创建 `MockNativeService`。
    2.  在 `test` 目录下编写单元测试。
    3.  **Stubbing**：`when(mockService.getData()).thenAnswer(...)` 模拟原生层返回数据。
    4.  **Verification**：`verify(mockService.saveData(...)).called(1)` 验证 UI 是否正确调用了底层接口。

### 6.2 契约测试 (Contract Testing)
*   确保 Dart 端定义的 DTO 结构与 Native 端解析逻辑一致。
*   编写集成测试（Integration Test），在真实设备/模拟器上运行，验证 Channel 通道的连通性。

---