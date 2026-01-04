# 第五章：跨平台基础设施 (Infrastructure Layer)

**版本**: 1.0.0
**日期**: 2025-12-23
**状态**: Draft
**作者**: 资深系统架构师 (Architect Mode)
**源文档**: `cross_platform_abstraction_layer.md`

---

## 1. 架构综述 (Infrastructure Overview)

为了实现 Clotho 项目在 **Android** 和 **Windows** 等多平台上的**长期稳定性、高性能与代码复用**，基础设施层以 **Flutter** 为统一底座，设计严格遵循 **依赖倒置原则 (Dependency Inversion Principle, DIP)**。

### 1.1 核心设计理念

传统的架构往往是上层 UI 直接调用底层原生 API，导致强耦合且难以跨平台。我们采用 **Clean Architecture** 结合 **Repository Pattern**，利用 Flutter 的跨平台能力将依赖关系反转：

* **UI 层 (Presentation Layer)**：基于 Flutter 构建，只依赖于纯 Dart 编写的抽象接口 (Domain)。
* **原生实现层 (Data Layer)**：负责具体的平台调用（如 Android 的 Intent 或 Windows 的 Win32 API），实现上述接口。

### 1.2 架构分层图解

```mermaid
graph TD
    UI[Flutter UI] -->|依赖| Domain[Domain Layer (纯Dart接口)]
    Data[Data Layer (Repository实现)] -->|实现| Domain
    Data -->|调用| Channel[MethodChannel / FFI]
    Channel -->|通信| Native[Android (Kotlin) / Windows (C++)]
```

---

## 2. 跨端通信策略 (Cross-Platform Communication)

针对 Android 和 Windows 的特性，采用差异化的通信策略以平衡开发效率与运行性能。

### 2.1 Android 端通信方案

* **技术**: **MethodChannel** (Standard)。
* **场景**: 文件选择、权限请求、系统信息。
* **实现**: 使用 Kotlin Coroutines 处理异步任务，避免阻塞 UI 线程。

### 2.2 Windows 端通信方案

由于 Windows 端涉及高性能计算（如本地 LLM 推理），采用混合策略：

| 策略 | 技术 | 适用场景 | 优势 |
| :--- | :--- | :--- | :--- |
| **策略 A** | **MethodChannel (C++)** | 窗口管理、注册表、托盘 | 官方支持，开发简便 |
| **策略 B** | **Dart FFI (C++ DLL)** | **LLM 推理、图像处理** | 无序列化开销，直接内存访问 |

### 2.3 大数据传输优化

* **二进制传输**: 图片/大文本使用 `Uint8List` (Binary Messenger)，避免 String/JSON 转换开销。
* **共享内存**: Windows FFI 场景下，使用内存映射文件加载大模型权重。

---

## 3. 差异化适配与生命周期

抽象层需屏蔽平台差异，对外暴露统一的行为。

### 3.1 生命周期统一

* **Android**: 关注 `onPause`/`onResume`。
* **Windows**: 关注 `CloseRequest`。
* **抽象**: 定义 `AppLifecycleObserver` 接口，将底层回调统一转换为 Dart 端的 `AppLifecycleState` 流。

### 3.2 权限管理抽象

* **设计**: 定义统一的 `PermissionService`。
* **策略**: UI 层只调用 `requestPermission(PermissionType.storage)`，无需关心底层是弹窗 (Android) 还是直接通过 (Windows)。

---

## 4. 容错与稳定性 (Stability)

跨端调用是崩溃的高发区，必须建立严密的防御机制。

### 4.1 异常转化机制

原生层的错误绝不能直接抛给 UI 层。

1. **Native 捕获**: Kotlin `runCatching`, C++ `try-catch`。
2. **错误码映射**: 返回 `PlatformException(code, msg)`。
3. **Dart 转化**: Data 层捕获异常，转化为业务可理解的 `Failure` 对象 (Domain Failure)。

### 4.2 崩溃防护

* **类型安全**: Native 端严格检查参数类型。
* **主线程保护**: 耗时操作强制在后台线程执行，防止 ANR。

---

## 5. 模块间通信总线 (ClothoNexus) - v1.1 新增

为了解耦 UI 层与逻辑层，并支持复杂的异步工作流（如流式生成、状态回溯），系统引入了名为 **ClothoNexus** 的强类型事件总线。

### 5.1 设计原则

* **强类型 (Type Safety)**: 摒弃字符串事件名，使用 Dart 类作为事件载体，确保 Payload 结构安全。
* **单向数据流 (Unidirectional Flow)**: 数据从 Mnemosyne 流向 UI，意图 (Intent) 从 UI 流向 Jacquard。
* **依赖注入 (Dependency Injection)**: 总线实例通过 DI 容器传递，而非全局单例。

### 5.2 架构拓扑

ClothoNexus 作为中央枢纽，管理着几条核心的 Stream 管道：

```mermaid
graph TD
    subgraph Nexus [ClothoNexus]
        StateStream[State Stream<br>(数据变更)]
        WorkflowStream[Workflow Stream<br>(工作流状态)]
        InteractionStream[Interaction Stream<br>(用户交互)]
    end

    subgraph Mnemosyne
        Store[状态存储]
    end

    subgraph Jacquard
        Pipeline[执行流水线]
    end

    subgraph Presentation
        ChatUI[聊天界面]
        StatusBar[状态栏]
    end

    Store -->|emit(StateUpdated)| StateStream
    Pipeline -->|emit(WorkflowStatus)| WorkflowStream
    
    StateStream -->|listen| StatusBar & ChatUI
    WorkflowStream -->|listen| ChatUI
    
    ChatUI -->|dispatch(UserIntent)| InteractionStream
    InteractionStream -->|listen| Pipeline
```

### 5.3 核心事件定义

* **StateUpdatedEvent**: 数据变更事件。包含 `delta` (变更字段) 和 `mk` (消息锚点)。
* **WorkflowStatusEvent**: 工作流状态事件。包含 `stage` (如 generating, parsing) 和 `progress`。
* **UserIntentEvent**: 用户交互意图。包含 `action` (如 send_message, click_option) 和 `payload`。

### 5.4 实现策略

基于 Dart 原生 `StreamController.broadcast()` 实现多播机制，支持背压处理 (Backpressure) 以防止 UI 卡顿。
