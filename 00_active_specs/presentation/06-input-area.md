# 输入区域组件 (Input Area Component)

**版本**: 1.0.0
**日期**: 2026-02-11
**状态**: Draft
**参考**: `99_archive/legacy_ui/12-聊天界面.md`, `99_archive/legacy_ui/UI`

---

## 1. 概述 (Overview)

输入区域是 Clotho Stage 的核心交互组件，负责接收用户输入并提交到 Jacquard 编排层。本规范定义输入区域的结构、样式、状态和行为。

### 1.1 设计原则

| 原则 | 说明 |
| :--- | :--- |
| **固定位置** | 输入区域固定在底部，不随消息滚动 |
| **自适应高度** | 输入框高度根据内容自动调整 |
| **状态反馈** | 生成中、错误等状态有清晰反馈 |
| **键盘友好** | 支持快捷键操作 |

---

## 2. 组件结构 (Component Structure)

### 2.1 整体布局

```dart
class InputArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.divider,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 状态按钮行
          InputToolbar(),
          SizedBox(height: 8),
          // 输入行
          InputRow(),
        ],
      ),
    );
  }
}
```

### 2.2 输入行

```dart
class InputRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 附件按钮
        IconButton(
          icon: Icon(Icons.attach_file),
          onPressed: () {},
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: 8),
        // 输入框
        Expanded(
          child: InputTextField(),
        ),
        SizedBox(width: 8),
        // 发送按钮
        FloatingActionButton(
          mini: true,
          onPressed: () {},
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.send,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}
```

---

## 3. 输入框组件 (Input TextField)

### 3.1 基础实现

```dart
class InputTextField extends StatefulWidget {
  @override
  _InputTextFieldState createState() => _InputTextFieldState();
}

class _InputTextFieldState extends State<InputTextField> {
  final TextEditingController _controller = TextEditingController();
  int _tokenCount = 0;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLines: null,
      minLines: 1,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        hintText: '输入消息...',
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: (value) {
        setState(() {
          _tokenCount = _calculateTokens(value);
        });
      },
    );
  }

  int _calculateTokens(String text) {
    // 简单的 token 计算逻辑
    return text.length ~/ 4;
  }
}
```

### 3.2 自适应高度

```dart
class AdaptiveInputField extends StatefulWidget {
  @override
  _AdaptiveInputFieldState createState() => _AdaptiveInputFieldState();
}

class _AdaptiveInputFieldState extends State<AdaptiveInputField> {
  int _lineCount = 1;
  static const int _maxLines = 6;

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: _maxLines,
      minLines: _lineCount,
      onChanged: (value) {
        final newLineCount = value.split('\n').length;
        if (newLineCount != _lineCount) {
          setState(() {
            _lineCount = newLineCount.clamp(1, _maxLines);
          });
        }
      },
      // ... 其他配置
    );
  }
}
```

---

## 4. 状态工具栏 (Input Toolbar)

### 4.1 工具栏组件

```dart
class InputToolbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 生成状态指示器
        GenerationIndicator(),
        Spacer(),
        // 快捷操作按钮
        IconButton(
          icon: Icon(Icons.format_quote),
          onPressed: () {},
          tooltip: '引用',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        IconButton(
          icon: Icon(Icons.history),
          onPressed: () {},
          tooltip: '历史',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: () {},
          tooltip: '设置',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}
```

---

## 5. 生成状态指示器 (Generation Indicator)

### 5.1 生成中状态

```dart
class GenerationIndicator extends StatelessWidget {
  final bool isGenerating;

  @override
  Widget build(BuildContext context) {
    if (!isGenerating) {
      return SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 8),
        Text(
          'AI 正在生成...',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
```

### 5.2 生成进度条

```dart
class GenerationProgressIndicator extends StatelessWidget {
  final double progress; // 0.0 - 1.0

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh.withOpacity(0.9),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                ),
              ),
              SizedBox(width: 8),
              Text(
                '${(progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## 6. 快捷操作 (Quick Actions)

### 6.1 快捷按钮

```dart
class QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        ActionChip(
          avatar: Icon(Icons.edit, size: 16),
          label: Text('编辑'),
          onPressed: () {},
        ),
        ActionChip(
          avatar: Icon(Icons.undo, size: 16),
          label: Text('重试'),
          onPressed: () {},
        ),
        ActionChip(
          avatar: Icon(Icons.refresh, size: 16),
          label: Text('重新生成'),
          onPressed: () {},
        ),
      ],
    );
  }
}
```

---

## 7. 响应式适配 (Responsive Adaptation)

### 7.1 移动端适配

```dart
class ResponsiveInputArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 8 : 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMobile) ...[
            // 移动端：状态栏在输入框上方
            InputToolbar(),
            SizedBox(height: 8),
          ],
          InputRow(),
          if (!isMobile) ...[
            // 桌面端：状态栏在输入框下方
            SizedBox(height: 8),
            InputToolbar(),
          ],
        ],
      ),
    );
  }
}
```

---

## 8. 键盘快捷键 (Keyboard Shortcuts)

### 8.1 快捷键定义

```dart
class InputShortcuts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        // Enter 发送，Shift+Enter 换行
        const SingleActivator(LogicalKeyboardKey.enter): _sendMessage,
        const SingleActivator(
          LogicalKeyboardKey.enter,
          shift: true,
        ): _insertNewline,
        // Ctrl+K 清空输入
        const SingleActivator(
          LogicalKeyboardKey.keyK,
          control: true,
        ): _clearInput,
      },
      child: Focus(
        autofocus: true,
        child: InputTextField(),
      ),
    );
  }

  void _sendMessage() {
    // 发送逻辑
  }

  void _insertNewline() {
    // 插入换行
  }

  void _clearInput() {
    // 清空输入
  }
}
```

---

## 9. 迁移对照表 (Migration Reference)

| 旧 UI 元素 | 新 UI 组件 | 变化 |
| :--- | :--- | :--- |
| `#send_textarea` | `InputTextField` | textarea → TextField |
| `bottom_form` | `InputArea` | div → Container |
| `mes_buttons` | `InputToolbar` | div → Row |
| 生成状态 | `GenerationIndicator` | CSS → Widget |

---

**关联文档**:
- [`01-design-tokens.md`](./01-design-tokens.md) - 设计令牌系统
- [`02-color-theme.md`](./02-color-theme.md) - 颜色与主题系统
- [`03-typography.md`](./03-typography.md) - 排版系统
- [`04-responsive-layout.md`](./04-responsive-layout.md) - 响应式布局
- [`05-message-bubble.md`](./05-message-bubble.md) - 消息气泡组件
- [`15-input-draft-controller.md`](./15-input-draft-controller.md) - 输入草稿控制器
