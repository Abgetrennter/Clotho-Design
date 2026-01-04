# 运行时环境导读 (Runtime Environment Guide)

**版本**: 1.0.0
**日期**: 2025-12-30

本目录包含 Clotho 系统的动态运行时架构文档。不同于 `core/` 目录下的静态组件设计，本目录关注系统在运行过程中的状态变化、数据流转和生命周期管理。

## 文档索引

### 1. [分层运行时环境架构 (Layered Runtime Architecture)](layered-runtime-architecture.md)
**核心文档 (SSOT)**。详细定义了系统的四层叠加模型（L0-L3），解释了角色卡蓝图与会话实例如何分离。
* **关键词**: Layered Sandwich, Blueprint vs Instance, Copy-on-Write
* **包含内容**:
    * 四层模型定义 (Infrastructure, Global, Character, Session)
    * **Patching 机制与 Deep Merge 算法** (原 Mnemosyne 文档内容)
    * 运行时数据流 (Freeze, Unload, Hydrate, Resume)

## 核心概念

*   **L3 Session State**: 用户当前的对话状态，包括历史记录、变量变更和对世界设定的动态修改。
*   **Patching**: 一种非破坏性的修改机制，允许在不修改原始角色卡 (L2) 的前提下，记录角色的成长和变化。

## 关联阅读

*   **数据引擎**: [Mnemosyne Data Engine](../core/mnemosyne-data-engine.md) - 负责执行 Patching 和快照生成的组件。
*   **编排层**: [Jacquard Orchestration](../core/jacquard-orchestration.md) - 负责驱动运行时状态流转的调度器。
