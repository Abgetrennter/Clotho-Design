# UI 布局架构设计方案 (UI Layout Architecture Design)

**版本**: 1.0
**状态**: Draft
**参考标杆**: SillyTavern, TavernAI
**关联文档**: `doc/architecture/system_architecture.md`, `doc/architecture/ui_subsystem_design.md`

---

## 1. 宏观布局策略 (Macro Layout Strategy)

本设计采用 **"Stage & Control (舞台与控制台)"** 的布局哲学。核心对话区域（舞台）应尽可能沉浸，而参数配置与辅助信息（控制台）应在需要时触手可及，或在宽屏设备上常驻。

### 1.1 响应式三栏架构 (Responsive 3-Pane Architecture)

系统根据屏幕宽度（`width`）自动在三种模式间切换：

#### A. 桌面/宽屏模式 (Desktop/Wide) - `width > 1200dp`
*   **左栏 (Navigation/Session)**: 280dp，常驻。显示角色列表、会话历史。
*   **中栏 (Stage)**: 自适应 (Flex)，核心对话区。
*   **右栏 (Inspector)**: 320dp~400dp，常驻/可折叠。显示世界书 (Lore)、当前状态 (Status)、高级参数。

```text
+------------------+------------------------------------------+----------------------+
|  [Left Panel]    |              [Center Stage]              |    [Right Panel]     |
|                  |                                          |                      |
|  - Character     |  +------------------------------------+  |  - World Info        |
|    List          |  |           Chat Stream              |  |  - Status Bar        |
|  - Session       |  |                                    |  |    (Live Preview)    |
|    History       |  |  [Avatar] "Hello User..."          |  |  - Generation        |
|                  |  |                                    |  |    Params            |
|                  |  |           [Status Slot]            |  |                      |
|                  |  +------------------------------------+  |                      |
|                  |                                          |                      |
|  [Settings Btn]  |  [Input Deck (Draft Controller)]         |  [Token Counter]     |
+------------------+------------------------------------------+----------------------+
```

#### B. 平板/窄屏模式 (Tablet/Narrow) - `600dp < width <= 1200dp`
*   **左栏**: 收起为 Rail (侧边导航条) 或 Drawer (抽屉)。
*   **中栏**: 占据主体。
*   **右栏**: 默认隐藏，通过按钮从右侧滑出 (End Drawer) 或覆盖。

#### C. 移动端模式 (Mobile) - `width <= 600dp`
*   **单列布局**。
*   **导航**: 顶部 AppBar 或 底部 BottomNavigationBar。
*   **辅助信息**: 通过 BottomSheet (底部弹窗) 或二级页面展示。

### 1.2 区域划分定义

| 区域 ID | 名称 | 职责 | 渲染策略 |
| :--- | :--- | :--- | :--- |
| **Region_Nav** | 导航区 | 切换会话、管理角色 | Native Flutter |
| **Region_Stage** | 舞台区 | 显示对话流、背景图、立绘 | Native Flutter (List) |
| **Region_Input** | 输入甲板 | 用户输入、快捷指令、草稿编辑 | Native Flutter |
| **Region_Inspector** | 监视区 | 显示 Lorebook、参数、**状态栏详情** | Native / Hybrid SDUI |
| **Region_Overlay** | 覆盖层 | 全局 Toast、模态对话框、图片预览 | Native Flutter |

---

## 2. 组件架构视图 (Component Architecture)

基于 Flutter 的 Widget 树与 Riverpod 状态管理，构建高内聚、低耦合的组件体系。

### 2.1 核心组件层级 (Mermaid)

```mermaid
graph TD
    %% 顶层容器
    AppScaffold[AdaptiveScaffold] --> NavLayer[Navigation Layer]
    AppScaffold --> BodyLayer[Body Layer]
    
    %% 导航层
    NavLayer --> |Desktop| SideBar[SessionSidebar]
    NavLayer --> |Mobile| Drawer[AppDrawer]
    
    %% 主体层
    BodyLayer --> ChatArea[ChatStage]
    BodyLayer --> Inspector[InspectorPanel]
    
    %% 聊天区域分解
    ChatArea --> Background[DynamicBackground]
    ChatArea --> MessageList[MessageStreamListView]
    ChatArea --> InputDeck[InputControlDeck]
    
    %% 消息组件分解 (关键)
    MessageList --> MessageItem[ChatMessageItem]
    MessageItem --> Avatar[User/Char Avatar]
    MessageItem --> Bubble[ContentBubble]
    MessageItem --> StatusSlot[MessageStatusSlot (Container)]
    
    %% 状态槽的多态实现
    StatusSlot --> |Native| RFWWidget[RFW Renderer]
    StatusSlot --> |Web| WebViewWidget[WebView Renderer]
    StatusSlot --> |Fallback| Placeholder[Error/Loading View]
    
    %% 输入区域分解
    InputDeck --> Toolbar[QuickActionToolbar]
    InputDeck --> TextField[DraftTextField]
    InputDeck --> SendBtn[SendButton]
```

### 2.2 关键组件详解

#### 1. `AdaptiveScaffold` (响应式骨架)
*   **职责**: 监听 `LayoutBuilder` 或 `MediaQuery`，决定显示 3-Pane 还是单列。管理左右侧边栏的显隐状态。
*   **状态**: `layoutProvider` (mobile, tablet, desktop)。

#### 2. `ChatMessageItem` (消息原子)
*   **职责**: 渲染单条消息。
*   **布局**:
    *   Header: 角色名、时间戳、Token 数。
    *   Body: Markdown 文本渲染。
    *   **Footer (Slot)**: `MessageStatusSlot`。这是 Hybrid SDUI 的注入点。
*   **解耦**: 消息体不关心 StatusSlot 内部是 RFW 还是 WebView，只提供约束 (Constraints)。

#### 3. `MessageStatusSlot` (状态槽)
*   **职责**: 根据 `doc/architecture/ui_subsystem_design.md`，加载动态 UI。
*   **逻辑**:
    *   获取 `message.metadata['status_ui_id']`。
    *   查询 `ExtensionRegistry`。
    *   决定渲染 `RFW` 还是 `WebView`。

#### 4. `InputControlDeck` (输入甲板)
*   **职责**: 实现 `InputDraftController` 逻辑。
*   **特性**:
    *   支持多行输入。
    *   支持 "Slash Commands" (/) 补全。
    *   **拦截**: 接收来自 `StatusSlot` 的交互事件（如点击了状态栏里的“攻击”按钮），将其转化为文本填入输入框，而不是直接发送。

---

## 3. 迁移与重构路线 (Migration & Refactoring Route)

基于现有 `Material3ChatUIDemo.dart` 进行渐进式重构。

### 阶段一：原子化拆分 (Atomization)
**目标**: 将巨型 `build` 方法拆解为独立 Widget 文件。
1.  创建 `lib/features/chat/presentation/widgets/` 目录。
2.  提取 `_buildMessageBubble` -> `ChatMessageItem`。
3.  提取 `_buildInputArea` -> `InputControlDeck`。
4.  提取 `_showStatusPanel` -> `StatusInspectorPanel` (为右侧栏做准备)。

### 阶段二：引入响应式骨架 (Responsive Layout)
**目标**: 支持桌面端布局。
1.  创建 `lib/core/presentation/widgets/adaptive_scaffold.dart`。
2.  实现 `AdaptiveScaffold`，接受 `navigation`, `body`, `secondaryBody` (右栏) 参数。
3.  修改 `ChatPage` 使用 `AdaptiveScaffold`。

### 阶段三：状态管理升级 (State Management)
**目标**: 移除 `setState`，完全接入 Riverpod。
1.  定义 `ChatSessionNotifier` 管理消息列表。
2.  定义 `InputDraftNotifier` 管理输入框内容。
3.  让 `InputControlDeck` 监听 `InputDraftNotifier`。

### 阶段四：Hybrid SDUI 预留 (Slot Integration)
**目标**: 为未来接入 RFW/WebView 做好布局准备。
1.  在 `ChatMessageItem` 底部添加 `MessageStatusSlot` 占位符 Widget。
2.  实现基础的 `ExtensionRegistry` (Mock)。
3.  当消息包含特定 Metadata 时，在 Slot 中显示简单的调试信息。

---

## 4. 视觉风格指导 (Visual Style Guide)

*   **主题**: Material 3 (You) + 自定义扩展。
*   **沉浸感**:
    *   对话气泡支持半透明/毛玻璃 (Blur) 效果，以便透出背景图。
    *   字体大小、行高应可配置 (Accessibility)。
*   **动效**:
    *   消息上屏使用 `SizeTransition` + `FadeTransition`。
    *   侧边栏展开/收起使用标准缓动曲线。
