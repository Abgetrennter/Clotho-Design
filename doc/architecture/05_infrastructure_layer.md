# 第五章：跨平台基础设施 (Infrastructure Layer)

**版本**: 1.0.0
**日期**: 2025-12-23
**状态**: Draft
**作者**: 资深系统架构师 (Architect Mode)
**源文档**: `cross_platform_abstraction_layer.md`

---

## 1. 架构综述 (Infrastructure Overview)

为了实现 `Neuropean` 项目在 Android 和 Windows 端的长期稳定性与可维护性，基础设施层设计严格遵循 **依赖倒置原则 (Dependency Inversion Principle, DIP)**。

### 1.1 核心设计理念
传统的架构往往是上层 UI 直接调用底层原生 API，导致强耦合。我们采用 **Clean Architecture** 结合 **Repository Pattern**，将依赖关系反转：
*   **UI 层 (Presentation Layer)**：只依赖于纯 Dart 编写的抽象接口 (Domain)。
*   **原生实现层 (Data Layer)**：负责具体的平台调用，实现上述接口。

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
*   **技术**: **MethodChannel** (Standard)。
*   **场景**: 文件选择、权限请求、系统信息。
*   **实现**: 使用 Kotlin Coroutines 处理异步任务，避免阻塞 UI 线程。

### 2.2 Windows 端通信方案
由于 Windows 端涉及高性能计算（如本地 LLM 推理），采用混合策略：

| 策略 | 技术 | 适用场景 | 优势 |
| :--- | :--- | :--- | :--- |
| **策略 A** | **MethodChannel (C++)** | 窗口管理、注册表、托盘 | 官方支持，开发简便 |
| **策略 B** | **Dart FFI (C++ DLL)** | **LLM 推理、图像处理** | 无序列化开销，直接内存访问 |

### 2.3 大数据传输优化
*   **二进制传输**: 图片/大文本使用 `Uint8List` (Binary Messenger)，避免 String/JSON 转换开销。
*   **共享内存**: Windows FFI 场景下，使用内存映射文件加载大模型权重。

---

## 3. 差异化适配与生命周期

抽象层需屏蔽平台差异，对外暴露统一的行为。

### 3.1 生命周期统一
*   **Android**: 关注 `onPause`/`onResume`。
*   **Windows**: 关注 `CloseRequest`。
*   **抽象**: 定义 `AppLifecycleObserver` 接口，将底层回调统一转换为 Dart 端的 `AppLifecycleState` 流。

### 3.2 权限管理抽象
*   **设计**: 定义统一的 `PermissionService`。
*   **策略**: UI 层只调用 `requestPermission(PermissionType.storage)`，无需关心底层是弹窗 (Android) 还是直接通过 (Windows)。

---

## 4. 容错与稳定性 (Stability)

跨端调用是崩溃的高发区，必须建立严密的防御机制。

### 4.1 异常转化机制
原生层的错误绝不能直接抛给 UI 层。
1.  **Native 捕获**: Kotlin `runCatching`, C++ `try-catch`。
2.  **错误码映射**: 返回 `PlatformException(code, msg)`。
3.  **Dart 转化**: Data 层捕获异常，转化为业务可理解的 `Failure` 对象 (Domain Failure)。

### 4.2 崩溃防护
*   **类型安全**: Native 端严格检查参数类型。
*   **主线程保护**: 耗时操作强制在后台线程执行，防止 ANR。
