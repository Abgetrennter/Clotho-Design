# Infrastructure Layer (基础设施层)

**版本**: 1.0.0  
**日期**: 2026-02-12  
**状态**: Active  

---

## 1. 概述 (Overview)
基础设施层（Infrastructure Layer，L0）是 Clotho 架构的最底层，负责提供与平台无关的基础服务、硬件抽象以及核心运行时支持。它为上层模块（Core, Jacquard, Mnemosyne, Presentation）提供稳定的地基。

## 2. 核心职责 (Core Responsibilities)
*   **依赖注入 (Dependency Injection)**: 管理服务生命周期与模块解耦。
*   **平台抽象 (Platform Abstraction)**: 屏蔽不同操作系统（Windows, Android, iOS）的文件系统、网络和硬件差异。
*   **日志与遥测 (Logging & Telemetry)**: 提供统一的日志记录和性能监控接口。
*   **事件总线 (Event Bus)**: (ClothoNexus) 提供跨模块的异步通信机制。

## 3. 设计规范 (Design Specifications)

### 3.1 核心规范
*   [依赖注入与状态管理规范 (Dependency Injection & State Management)](./dependency-injection.md)
    *   定义了 GetIt + Riverpod 的混合架构方案。
    *   规定了 UI 层与核心层的交互边界。
*   [文件系统抽象规范 (File System Abstraction)](./file-system-abstraction.md)
    *   定义了跨平台路径映射（AppDate, Cache, Temp）。
    *   提供了 `app_data://` 等语义化路径别名。
*   [日志分级与输出规范 (Logging Standards)](./logging-standards.md)
    *   定义了 CoreLogger 服务与 Sink 架构。
    *   规范了日志等级、隐私脱敏规则以及与 Nexus 的混合集成模式。

### 3.2 待定规范 (Planned Specs)
*   (暂无)

### 3.3 核心事件总线
*   [ClothoNexus: 核心事件总线](./clotho-nexus-events.md)
    *   定义了 Core/Infrastructure 层的异步事件总线。
    *   规范了 System, Session, Message, Data 等标准事件类型。
    *   展示了 Core (发布) -> Nexus -> UI (订阅) 的数据流。