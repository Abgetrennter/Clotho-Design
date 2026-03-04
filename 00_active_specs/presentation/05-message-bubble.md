# 消息气泡组件 (Message Bubble Component)

**版本**: 1.0.0
**日期**: 2026-02-11
**状态**: Draft
**参考**: `99_archive/legacy_ui/12-聊天界面.md`

---

## 1. 概述 (Overview)

消息气泡是 Clotho Stage 的核心组件，负责渲染用户和 AI 的对话内容。本规范定义消息气泡的结构、样式、状态和交互行为。

### 1.1 设计原则

| 原则 | 说明 |
| :--- | :--- |
| **清晰区分** | 用户消息和 AI 消息通过颜色、对齐方式区分 |
| **状态明确** | 发送中、错误、编辑等状态有清晰的视觉反馈 |
| **响应式适配** | 消息宽度根据屏幕尺寸自适应 |
| **可访问性** | 支持屏幕阅读器和键盘导航 |

---

## 2. 组件结构 (Component Structure)

### 2.1 数据模型

```dart
enum MessageStatus {
  default,   // 默认状态
  sending,   // 发送中
  error,     // 发送失败
  editing,   // 编辑模式
  highlighted, // 高亮（搜索结果/引用）
  deleted,   // 已删除
}

class Message {
  final String id;
  final String content;
  final bool isUser;
  final String? patternName;
  final String? patternAvatar;
  final DateTime timestamp;
  final MessageStatus status;
  final List<MessageAction>? actions;
}
```

### 2.2 Widget 结构

```dart
class MessageBubble extends StatelessWidget {
  final Message message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像
          if (!isUser) Avatar(message.patternAvatar, message.patternName),
          SizedBox(width: 12),
          // 消息内容
          Expanded(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // 名称和时间戳
                if (!isUser) MessageHeader(message),
                // 消息文本
                MessageContent(message),
                // 操作按钮
                MessageActions(message),
              ],
            ),
          ),
          SizedBox(width: 12),
          // 用户头像（可选）
          if (isUser) Avatar(message.patternAvatar, 'User'),
        ],
      ),
    );
  }
}
```

---

## 3. 消息样式 (Message Styles)

### 3.1 用户消息样式

```dart
class UserMessageBubble extends StatelessWidget {
  final Message message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Text(
          message.content,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
```

### 3.2 AI 消息样式

```dart
class AIMessageBubble extends StatelessWidget {
  final Message message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 头像
        CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage(message.patternAvatar ?? ''),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        ),
        SizedBox(width: 12),
        // 消息内容
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI 名称
                Text(
                  message.patternName ?? 'AI',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 4),
                // 消息内容
                Text(
                  message.content,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

---

## 4. 消息状态 (Message Status)

### 4.1 状态定义

| 状态 | 视觉特征 | 应用场景 |
| :--- | :--- | :--- |
| `default` | 正常显示 | 已发送的消息 |
| `sending` | 半透明 + 加载动画 | 正在发送中 |
| `error` | 红色边框 + 错误图标 | 发送失败 |
| `editing` | 黄色边框 + 编辑图标 | 编辑模式 |
| `highlighted` | 高亮背景 | 搜索结果/引用 |
| `deleted` | 删除线 + 低透明度 | 已删除消息 |

### 4.2 状态实现

```dart
class MessageStatusIndicator extends StatelessWidget {
  final MessageStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return Padding(
          padding: EdgeInsets.only(right: 8),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );

      case MessageStatus.error:
        return Padding(
          padding: EdgeInsets.only(right: 8),
          child: Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 16,
          ),
        );

      case MessageStatus.editing:
        return Padding(
          padding: EdgeInsets.only(right: 8),
          child: Icon(
            Icons.edit,
            color: Theme.of(context).colorScheme.warning,
            size: 16,
          ),
        );

      default:
        return SizedBox.shrink();
    }
  }
}
```

### 4.3 状态样式

```dart
class MessageContent extends StatelessWidget {
  final Message message;

  @override
  Widget build(BuildContext context) {
    BoxDecoration decoration;

    switch (message.status) {
      case MessageStatus.error:
        decoration = BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.error,
            width: 1,
          ),
        );
        break;

      case MessageStatus.editing:
        decoration = BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.warning,
            width: 2,
          ),
        );
        break;

      case MessageStatus.highlighted:
        decoration = BoxDecoration(
          color: Theme.of(context).colorScheme.warning.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        );
        break;

      case MessageStatus.deleted:
        decoration = BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        );
        break;

      default:
        decoration = BoxDecoration(
          color: message.isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        );
    }

    return Container(
      decoration: decoration,
      child: Text(
        message.content,
        style: message.status == MessageStatus.deleted
            ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                decoration: TextDecoration.lineThrough,
              )
            : Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
```

---

## 5. 头像系统 (Avatar System)

### 5.1 头像组件

```dart
class MessageAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool showStatus;
  final AvatarStatus? status;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // 头像图片
          CircleAvatar(
            radius: size / 2,
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: imageUrl == null
                ? Text(
                    name?.substring(0, 1).toUpperCase() ?? '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: size * 0.4,
                    ),
                  )
                : null,
          ),
          // 在线状态指示器
          if (showStatus && status != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: AvatarStatusIndicator(status: status!),
            ),
        ],
      ),
    );
  }
}
```

### 5.2 状态指示器

```dart
enum AvatarStatus {
  online,
  offline,
  busy,
}

class AvatarStatusIndicator extends StatelessWidget {
  final AvatarStatus status;

  @override
  Widget build(BuildContext context) {
    Color statusColor;

    switch (status) {
      case AvatarStatus.online:
        statusColor = Theme.of(context).colorScheme.success;
        break;
      case AvatarStatus.busy:
        statusColor = Theme.of(context).colorScheme.warning;
        break;
      case AvatarStatus.offline:
      default:
        statusColor = Theme.of(context).colorScheme.onSurfaceVariant;
    }

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: statusColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          width: 2,
        ),
      ),
    );
  }
}
```

---

## 6. 消息操作 (Message Actions)

### 6.1 操作按钮

```dart
class MessageActions extends StatelessWidget {
  final Message message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (message.status == MessageStatus.error)
            TextButton.icon(
              icon: Icon(Icons.refresh, size: 16),
              label: Text('重试'),
              onPressed: () {},
            ),
          if (message.status == MessageStatus.default)
            TextButton.icon(
              icon: Icon(Icons.edit, size: 16),
              label: Text('编辑'),
              onPressed: () {},
            ),
          IconButton(
            icon: Icon(Icons.copy, size: 16),
            onPressed: () {},
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 16),
            onPressed: () {},
            color: Theme.of(context).colorScheme.error,
          ),
        ],
      ),
    );
  }
}
```

---

## 7. 响应式适配 (Responsive Adaptation)

### 7.1 移动端适配

```dart
class ResponsiveMessageBubble extends StatelessWidget {
  final Message message;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final maxWidth = isMobile
        ? MediaQuery.of(context).size.width * 0.8
        : MediaQuery.of(context).size.width * 0.75;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: isMobile
          ? MobileMessageLayout(message)
          : DesktopMessageLayout(message),
    );
  }
}
```

---

## 8. 迁移对照表 (Migration Reference)

| 旧 UI 元素 | 新 UI 组件 | 变化 |
| :--- | :--- | :--- |
| `.mes` | `MessageBubble` | HTML → Flutter Widget |
| `.mes_text` | `MessageContent` | CSS → BoxDecoration |
| `.avatar` | `MessageAvatar` | img → CircleAvatar |
| `.swipe_control` | `MessageActions` | 滑动手势 → 按钮组 |
| 状态类 | `MessageStatus` 枚举 | CSS 类 → Dart 枚举 |

---

**关联文档**:
- [`01-design-tokens.md`](./01-design-tokens.md) - 设计令牌系统
- [`02-color-theme.md`](./02-color-theme.md) - 颜色与主题系统
- [`03-typography.md`](./03-typography.md) - 排版系统
- [`04-responsive-layout.md`](./04-responsive-layout.md) - 响应式布局
- [`06-input-area.md`](./06-input-area.md) - 输入区域组件
- [`07-message-status-slot.md`](./07-message-status-slot.md) - 消息状态槽
