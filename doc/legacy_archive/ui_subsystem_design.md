# UI 子系统架构设计说明书 (UI Subsystem Architecture Design Document)

**版本**: 1.0
**状态**: Draft
**最后更新**: 2025-12-21
**参考文档**: `doc/architecture/system_architecture.md`

---

## 1. 概览 (Overview)

本系统采用 **Hybrid SDUI Engine (混合式服务端驱动 UI 引擎)** 架构，旨在解决高性能原生体验与海量第三方内容兼容性之间的矛盾。作为 Clotho 系统架构中 **表现层 (Presentation Layer)** 的核心实现，UI 子系统严格遵循“逻辑与表现分离”原则，通过单向数据流接收编排层 (Jacquard Layer) 的指令，并负责最终的界面渲染与用户交互。

### 1.1 核心设计理念

1.  **原生优先 (Native First)**: 对于官方维护或社区热门的内容，通过下发结构化布局数据（RFW），使用 Flutter 原生渲染，确保高性能与一致性。
2.  **Web 兜底 (Web Fallback)**: 对于长尾、复杂或未知来源的内容，降级使用 WebView 渲染 HTML/JS，确保 100% 的兼容性。
3.  **单向受控 (Unidirectional Control)**: UI 层不直接修改业务状态（World State），所有交互意图必须转化为标准指令或输入草稿，经由编排层处理。

---

## 2. 架构设计 (Architecture Design)

UI 子系统由路由调度器、双轨渲染引擎及扩展包管理模块组成。

### 2.1 渲染路由机制

当系统需要渲染一个动态内容（如角色状态栏、自定义面板）时，**路由调度器 (Routing Dispatcher)** 将按以下优先级执行决策：

1.  **检查扩展 (Check Extension)**: 根据内容的唯一标识符（ID 或特征码），查询本地或云端的 **UI 扩展包 (UI Extension)** 注册表。
2.  **分支 A - 原生渲染 (Native Track)**: 若存在匹配的 `.rfw` (Remote Flutter Widgets) 布局包，则加载该包并注入数据，执行原生渲染。
3.  **分支 B - 降级渲染 (Web Track)**: 若无匹配扩展包或加载失败，则直接加载原始内容（HTML/CSS/JS），执行 WebView 渲染。

### 2.2 架构拓扑图

```mermaid
graph TD
    %% 样式定义
    classDef core fill:#e1f5fe,stroke:#01579b,stroke-width:2px;
    classDef native fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px;
    classDef web fill:#fff3e0,stroke:#e65100,stroke-width:2px;
    classDef ext fill:#f3e5f5,stroke:#4a148c,stroke-width:2px;

    subgraph Presentation_Layer [表现层]
        Dispatcher[路由调度器]:::core
        
        subgraph Native_Engine [原生渲染引擎]
            RFW_Loader[RFW 加载器]:::native
            Native_Widget[RemoteWidget]:::native
        end
        
        subgraph Web_Engine [Web 渲染引擎]
            WebView_Controller[WebView 控制器]:::web
            JS_Bridge[JS Bridge (受限)]:::web
        end
        
        Input_Controller[InputDraftController]:::core
    end

    subgraph Resources [资源管理]
        Extension_Registry[UI 扩展包注册表]:::ext
        Local_Cache[本地缓存 (.rfw)]:::ext
    end

    %% 流程
    Content((动态内容)) --> Dispatcher
    Dispatcher -- "查询 ID" --> Extension_Registry
    
    Extension_Registry -- "命中 (Hit)" --> RFW_Loader
    Extension_Registry -- "未命中 (Miss)" --> WebView_Controller
    
    RFW_Loader -- "加载布局" --> Local_Cache
    RFW_Loader --> Native_Widget
    
    Native_Widget -- "交互事件" --> Input_Controller
    JS_Bridge -- "交互事件" --> Input_Controller
    
    Input_Controller -- "生成草稿" --> User_Input_Area[用户输入框]
```

---

## 3. 关键组件详解 (Key Components)

### 3.1 UI 扩展包 (UI Extensions)
*注：为避免与 Jacquard 层的逻辑插件混淆，UI 侧的动态布局文件统称为“UI 扩展包”。*

*   **定义**: 包含界面布局描述（`.rfw` 或二进制格式）的静态资源包。
*   **职责**: 定义界面的结构、样式及基础交互逻辑（如展开/折叠），但不包含业务逻辑代码（Dart）。
*   **分发**: 通过“扩展包注册表”进行索引，支持云端下发与本地缓存。

### 3.2 MessageStatusSlot (消息状态槽)
*   **定位**: 嵌入在 `ChatMessageItem` 中的动态容器，是 Hybrid SDUI 架构的典型应用场景。
*   **生命周期**: 随消息创建而初始化，随消息销毁而释放。
*   **职责**:
    *   作为“防火墙”隔离外部内容与核心 App。
    *   管理渲染器的尺寸约束（最大高度、裁剪）。
    *   处理渲染失败时的优雅降级（显示占位符或折叠）。

### 3.3 InputDraftController (输入草稿控制器)
*   **定位**: UI 子系统与用户输入之间的**唯一写通道**。
*   **安全约束**: 状态栏（无论是原生还是 Web）**严禁**直接发送消息、修改历史记录或触发 LLM 生成。
*   **功能**:
    *   接收来自渲染器的“文本意图”（如点击“攻击”按钮）。
    *   将意图转换为文本草稿（Draft）填入输入框。
    *   允许用户在发送前进行二次编辑。

---

## 4. 状态栏设计详解 (Status Bar Design)

状态栏是第三方角色卡（Character Card）中常见的 UI 元素，用于显示角色的 HP、MP、好感度等状态。

### 4.1 设计原则
1.  **消息级附属**: 状态栏属于特定历史时刻的快照，不应随当前最新状态实时浮动，而是锚定在生成该状态的那条消息下方。
2.  **允许失败**: 状态栏是辅助信息。若渲染崩溃或资源加载失败，绝不能阻断核心对话文本的显示。
3.  **数据隔离**: HTML/JS 环境必须沙箱化，禁止访问 Cookie、本地存储或非授权的 URL。

### 4.2 数据流向
1.  **输入**: `ChatMessage` 对象携带的 `World State` 快照。
2.  **处理**:
    *   **Native**: 将 State 映射为 RFW 数据模型，驱动原生组件更新。
    *   **Web**: 将 State 注入到 HTML 模板中，或通过 JS Bridge 传递。
3.  **输出**: 仅产生 `Input Draft` 事件。

---

## 5. 与编排层交互 (Interaction with Jacquard)

UI 子系统是被动的消费者，通过 **Filament 协议** 与编排层通信。

### 5.1 接收指令
UI 层监听 Jacquard 流水线的输出流，解析 Filament 标签并执行相应动作：

*   `<thought>...</thought>`: 渲染为折叠的思维链区域。
*   `<reply>...</reply>`: 实时流式渲染对话文本。
*   `<state_update>...</state_update>`: 
    *   UI 层**不处理**状态的具体数值计算。
    *   UI 层仅根据此标签触发视觉反馈（如飘字效果），实际数值更新由 Jacquard 层的 `State Updater Plugin` 处理后，通过 `Mnemosyne` 广播回 UI。

### 5.2 状态同步
UI 不维护权威状态。当 `Mnemosyne` 中的状态发生变更时，会通过 Stream 通知 UI 层。UI 层接收到新快照后，触发 `build` 重绘。

---

## 6. 术语表 (Glossary)

| 术语 | 说明 | 备注 |
| :--- | :--- | :--- |
| **UI Extension (UI 扩展包)** | 用于 UI 渲染的动态布局文件（如 .rfw）。 | 区别于 Jacquard Plugin。 |
| **Jacquard Plugin (逻辑插件)** | 用于处理业务逻辑的 Dart 代码模块。 | 运行在编排层。 |
| **RFW (Remote Flutter Widgets)** | Google 提供的动态组件渲染库。 | 原生渲染核心技术。 |
| **Slot (插槽)** | 预留的 UI 容器区域，用于动态加载内容。 | 如 MessageStatusSlot。 |